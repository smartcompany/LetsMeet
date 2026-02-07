import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart' as app_models;
import '../theme/app_theme.dart';

/// 프로필 카드 공통 위젯
/// 배경 사진, 프로필 사진, 이름, 가입일, 자기소개, 신뢰도 배지, 관심사 표시
class ProfileCard extends StatelessWidget {
  final String fullName;
  final String? profileImageUrl;
  final String? backgroundImageUrl;
  final DateTime? createdAt;
  final String? bio;
  final String? gender;
  final int? trustScore;
  final app_models.TrustLevel? trustLevel;
  final bool showTrustBadge;
  final bool showStyleSentences;
  final String? lifeSceneText;
  final String? selfStatementText;
  final String? interactionStyleText;
  final EdgeInsetsGeometry? margin;

  const ProfileCard({
    super.key,
    required this.fullName,
    this.profileImageUrl,
    this.backgroundImageUrl,
    this.createdAt,
    this.bio,
    this.gender,
    this.trustScore,
    this.trustLevel,
    this.showTrustBadge = true,
    this.showStyleSentences = true,
    this.lifeSceneText,
    this.selfStatementText,
    this.interactionStyleText,
    this.margin,
  });

  String _formatJoinDate(DateTime date) {
    return DateFormat('yyyy년 M월', 'ko_KR').format(date) + ' 가입';
  }

  static Color _getTrustLevelColor(app_models.TrustLevel level) {
    switch (level) {
      case app_models.TrustLevel.trust:
        return const Color(0xFF10B981);
      case app_models.TrustLevel.stable:
        return const Color(0xFF3B82F6);
      case app_models.TrustLevel.caution:
        return const Color(0xFFF59E0B);
      case app_models.TrustLevel.restricted:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBackgroundImage =
        backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty;

    return Container(
      margin: margin ?? const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (hasBackgroundImage)
                AspectRatio(
                  aspectRatio: 16 / 6,
                  child: Image.network(
                    backgroundImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderBanner(),
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 6,
                  child: _buildPlaceholderBanner(),
                ),
              Positioned(
                bottom: -40,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null || profileImageUrl!.isEmpty
                        ? Text(
                            fullName.isNotEmpty ? fullName[0] : '?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (createdAt != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatJoinDate(createdAt!),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                if (gender != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    gender == 'male' ? '남성' : '여성',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                bio!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (showTrustBadge && trustLevel != null && trustScore != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getTrustLevelColor(trustLevel!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: _getTrustLevelColor(trustLevel!),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trustLevel!.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getTrustLevelColor(trustLevel!),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${trustScore}점',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showStyleSentences &&
              (lifeSceneText != null ||
                  selfStatementText != null ||
                  interactionStyleText != null)) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (lifeSceneText != null && lifeSceneText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        lifeSceneText!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (selfStatementText != null && selfStatementText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        selfStatementText!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (interactionStyleText != null &&
                      interactionStyleText!.isNotEmpty)
                    Text(
                      interactionStyleText!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 24),
        ],
      ),
    );
  }

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
    );
  }
}
