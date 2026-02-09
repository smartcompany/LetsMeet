import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 프로필 편집용 배경 + 아바타 뷰
/// - 변경 버튼 탭: 배경 이미지 변경 (onTapBackground)
/// - 가운데 프로필 원 탭: 프로필 이미지 변경 (onTapProfile)
class ProfilePhotoEditView extends StatelessWidget {
  final String? backgroundImageUrl;
  final String? profileImageUrl;
  final bool isUploadingBackground;
  final bool isUploadingProfile;
  final VoidCallback onTapBackground;
  final VoidCallback onTapProfile;

  const ProfilePhotoEditView({
    super.key,
    required this.backgroundImageUrl,
    required this.profileImageUrl,
    required this.isUploadingBackground,
    required this.isUploadingProfile,
    required this.onTapBackground,
    required this.onTapProfile,
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
      child: Center(
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
      ),
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
      clipBehavior: Clip.none,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 배경 이미지 영역 (아래쪽 여백 포함)
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 6,
                    child: backgroundImageUrl != null &&
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
                              // 변경 버튼 → 배경 이미지 변경
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: onTapBackground,
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
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onTapBackground,
                            child: _buildPlaceholderBanner(),
                          ),
                  ),
                ),
              ),

              // 프로필 원 (가운데 포토) 탭 → 프로필 이미지 변경
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapProfile,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 37,
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: profileImageUrl != null &&
                                  profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null ||
                                  profileImageUrl!.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                      ),
                      // 카메라 아이콘 (시각용, 탭은 부모 GestureDetector가 처리)
                      Positioned(
                        right: -4,
                        bottom: -4,
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
