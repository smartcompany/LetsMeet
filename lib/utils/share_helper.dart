import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

import '../widgets/share_options_sheet.dart';

/// 앱/모임 공유 링크 (서버 applink · meeting 랜딩)
class ShareHelper {
  ShareHelper._();

  static const String webBase = 'https://lets-meet-server.vercel.app';

  /// 앱 다운로드 · 스토어 리다이렉트 (settings `down_load_url` → AdService)
  static String get appShareUrl {
    final fromSettings = AdService.shared.downloadUrl?.trim();
    if (fromSettings != null && fromSettings.isNotEmpty) {
      return fromSettings;
    }
    return '$webBase/applink';
  }

  /// 모임 딥링크 랜딩 (Universal Link / 앱에서 열기)
  static String meetingShareUrl(String meetingId) =>
      '$webBase/meeting/$meetingId';

  static Future<void> shareApp(BuildContext context) async {
    const appName = '이음터';
    final url = appShareUrl;
    debugPrint(
      '[ShareHelper] shareApp '
      'down_load_url=${AdService.shared.downloadUrl} '
      'resolved=$url',
    );
    final link = Uri.parse(url);
    await ShareOptionsSheet.show(
      context: context,
      title: '앱 공유하기',
      shareText: '$appName에서 소소한 모임을 만나보세요!',
      subject: '$appName 앱 공유',
      linkUrl: link,
      linkButtonTitle: '앱 다운로드',
    );
  }

  static Future<void> shareMeeting(
    BuildContext context, {
    required String meetingId,
    required String title,
  }) async {
    final url = meetingShareUrl(meetingId);
    debugPrint('[ShareHelper] shareMeeting meetingId=$meetingId url=$url');
    final link = Uri.parse(url);
    await ShareOptionsSheet.show(
      context: context,
      title: '모임 공유하기',
      shareText: '이음터에서 "$title" 모임을 초대합니다!',
      kakaoShareText: '이음터에서 "$title" 모임을 초대합니다!',
      subject: '$title 모임 공유',
      linkUrl: link,
      linkButtonTitle: '모임 보기',
    );
  }
}
