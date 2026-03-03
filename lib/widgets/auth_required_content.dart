import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
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
    return Consumer<AuthProvider<User>>(
      builder: (context, authProvider, _) {
        if (!authProvider.isInitialized && !authProvider.isInitializing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<AuthProvider<User>>().initialize();
          });
        }

        if (!authProvider.isLoggedIn()) {
          return _LoginPromptContent(authProvider: authProvider);
        }

        if (authProvider.needProfileSetup()) {
          return const ProfileSetupScreen(embeddedInProfile: true);
        }

        if (authProvider.userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return child;
      },
    );
  }
}

/// 로그인 안내 + 로그인 버튼 (로그인 성공 시 필요하면 프로필 설정 화면 push)
class _LoginPromptContent extends StatelessWidget {
  final AuthProvider<User> authProvider;

  const _LoginPromptContent({required this.authProvider});

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
        builder: (context) => AuthScreen<User>(config: authConfig),
        fullscreenDialog: true,
      ),
    );

    if (result != true || !context.mounted) return;

    final ap = context.read<AuthProvider<User>>();
    for (var i = 0; i < 50 && context.mounted; i++) {
      if (!ap.isLoading) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!context.mounted) return;

    final u = context.read<AuthProvider<User>>().userProfile;
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
