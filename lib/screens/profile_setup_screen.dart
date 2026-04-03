import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_lib/share_lib_auth.dart';
import 'package:share_lib/share_lib_image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_auth_provider.dart';
import '../models/user.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo_edit_view.dart';
import '../utils/photo_permission_helper.dart';
import '../widgets/profile_style_section.dart';
import '../widgets/user_profile_view.dart';
import 'community_guidelines_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Future<void> Function()? onComplete;

  /// 마이페이지 탭 안에서 보일 때 true. 앱바·뒤로가기 버튼 숨김 (뒤로가기 시 스택 꼬임 방지)
  final bool embeddedInProfile;

  const ProfileSetupScreen({
    super.key,
    this.onComplete,
    this.embeddedInProfile = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedGender; // 'male' or 'female'
  String? _profileImageUrl;
  String? _backgroundImageUrl;
  bool _isUploadingProfileImage = false;
  bool _isUploadingBackgroundImage = false;

  String? _selectedLifeSceneId;
  String? _selectedSelfStatementId;
  String? _selectedInteractionStyleId;

  @override
  void initState() {
    super.initState();
    _initProfileFieldsFromState();
    // 최초 프로필 없음: Sign in with Apple 가이드상 닉네임 입력을 강제할 수 없어,
    // 로그인에서 받은 표시 이름(Firebase / Apple 캐시)으로 닉네임 칸을 채웁니다.
    unawaited(_prefillNicknameFromLoginWhenNoProfile());
    // Apple 로그인 직후에는 Firebase displayName이 한 프레임 늦게 잡히는 경우가 있어
    // reload 후 닉네임·사진을 다시 반영합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDisplayNameAndPhotoFromFirebase();
    });
    // 프로필 설정 진입 시 약관 미동의면 약관 먼저 표시. 거절 시 로그아웃 + (push된 경우) pop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 푸시 직후 리빌드로 인한 중복 호출/즉시 pop 방지: 한 프레임 더 지연 후 푸시
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _ensureGuidelinesThenContinue();
      });
    });
  }

  void _initProfileFieldsFromState() {
    final userProfile = AppAuthProvider.shared.userProfile;
    if (userProfile != null) {
      _nicknameController.text =
          userProfile.fullName.isNotEmpty ? userProfile.fullName : '';
      _selectedLifeSceneId = userProfile.lifeSceneId;
      _selectedSelfStatementId = userProfile.selfStatementId;
      _selectedInteractionStyleId = userProfile.interactionStyleId;
      _bioController.text = userProfile.bio ?? '';
      _selectedGender = userProfile.gender;
      _profileImageUrl = userProfile.profileImageUrl;
      _backgroundImageUrl = userProfile.backgroundImageUrl;
    } else {
      // 서버 프로필 없음(최초 소셜 로그인): 동기적으로 캐시된 Firebase 표시 이름·사진 반영
      // (displayName이 아직 없으면 _prefillNicknameFromLoginWhenNoProfile / _sync에서 보강)
      final fb = FirebaseAuth.instance.currentUser;
      if (fb != null) {
        final name = fb.displayName?.trim();
        if (name != null && name.isNotEmpty) {
          _nicknameController.text = name;
        }
        final photo = fb.photoURL;
        if (photo != null && photo.isNotEmpty) {
          _profileImageUrl = photo;
        }
      }
    }
  }

  /// Firebase `displayName`(및 Apple 로컬 캐시)에서 로그인 시 받은 표시 이름을 가져옵니다.
  Future<String> _resolveLoginDisplayNameForNickname() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (_) {}
    final u = FirebaseAuth.instance.currentUser;
    final n = u?.displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = displayNameFromApplePrefs(prefs);
    if (fromPrefs.isNotEmpty) return fromPrefs;
    return '';
  }

  /// 서버 프로필이 없을 때(최초 설정) 닉네임 칸을 로그인 표시 이름으로 채웁니다.
  Future<void> _prefillNicknameFromLoginWhenNoProfile() async {
    if (!mounted) return;
    if (AppAuthProvider.shared.userProfile != null) return;
    if (_nicknameController.text.trim().isNotEmpty) return;

    final resolved = await _resolveLoginDisplayNameForNickname();
    if (!mounted || resolved.isEmpty) return;
    setState(() {
      _nicknameController.text = resolved;
    });
  }

  /// Apple이 최초에만 넘긴 표시 이름을 share_lib가 저장한 값 → Firebase가 아직 비어 있을 때 닉네임 필드에 반영
  Future<void> _applyCachedAppleDisplayNameIfNeeded() async {
    if (!mounted) return;
    final serverEmpty =
        (AppAuthProvider.shared.userProfile?.fullName.trim().isEmpty ?? true);
    if (!serverEmpty) return;
    if (_nicknameController.text.trim().isNotEmpty) return;
    final n = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (n != null && n.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final cached = displayNameFromApplePrefs(prefs);
    if (cached.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _nicknameController.text = cached;
    });
  }

  /// Sign in with Apple 직후 등 Firebase 프로필이 갱신된 뒤 표시 이름을 닉네임 필드에 반영합니다.
  Future<void> _syncDisplayNameAndPhotoFromFirebase() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null || !mounted) return;
    try {
      await fb.reload();
    } catch (_) {
      // 네트워크 등 — 기존 캐시 값으로 진행
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    final name = user.displayName?.trim();
    final photo = user.photoURL;

    // 서버에 저장된 닉네임이 없고, 칸이 비어 있으면 Firebase(Apple이 넘긴 표시 이름)로 채움
    final serverName =
        AppAuthProvider.shared.userProfile?.fullName.trim() ?? '';
    final needsNameFromFirebase =
        serverName.isEmpty && (_nicknameController.text.trim().isEmpty);
    final hasFirebaseName = name != null && name.isNotEmpty;

    if (needsNameFromFirebase && hasFirebaseName) {
      setState(() {
        _nicknameController.text = name;
      });
    } else {
      await _applyCachedAppleDisplayNameIfNeeded();
    }

    if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
      if (photo != null && photo.isNotEmpty) {
        setState(() {
          _profileImageUrl = photo;
        });
      }
    }

    // 한 번 더 지연 후 동기화 (Apple updateDisplayName 타이밍 대비)
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (_) {}
    final u2 = FirebaseAuth.instance.currentUser;
    if (u2 == null || !mounted) return;
    final n2 = u2.displayName?.trim();
    if (n2 != null &&
        n2.isNotEmpty &&
        _nicknameController.text.trim().isEmpty &&
        (AppAuthProvider.shared.userProfile?.fullName.trim().isEmpty ?? true)) {
      setState(() {
        _nicknameController.text = n2;
      });
    }
    await _applyCachedAppleDisplayNameIfNeeded();
  }

  Future<void> _ensureGuidelinesThenContinue() async {
    final accepted = await isCommunityGuidelinesAccepted();
    if (accepted) return;
    if (!mounted) return;

    final ok = await ensureCommunityGuidelinesAccepted(context);
    if (!mounted) return;
    if (!ok) {
      await AppAuthProvider.shared.logout();
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    if (!await requestPhotoPermission(context)) return;
    final files = await MediaPickerService.pickImages(context, maxCount: 1);
    final picked = files?.isNotEmpty == true ? files!.first : null;
    if (picked == null) return;

    setState(() {
      _isUploadingProfileImage = true;
    });

    try {
      final api = ApiService.shared;
      final url = await api.uploadProfileImage(File(picked.path));
      if (!mounted) return;
      setState(() {
        _profileImageUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필 사진 업로드 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfileImage = false;
        });
      }
    }
  }

  Future<void> _pickBackgroundImage() async {
    debugPrint('🟡 [ProfileSetup] 배경 사진 선택 시작');
    if (!await requestPhotoPermission(context)) return;
    final files = await MediaPickerService.pickImages(context, maxCount: 1);
    final picked = files?.isNotEmpty == true ? files!.first : null;
    if (picked == null) {
      debugPrint('⚠️ [ProfileSetup] 배경 사진 선택 취소 또는 없음');
      return;
    }

    setState(() {
      _isUploadingBackgroundImage = true;
    });

    try {
      final fileToUpload = File(picked.path);
      final fileSize = await fileToUpload.length();
      debugPrint(
          '🟡 [ProfileSetup] 배경 업로드 시작: path=${fileToUpload.path}, size=$fileSize bytes');

      final api = ApiService.shared;
      final url = await api.uploadBackgroundImage(fileToUpload);
      debugPrint('✅ [ProfileSetup] 배경 업로드 성공: $url');
      if (!mounted) return;
      setState(() {
        _backgroundImageUrl = url;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileSetup] 배경 업로드 실패: $e');
      debugPrint('❌ [ProfileSetup] 스택: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('배경 사진 업로드 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBackgroundImage = false;
        });
      }
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLifeSceneId == null || _selectedInteractionStyleId == null) {
      final opts = SettingsProvider.shared.profileStyleOptions;
      if (opts != null) {
        ProfileStyleSection.showStylePickerSheet(
          context,
          lifeSceneId: _selectedLifeSceneId,
          selfStatementId: _selectedSelfStatementId,
          interactionStyleId: _selectedInteractionStyleId,
          opts: opts,
          onUpdate: ({
            lifeSceneId,
            selfStatementId,
            interactionStyleId,
          }) async {
            setState(() {
              if (lifeSceneId != null) {
                _selectedLifeSceneId = lifeSceneId;
              }
              if (selfStatementId != null) {
                _selectedSelfStatementId = selfStatementId;
              }
              if (interactionStyleId != null) {
                _selectedInteractionStyleId = interactionStyleId;
              }
            });
          },
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스타일을 등록해 주세요')),
        );
      });
      return;
    }

    var fullNameForApi = _nicknameController.text.trim();
    if (fullNameForApi.isEmpty &&
        AppAuthProvider.shared.userProfile == null) {
      fullNameForApi = await _resolveLoginDisplayNameForNickname();
      if (fullNameForApi.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인에서 표시 이름을 불러올 수 없습니다. 잠시 후 다시 시도해주세요.'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ApiService.shared.updateProfile(
        fullName: fullNameForApi,
        gender: _selectedGender,
        bio: _bioController.text.trim(),
        profileImageUrl: _profileImageUrl,
        backgroundImageUrl: _backgroundImageUrl,
        lifeSceneId: _selectedLifeSceneId,
        selfStatementId: _selectedSelfStatementId,
        interactionStyleId: _selectedInteractionStyleId,
        kakaoId: AppAuthProvider.shared.kakaoId,
      );

      if (!mounted) return;

      if (result is Map && result['custom_token'] != null) {
        await AppAuthProvider.shared.signInWithCustomToken(
          result['custom_token'] as String,
        );
      } else {
        AppAuthProvider.shared.setUserProfile(result as User);
      }

      if (!mounted) return;

      // 프로필 설정 완료 콜백 호출
      if (widget.onComplete != null) {
        await widget.onComplete!();
      } else {
        // 이전 화면으로 돌아감 (true 반환)
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필 업데이트 실패: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: widget.embeddedInProfile
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              centerTitle: true,
              automaticallyImplyLeading: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppTheme.textPrimaryColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                '프로필 설정',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppTheme.dividerColor.withOpacity(0.3),
                ),
              ),
            ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // 안내 문구
                const Text(
                  '프로필을 완성해주세요',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '이 정보는 다른 회원들에게 공개됩니다',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondaryColor.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 40),

                // 프로필 사진 미리보기 (배경 + 아바타)
                Text(
                  '프로필 사진',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ProfilePhotoEditView(
                  backgroundImageUrl: _backgroundImageUrl,
                  profileImageUrl: _profileImageUrl,
                  isUploadingBackground: _isUploadingBackgroundImage,
                  isUploadingProfile: _isUploadingProfileImage,
                  onTapBackground: _pickBackgroundImage,
                  onTapProfile: _pickProfileImage,
                ),

                const SizedBox(height: 24),

                // 성별 선택
                Text(
                  '성별',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('남성'),
                      selected: _selectedGender == 'male',
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? 'male' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('여성'),
                      selected: _selectedGender == 'female',
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? 'female' : null;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 자기소개
                Text(
                  '자기소개',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: '간단한 자기소개를 입력해주세요',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '자기소개를 입력해주세요';
                    }
                    if (value.trim().length < 2) {
                      return '자기소개는 2자 이상 입력해주세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 닉네임 입력
                Text(
                  '닉네임',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: '닉네임을 입력해주세요',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppTheme.textSecondaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  validator: (value) {
                    final t = value?.trim() ?? '';
                    final isFirstProfileSetup =
                        AppAuthProvider.shared.userProfile == null;
                    // 최초 프로필: 가이드상 닉네임 입력을 강제하지 않음(제출 시 로그인 표시 이름 사용)
                    if (isFirstProfileSetup) {
                      if (t.isEmpty) return null;
                      if (t.length < 2) {
                        return '닉네임은 최소 2자 이상이어야 합니다';
                      }
                      return null;
                    }
                    if (t.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    if (t.length < 2) {
                      return '닉네임은 최소 2자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 나를 설명하면 이런 편이에요 (스타일 섹션)
                ListenableBuilder(
                  listenable: SettingsProvider.shared,
                  builder: (context, _) {
                    final opts = SettingsProvider.shared.profileStyleOptions;
                    if (opts == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    String? _resolve(
                        String? id, List<ProfileStyleOption> list) {
                      if (id == null) return null;
                      try {
                        return list.firstWhere((e) => e.id == id).text;
                      } catch (_) {
                        return null;
                      }
                    }

                    return ProfileStyleSection(
                      sectionTitle: opts.description,
                      lifeSceneText:
                          _resolve(_selectedLifeSceneId, opts.lifeScenes),
                      selfStatementText: _resolve(
                          _selectedSelfStatementId, opts.selfStatements),
                      interactionStyleText: _resolve(
                          _selectedInteractionStyleId, opts.interactionStyles),
                      showSettingsButton: true,
                      onSettingsTap: () {
                        ProfileStyleSection.showStylePickerSheet(
                          context,
                          lifeSceneId: _selectedLifeSceneId,
                          selfStatementId: _selectedSelfStatementId,
                          interactionStyleId: _selectedInteractionStyleId,
                          opts: opts,
                          onUpdate: ({
                            lifeSceneId,
                            selfStatementId,
                            interactionStyleId,
                          }) async {
                            setState(() {
                              if (lifeSceneId != null)
                                _selectedLifeSceneId = lifeSceneId;
                              if (selfStatementId != null)
                                _selectedSelfStatementId = selfStatementId;
                              if (interactionStyleId != null)
                                _selectedInteractionStyleId =
                                    interactionStyleId;
                            });
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 48),

                // 미리보기 & 완료 버튼
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final userProfile = AppAuthProvider.shared.userProfile;
                        final opts =
                            SettingsProvider.shared.profileStyleOptions;
                        String? _findText(
                            List<ProfileStyleOption>? list, String? id) {
                          if (list == null || id == null) return null;
                          try {
                            return list.firstWhere((e) => e.id == id).text;
                          } catch (_) {
                            return null;
                          }
                        }

                        UserProfileView.showPreview(
                          context,
                          fullName: _nicknameController.text.trim().isEmpty
                              ? '닉네임'
                              : _nicknameController.text.trim(),
                          profileImageUrl: _profileImageUrl,
                          backgroundImageUrl: _backgroundImageUrl,
                          bio: _bioController.text.trim().isEmpty
                              ? null
                              : _bioController.text.trim(),
                          gender: _selectedGender,
                          createdAt: userProfile?.createdAt,
                          trustScore: userProfile?.trustScore ?? 70,
                          lifeSceneText:
                              _findText(opts?.lifeScenes, _selectedLifeSceneId),
                          selfStatementText: _findText(
                              opts?.selfStatements, _selectedSelfStatementId),
                          interactionStyleText: _findText(
                              opts?.interactionStyles,
                              _selectedInteractionStyleId),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '미리보기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ).copyWith(elevation: MaterialStateProperty.all(0)),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                '완료',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
