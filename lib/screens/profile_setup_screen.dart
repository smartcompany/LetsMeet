import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo_edit_view.dart';
import '../widgets/profile_style_section.dart';
import '../widgets/user_profile_view.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Future<void> Function()? onComplete;

  const ProfileSetupScreen({super.key, this.onComplete});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedGender; // 'male' or 'female'
  String? _profileImageUrl;
  String? _backgroundImageUrl;
  bool _isUploadingProfileImage = false;
  bool _isUploadingBackgroundImage = false;
  final ImagePicker _picker = ImagePicker();

  String? _selectedLifeSceneId;
  String? _selectedSelfStatementId;
  String? _selectedInteractionStyleId;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider<User>>().user;
    if (user != null) {
      _nameController.text = user.fullName.isNotEmpty ? user.fullName : '';
      _selectedLifeSceneId = user.lifeSceneId;
      _selectedSelfStatementId = user.selfStatementId;
      _selectedInteractionStyleId = user.interactionStyleId;
      _bioController.text = user.bio ?? '';
      _selectedGender = user.gender;
      _profileImageUrl = user.profileImageUrl;
      _backgroundImageUrl = user.backgroundImageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _isUploadingProfileImage = true;
    });

    try {
      final api = ApiService();
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
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _isUploadingBackgroundImage = true;
    });

    try {
      final api = ApiService();
      final url = await api.uploadBackgroundImage(File(picked.path));
      if (!mounted) return;
      setState(() {
        _backgroundImageUrl = url;
      });
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아하는 시간과 같이 있으면을 선택해주세요')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final authProvider = context.read<AuthProvider<User>>();

      final result = await apiService.updateProfile(
        fullName: _nameController.text.trim(),
        gender: _selectedGender,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        profileImageUrl: _profileImageUrl,
        backgroundImageUrl: _backgroundImageUrl,
        lifeSceneId: _selectedLifeSceneId,
        selfStatementId: _selectedSelfStatementId,
        interactionStyleId: _selectedInteractionStyleId,
        kakaoId: authProvider.kakaoId,
      );

      if (!mounted) return;

      if (result is Map && result['custom_token'] != null) {
        await authProvider.signInWithCustomToken(
          result['custom_token'] as String,
        );
      } else {
        authProvider.setUser(result as User);
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
      appBar: AppBar(
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
                    hintText: '간단한 자기소개를 입력해주세요 (선택)',
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
                ),

                const SizedBox(height: 32),

                // 이름 입력
                Text(
                  '이름',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '이름을 입력해주세요',
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
                    if (value == null || value.trim().isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    if (value.trim().length < 2) {
                      return '닉네임은 최소 2자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 나를 설명하면 이런 편이에요 (스타일 섹션)
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, _) {
                    final opts = settingsProvider.profileStyleOptions;
                    if (opts == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    String? _resolve(String? id, List<ProfileStyleOption> list) {
                      if (id == null) return null;
                      try {
                        return list.firstWhere((e) => e.id == id).text;
                      } catch (_) {
                        return null;
                      }
                    }
                    return ProfileStyleSection(
                      sectionTitle: opts.description,
                      lifeSceneText: _resolve(_selectedLifeSceneId, opts.lifeScenes),
                      selfStatementText: _resolve(_selectedSelfStatementId, opts.selfStatements),
                      interactionStyleText: _resolve(_selectedInteractionStyleId, opts.interactionStyles),
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
                              if (lifeSceneId != null) _selectedLifeSceneId = lifeSceneId;
                              if (selfStatementId != null) _selectedSelfStatementId = selfStatementId;
                              if (interactionStyleId != null) _selectedInteractionStyleId = interactionStyleId;
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
                        final user = context.read<AuthProvider<User>>().user;
                        final opts = context.read<SettingsProvider>().profileStyleOptions;
                        String? _findText(List<ProfileStyleOption>? list, String? id) {
                          if (list == null || id == null) return null;
                          try {
                            return list.firstWhere((e) => e.id == id).text;
                          } catch (_) {
                            return null;
                          }
                        }
                        UserProfileView.showPreview(
                          context,
                          fullName: _nameController.text.trim().isEmpty
                              ? '이름'
                              : _nameController.text.trim(),
                          profileImageUrl: _profileImageUrl,
                          backgroundImageUrl: _backgroundImageUrl,
                          bio: _bioController.text.trim().isEmpty
                              ? null
                              : _bioController.text.trim(),
                          gender: _selectedGender,
                          createdAt: user?.createdAt,
                          trustScore: user?.trustScore ?? 70,
                          lifeSceneText: _findText(opts?.lifeScenes, _selectedLifeSceneId),
                          selfStatementText: _findText(opts?.selfStatements, _selectedSelfStatementId),
                          interactionStyleText: _findText(opts?.interactionStyles, _selectedInteractionStyleId),
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
