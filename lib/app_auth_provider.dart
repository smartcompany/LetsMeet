import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/scheduler.dart';
import 'package:share_lib/share_lib_auth.dart';
import 'models/user.dart';
import 'services/api_service.dart';

/// 앱 전역 인증 프로바이더 싱글턴.
/// - 읽을 때: AppAuthProvider.shared.xxx
/// - shared 최초 접근 시 initialize() 자동 호출.
class AppAuthProvider extends AuthProvider<User> {
  static AppAuthProvider? _instance;

  /// 싱글턴 인스턴스. 최초 접근 시 생성 후 initialize() 스케줄.
  static AppAuthProvider get shared {
    _instance ??= AppAuthProvider._();
    return _instance!;
  }

  static const String _googleServerClientId =
      '225419812075-n7imgrhem59uo9bdtpfkr9v92jb0ro3o.apps.googleusercontent.com';

  AppAuthProvider._()
      : super(
          firebaseAuth: FirebaseAuth.instance,
          authService: ApiService.shared,
          googleServerClientId: _googleServerClientId,
        ) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      initialize();
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        fbUser.getIdToken().then((token) {
          if (token != null) {
            ApiService.shared.setToken(token);
          }
        });
      }
    });
  }
}
