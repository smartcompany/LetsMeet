import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('전화번호를 입력해주세요')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.sendOtp(_phoneController.text);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호가 전송되었습니다')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')));
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호를 입력해주세요')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.verifyOtp(_phoneController.text, _otpController.text);

      if (!mounted) return;

      // 사용자 정보 확인 후 개인정보 등록 화면으로 이동
      final user = authProvider.user;
      if (user != null && (user.nickname.isEmpty || user.interests.isEmpty)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
        return;
      }

      // 개인정보가 이미 있으면 이전 화면으로 돌아감 (true 반환)
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증 실패: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: AppTheme.textPrimaryColor,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 로고/브랜딩
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    'LetsMeet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // 타이틀
              const Text(
                '시작하기',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '소규모 · 주제 중심 · 질문 기반',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 48),

              // 전화번호 입력
              TextField(
                controller: _phoneController,
                enabled: !_otpSent,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  hintText: '010-1234-5678',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: AppTheme.textSecondaryColor,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofillHints: null,
              ),

              if (_otpSent) ...[
                const SizedBox(height: 20),

                // 인증번호 입력
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: '인증번호',
                    hintText: '6자리 숫자',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppTheme.textSecondaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 32),

                // 인증하기 버튼
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                        ).copyWith(elevation: MaterialStateProperty.all(0)),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                '인증하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 32),

                // 인증번호 받기 버튼
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ).copyWith(elevation: MaterialStateProperty.all(0)),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                '인증번호 받기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 32),

              // 구분선
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '또는',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 소셜 로그인 버튼들
              Column(
                children: [
                  // 카카오 로그인
                  _SocialLoginButton(
                    icon: '🟡',
                    text: '카카오로 시작하기',
                    backgroundColor: const Color(0xFFFEE500),
                    textColor: const Color(0xFF000000),
                    onPressed: () async {
                      try {
                        await context.read<AuthProvider>().loginWithKakao();
                        if (!mounted) return;
                        final user = context.read<AuthProvider>().user;
                        if (user != null &&
                            (user.nickname.isEmpty || user.interests.isEmpty)) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const ProfileSetupScreen(),
                            ),
                          );
                          return;
                        }
                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('카카오 로그인 실패: ${e.toString()}'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 애플 로그인 (iOS만)
                  if (Theme.of(context).platform == TargetPlatform.iOS)
                    _SocialLoginButton(
                      icon: '⚫',
                      text: 'Apple로 시작하기',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      onPressed: () async {
                        try {
                          await context.read<AuthProvider>().loginWithApple();
                          if (!mounted) return;
                          final user = context.read<AuthProvider>().user;
                          if (user != null &&
                              (user.nickname.isEmpty ||
                                  user.interests.isEmpty)) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileSetupScreen(),
                              ),
                            );
                            return;
                          }
                          if (mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Apple 로그인 실패: ${e.toString()}'),
                            ),
                          );
                        }
                      },
                    ),
                  if (Theme.of(context).platform == TargetPlatform.iOS)
                    const SizedBox(height: 12),

                  // 구글 로그인
                  _SocialLoginButton(
                    icon: '🔵',
                    text: 'Google로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: AppTheme.textPrimaryColor,
                    borderColor: AppTheme.dividerColor,
                    onPressed: () async {
                      try {
                        await context.read<AuthProvider>().loginWithGoogle();
                        if (!mounted) return;
                        final user = context.read<AuthProvider>().user;
                        if (user != null &&
                            (user.nickname.isEmpty || user.interests.isEmpty)) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const ProfileSetupScreen(),
                            ),
                          );
                          return;
                        }
                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Google 로그인 실패: ${e.toString()}'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 안내 문구
              Center(
                child: Text(
                  '전화번호는 안전하게 보관되며\n다른 회원에게 공개되지 않습니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiaryColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: authProvider.isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: borderColor ?? backgroundColor,
                width: 1.5,
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
