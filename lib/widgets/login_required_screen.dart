import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/auth_screen.dart';

/// 로그인이 필요한 경우 표시하는 공통 화면 위젯
class LoginRequiredScreen extends StatelessWidget {
  /// 표시할 아이콘 (선택 사항, 기본값 사용)
  final IconData? icon;

  /// 제목 텍스트 (선택 사항, 기본값 사용)
  final String? title;

  /// 설명 텍스트 (선택 사항, 기본값 사용)
  final String? description;

  /// 로그인 버튼 표시 여부
  final bool showLoginButton;

  /// 로그인 버튼 텍스트
  final String? loginButtonText;

  const LoginRequiredScreen({
    super.key,
    this.icon,
    this.title,
    this.description,
    this.showLoginButton = true,
    this.loginButtonText,
  });

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
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.lock_outline_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title ?? '로그인이 필요합니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description ?? '로그인하여 계속 이용하세요',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textTertiaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (showLoginButton) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ).copyWith(elevation: MaterialStateProperty.all(0)),
                  child: Text(
                    loginButtonText ?? '로그인하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
