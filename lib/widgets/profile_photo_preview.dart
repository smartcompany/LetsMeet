import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 배경 이미지 + 프로필 아바타를 함께 보여주는 공통 위젯
/// - 배경 이미지 상단, 프로필 사진은 배경 하단과 겹쳐서 배치
/// - 배경 탭: onTapBackground, 아바타 탭: onTapProfile
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

  Widget _buildPlaceholderBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: editable
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_outlined,
                    size: 32,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '배경 사진 추가',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 배경 사진 상단
              GestureDetector(
                onTap: !editable || isUploadingBackground
                    ? null
                    : onTapBackground,
                child: AspectRatio(
                  aspectRatio: 16 / 6,
                  child:
                      backgroundImageUrl != null &&
                          backgroundImageUrl!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              backgroundImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderBanner(),
                            ),
                            if (editable)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: isUploadingBackground
                                      ? null
                                      : onTapBackground,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: isUploadingBackground
                                        ? const SizedBox(
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
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
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
                              ),
                          ],
                        )
                      : _buildPlaceholderBanner(),
                ),
              ),

              // 프로필 사진 - 배경 하단 중앙에 겹쳐서 배치
              Positioned(
                bottom: -40,
                child: GestureDetector(
                  onTap: !editable || isUploadingProfile ? null : onTapProfile,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 37,
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          backgroundImage:
                              profileImageUrl != null &&
                                  profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child:
                              profileImageUrl == null ||
                                  profileImageUrl!.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                      ),
                      if (editable)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: InkWell(
                            onTap: isUploadingProfile ? null : onTapProfile,
                            customBorder: const CircleBorder(),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
