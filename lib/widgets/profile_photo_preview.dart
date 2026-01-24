import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 배경 이미지 + 프로필 아바타를 함께 보여주는 공통 위젯
/// - 배경 탭: onTapBackground
/// - 아바타 탭: onTapProfile
class ProfilePhotoPreview extends StatelessWidget {
  final String? backgroundImageUrl;
  final String? profileImageUrl;
  final bool isUploadingBackground;
  final bool isUploadingProfile;
  final VoidCallback onTapBackground;
  final VoidCallback onTapProfile;
  final bool editable;

  const ProfilePhotoPreview({
    super.key,
    required this.backgroundImageUrl,
    required this.profileImageUrl,
    required this.isUploadingBackground,
    required this.isUploadingProfile,
    required this.onTapBackground,
    required this.onTapProfile,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 배경(160) + 아바타가 배경보다 약 10px 아래로 살짝 걸치도록 필요한 높이
      height: 180,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 배경 사진
          GestureDetector(
            onTap: !editable || isUploadingBackground ? null : onTapBackground,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(
                  color: AppTheme.dividerColor.withOpacity(0.5),
                ),
                image: backgroundImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(backgroundImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: backgroundImageUrl == null
                  ? (editable
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_outlined,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '배경 사진 추가',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink())
                  : (editable
                        ? Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isUploadingBackground)
                                      const SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '변경',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
            ),
          ),

          // 배경 위에 겹쳐 보이는 프로필 사진
          Positioned(
            // 아바타의 bottom이 배경 bottom(160)보다 약 10px 아래(170)로 오도록 조정
            // Stack 높이 180이므로 bottom = 180 - 170 = 10
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  if (editable)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: isUploadingProfile ? null : onTapProfile,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isUploadingProfile
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
