import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../screens/profile_setup_screen.dart';
import '../models/user.dart';
import '../config/auth_config.dart';

class AuthHelper {
  /// 인증이 필요한 경우 인증 플로우를 시작하고,
  /// 인증이 완료되면 true를 반환합니다.
  /// 이미 인증되어 있으면 true를 반환합니다.
  static Future<bool> requireAuth(BuildContext context) async {
    final authProvider = context.read<AuthProvider<User>>();

    // 이미 로그인되어 있고 개인정보도 있으면 통과
    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      if (user != null &&
          user.nickname.isNotEmpty &&
          user.interests.isNotEmpty) {
        return true;
      }

      // 로그인은 했지만 개인정보가 없으면 프로필 설정으로 이동
      if (user != null && (user.nickname.isEmpty || user.interests.isEmpty)) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
        return result == true;
      }
    }

    // 로그인이 안 되어 있으면 로그인 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthScreen<User>(config: authConfig),
        fullscreenDialog: true,
      ),
    );

    // 로그인 성공 후 개인정보 확인
    if (result == true && context.mounted) {
      final user = authProvider.user;
      if (user != null && (user.nickname.isEmpty || user.interests.isEmpty)) {
        final profileResult = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
        return profileResult == true;
      }
      return true;
    }

    return result == true;
  }
}
