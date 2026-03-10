import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../app_auth_provider.dart';
import '../config/auth_config.dart';
import '../models/user.dart';
import '../screens/profile_setup_screen.dart';

/// 로그인·프로필 설정 여부를 공통으로 체크하고, 조건에 따라
/// 로그인 안내 / 프로필 설정(임베드) / 로딩 / 실제 콘텐츠 중 하나를 표시합니다.
/// 마이페이지·채팅 탭 등에서 동일 로직으로 사용합니다.
class AuthRequiredContent extends StatelessWidget {
  /// 인증·프로필이 준비되었을 때 보여줄 메인 콘텐츠
  final Widget child;

  const AuthRequiredContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppAuthProvider.shared,
      builder: (context, _) {
        // 로그인 안 되어 있으면 로그인 안내 화면
        if (!AppAuthProvider.shared.isLoggedIn() ||
            AppAuthProvider.shared.needProfileSetup()) {
          return const _LoginPromptContent();
        }

        // 로그인·프로필 로딩 중
        if (AppAuthProvider.shared.userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return child;
      },
    );
  }
}

/// 로그인 안내 + 로그인 버튼
class _LoginPromptContent extends StatelessWidget {
  const _LoginPromptContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  authConfig.primaryColor.withOpacity(0.1),
                  authConfig.primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: authConfig.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            authConfig.getLocalizations(context).loginRequiredTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: authConfig.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              authConfig.getLocalizations(context).loginRequiredDescription,
              style: TextStyle(
                fontSize: 14,
                color: authConfig.textTertiaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onLoginPressed(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: authConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ).copyWith(elevation: MaterialStateProperty.all(0)),
                child: Text(
                  authConfig.getLocalizations(context).loginButtonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLoginPressed(BuildContext context) async {
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

    if (result != true || !context.mounted) return;

    for (var i = 0; i < 50 && context.mounted; i++) {
      if (!AppAuthProvider.shared.isLoading) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!context.mounted) return;

    final u = AppAuthProvider.shared.userProfile;
    final needSetup = u == null ||
        (authConfig.shouldShowProfileSetup != null &&
            authConfig.shouldShowProfileSetup!(u));
    if (needSetup && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileSetupScreen(),
        ),
      );
    }
  }
}
