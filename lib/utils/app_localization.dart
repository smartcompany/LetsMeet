import 'dart:ui';

/// 앱 표시 이름 (로케일별)
/// - 한국어: 이음터
/// - 영어: Gather
class AppLocalization {
  static String appName([Locale? locale]) {
    final loc = locale ?? PlatformDispatcher.instance.locale;
    if (loc.languageCode == 'ko') return '이음터';
    return 'Gather';
  }
}
