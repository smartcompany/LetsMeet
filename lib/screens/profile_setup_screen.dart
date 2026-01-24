import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo_preview.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Future<void> Function()? onComplete;

  const ProfileSetupScreen({super.key, this.onComplete});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final List<String> _selectedInterests = [];
  bool _isSubmitting = false;
  String? _selectedGender; // 'male' or 'female'
  String? _profileImageUrl;
  String? _backgroundImageUrl;
  bool _isUploadingProfileImage = false;
  bool _isUploadingBackgroundImage = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _availableInterests = [
    '디자인',
    '개발',
    '협업',
    '독서',
    '글쓰기',
    '문화',
    '요리',
    '음식',
    '환경',
    '라이프스타일',
    '지속가능성',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider<User>>().user;
    if (user != null) {
      _nicknameController.text = user.nickname.isNotEmpty ? user.nickname : '';
      _selectedInterests.addAll(user.interests);
      _fullNameController.text = user.fullName ?? '';
      _bioController.text = user.bio ?? '';
      _selectedGender = user.gender;
      _profileImageUrl = user.profileImageUrl;
      _backgroundImageUrl = user.backgroundImageUrl;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
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

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 3) {
          _selectedInterests.add(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('관심사는 최대 3개까지 선택할 수 있습니다')),
          );
        }
      }
    });
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개 이상의 관심사를 선택해주세요')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider<User>>();
      await authProvider.updateProfile(
        nickname: _nicknameController.text.trim(),
        fullName: _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : null,
        gender: _selectedGender,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        profileImageUrl: _profileImageUrl,
        backgroundImageUrl: _backgroundImageUrl,
        interests: _selectedInterests,
      );

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
          onPressed: () {
            // 프로필 설정이 필수인 경우 경고 표시
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  '프로필 설정',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                content: const Text(
                  '프로필 설정을 완료해야 서비스를 이용할 수 있습니다.\n정말 나가시겠습니까?',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(); // 프로필 설정 화면 닫기
                    },
                    child: const Text(
                      '나가기',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
                ProfilePhotoPreview(
                  backgroundImageUrl: _backgroundImageUrl,
                  profileImageUrl: _profileImageUrl,
                  isUploadingBackground: _isUploadingBackgroundImage,
                  isUploadingProfile: _isUploadingProfileImage,
                  onTapBackground: _pickBackgroundImage,
                  onTapProfile: _pickProfileImage,
                ),

                // 이하 섹션(이름, 성별, 닉네임)들과 동일한 체감 간격을 위해 24로 조정
                const SizedBox(height: 24),

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
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    hintText: '이름을 입력해주세요 (선택)',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
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

                // 관심사 선택
                Text(
                  '관심사 (최대 3개)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return GestureDetector(
                      onTap: () => _toggleInterest(interest),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.8),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.dividerColor.withOpacity(0.5),
                            width: isSelected ? 0 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.white,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                size: 18,
                                color: AppTheme.textSecondaryColor,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              interest,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 48),

                // 완료 버튼
                SizedBox(
                  width: double.infinity,
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
          ),
        ),
      ),
    );
  }
}
