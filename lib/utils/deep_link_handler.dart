import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../screens/meeting_detail_screen.dart';

/// 모임 딥링크 처리
/// - letsmeet://meeting/{id}
/// - https://lets-meet-server.vercel.app/meeting/{id}
class DeepLinkHandler {
  static String? _parseMeetingId(Uri uri) {
    // letsmeet://meeting/123
    if (uri.scheme == 'letsmeet' && uri.host == 'meeting') {
      final path = uri.path;
      if (path.isNotEmpty && path.startsWith('/')) {
        return path.substring(1).split('/').first;
      }
    }
    // https://lets-meet-server.vercel.app/meeting/123
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.path.startsWith('/meeting/')) {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'meeting') {
        return segments[1];
      }
    }
    return null;
  }

  static void init(GlobalKey<NavigatorState> navigatorKey) {
    final appLinks = AppLinks();

    void handleUri(Uri? uri) {
      if (uri == null) return;
      final meetingId = _parseMeetingId(uri);
      if (meetingId == null || meetingId.isEmpty) return;

      final context = navigatorKey.currentContext;
      if (context == null) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MeetingDetailScreen(meetingId: meetingId),
        ),
      );
    }

    // 앱이 링크로 실행된 경우 (콜드 스타트)
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleUri(uri);
        });
      }
    });

    // 앱이 이미 실행 중일 때 링크 수신
    appLinks.uriLinkStream.listen((uri) {
      handleUri(uri);
    });
  }
}
