import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../app_auth_provider.dart';
import '../screens/profile_setup_screen.dart';
import '../models/user.dart';
import '../config/auth_config.dart';

class AuthHelper {
  /// 인증이 필요한 경우 인증 플로우를 시작하고,
  /// 인증이 완료되면 true를 반환합니다.
  /// 이미 인증되어 있으면 true를 반환합니다.
  static Future<bool> requireAuth(BuildContext context) async {
    if (!AppAuthProvider.shared.isLoggedIn()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListenableProvider<AuthProvider<User>>.value(
            value: AppAuthProvider.shared,
            child: AuthScreen<User>(config: authConfig),
          ),
          fullscreenDialog: true,
        ),
      );
      return result == true;
    }

    if (AppAuthProvider.shared.needProfileSetup()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
      return result == true;
    }

    return true;
  }
}
