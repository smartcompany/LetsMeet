import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

import '../theme/app_theme.dart';
import '../utils/kakao_share_log.dart';

/// LetsMeet 전용 공유 시트
abstract final class ShareOptionsSheet {
  static Rect? _shareOriginFromContext(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String shareText,
    String? kakaoShareText,
    String? subject,
    Uri? linkUrl,
    String linkButtonTitle = '앱에서 열기',
  }) async {
    final shareOrigin = _shareOriginFromContext(context);
    final kakaoAvailable = await ShareService.isKakaoTalkAvailable();
    if (!context.mounted) return;

    final systemText = _mergeTextAndUrl(shareText, linkUrl);
    final kakaoText = kakaoShareText ?? shareText;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '원하는 방식으로 링크를 공유해보세요',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (kakaoAvailable)
                    _ShareActionTile(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF3A1D1D),
                      iconBackground: const Color(0xFFFEE500),
                      title: '카카오톡으로 공유',
                      subtitle: '카카오톡 채팅방으로 바로 보내기',
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        debugPrint(
                          '[ShareOptionsSheet] kakao '
                          'linkUrl=$linkUrl buttonTitle=$linkButtonTitle',
                        );
                        await ShareService.shareToKakao(
                          kakaoText,
                          linkUrl: linkUrl,
                          linkButtonTitle: linkButtonTitle,
                          onShareDefaultUri: (uri) =>
                              logKakaoShareDefaultUri(
                            uri,
                            requestedLinkUrl: linkUrl,
                          ),
                          onError: (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('카카오톡 공유 실패: $error')),
                            );
                          },
                        );
                      },
                    ),
                  _ShareActionTile(
                    icon: Icons.share_outlined,
                    iconColor: AppTheme.primaryColor,
                    iconBackground: AppTheme.primaryColor.withValues(alpha: 0.12),
                    title: '다른 앱으로 공유',
                    subtitle: '메시지, 메일, SNS 등으로 공유',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final ok = await ShareService.shareText(
                        systemText,
                        subject: subject,
                        sharePositionOrigin: shareOrigin,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('공유에 실패했어요')),
                        );
                      }
                    },
                  ),
                  _ShareActionTile(
                    icon: Icons.copy_rounded,
                    iconColor: AppTheme.textPrimaryColor,
                    iconBackground: const Color(0xFFF3F4F6),
                    title: '링크 복사',
                    subtitle: '모임 링크를 클립보드에 복사',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final ok = await ShareService.copyToClipboard(
                        linkUrl?.toString() ?? systemText,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? '링크를 복사했어요' : '복사에 실패했어요'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _mergeTextAndUrl(String shareText, Uri? linkUrl) {
    if (linkUrl == null) return shareText;
    final url = linkUrl.toString();
    if (shareText.contains(url)) return shareText;
    return '$shareText\n$url';
  }
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
