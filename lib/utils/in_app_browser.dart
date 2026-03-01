import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// App Store Guideline 4.0: 로그인·회원가입 등 웹 콘텐츠를 앱 내에서 표시하기 위해
/// 외부 브라우저(Safari) 대신 앱 내 브라우저(SFSafariViewController on iOS)를 사용합니다.
Future<bool> openUrlInApp(String urlString) async {
  final uri = Uri.tryParse(urlString);
  if (uri == null) return false;
  try {
    return await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
  } catch (e) {
    debugPrint('openUrlInApp failed: $e');
    return false;
  }
}

/// 같은 목적; [Uri] 버전.
Future<bool> openUriInApp(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (e) {
    debugPrint('openUriInApp failed: $e');
    return false;
  }
}
