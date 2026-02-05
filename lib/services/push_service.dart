import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'api_service.dart';

/// 백그라운드/종료 상태에서 수신한 메시지 핸들러
/// main() 최상단에서 등록해야 함
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
      '[PushService] Background: ${message.notification?.title} - ${message.notification?.body}');
  debugPrint('[PushService] Data: ${message.data}');
}

/// 푸시 알림 서비스
class PushService {
  PushService({required ApiService apiService}) : _apiService = apiService;

  final ApiService _apiService;

  /// 웹 푸시용 VAPID 키 (Firebase Console → Project settings → Cloud Messaging → Web Push certificates)
  static const String? _vapidKeyWeb =
      'BJMXYRTBLsB5no6QO7Ou3htptQK1A2cqsypxX6M4BBejdcY392-rieqFIMEpoaVQPALubRQO4S0Yvw1AdUW5fK0';

  /// 푸시 알림 초기화 (권한 요청, 토큰 획득, 핸들러 등록)
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 알림 권한 요청 (iOS, Web)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushService] 푸시 권한 거부됨');
        return;
      }

      // 토큰 획득 (웹은 VAPID 키 필요 시 push_service.dart의 _vapidKeyWeb 설정)
      final token = await (kIsWeb && _vapidKeyWeb != null
          ? messaging.getToken(vapidKey: _vapidKeyWeb!)
          : messaging.getToken());

      if (token != null) {
        debugPrint('[PushService] FCM Token 획득');
        await _saveTokenToServer(token);
      }

      // 토큰 갱신 리스너
      messaging.onTokenRefresh.listen(_saveTokenToServer);

      // 포그라운드 메시지
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // 알림 탭으로 앱 열었을 때
      _handleInitialMessage();
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    } catch (e) {
      debugPrint('[PushService] 초기화 오류: $e');
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      await _apiService.saveFcmToken(token);
      debugPrint('[PushService] FCM 토큰 서버 저장 완료');
    } catch (e) {
      debugPrint('[PushService] 토큰 저장 실패: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[PushService] Foreground: ${message.notification?.title}');
    debugPrint('[PushService] Body: ${message.notification?.body}');
    debugPrint('[PushService] Data: ${message.data}');
    // TODO: 로컬 알림 표시 또는 인앱 배너 등
  }

  Future<void> _handleInitialMessage() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _navigateFromNotification(initial);
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _navigateFromNotification(message);
  }

  void _navigateFromNotification(RemoteMessage message) {
    final data = message.data;
    debugPrint('[PushService] 알림 탭 → data: $data');
    // TODO: data['screen'], data['roomId'] 등으로 딥링크 네비게이션
  }
}
