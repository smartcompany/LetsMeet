import 'product_analytics_transport.dart';

/// 앱 내 사용자 행동 로그 (대시보드 여정 분석용).
class AppAnalyticsService {
  AppAnalyticsService._();

  static Future<void> initialize() =>
      ProductAnalyticsTransport.shared.initialize();

  static Future<void> log(
    String eventName, {
    Map<String, Object> properties = const {},
  }) =>
      ProductAnalyticsTransport.shared.log(eventName, properties: properties);
}
