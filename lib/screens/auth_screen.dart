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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSocialLoading = false;
  bool _isEmailLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runSocialLogin(Future<void> Function() action) async {
    if (_isSocialLoading) return;
    setState(() {
      _isSocialLoading = true;
    });
    try {
      await action();
    } finally {
      if (!mounted) return;
      setState(() {
        _isSocialLoading = false;
      });
    }
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요')));
      return;
    }

    if (_isEmailLoading) return;
    setState(() {
      _isEmailLoading = true;
    });
    try {
      await context.read<AuthProvider>().loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user != null && (user.nickname.isEmpty || user.interests.isEmpty)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
        return;
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = '이메일 로그인 실패';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        errorMessage = '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
      } else if (e.toString().contains('Invalid email or password')) {
        errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다.';
      } else if (e.toString().contains('social login')) {
        errorMessage = '이 이메일은 소셜 로그인으로 가입되었습니다. 소셜 로그인을 사용해주세요.';
      } else {
        errorMessage = '이메일 로그인 실패: ${e.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isEmailLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '로그인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        centerTitle: true,
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 소셜 로그인 버튼들
                  Column(
                    children: [
                      // 카카오 로그인
                      _SocialLoginButton(
                        icon: '🟡',
                        text: '카카오로 시작하기',
                        backgroundColor: const Color(0xFFFEE500),
                        textColor: const Color(0xFF000000),
                        isLoading: _isSocialLoading,
                        onPressed: () async {
                          await _runSocialLogin(() async {
                            try {
                              await context
                                  .read<AuthProvider>()
                                  .loginWithKakao();
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
                              String errorMessage = '카카오 로그인 실패';
                              if (e.toString().contains('SocketException') ||
                                  e.toString().contains('Failed host lookup') ||
                                  e.toString().contains('Connection refused')) {
                                errorMessage =
                                    '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
                              } else if (e.toString().contains('YOUR_KAKAO')) {
                                errorMessage =
                                    '카카오 SDK가 설정되지 않았습니다. main.dart에서 카카오 앱 키를 설정해주세요.';
                              } else {
                                errorMessage = '카카오 로그인 실패: ${e.toString()}';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          });
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
                          isLoading: _isSocialLoading,
                          onPressed: () async {
                            await _runSocialLogin(() async {
                              try {
                                await context
                                    .read<AuthProvider>()
                                    .loginWithApple();
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
                                String errorMessage = 'Apple 로그인 실패';
                                if (e.toString().contains('SocketException') ||
                                    e.toString().contains(
                                      'Failed host lookup',
                                    ) ||
                                    e.toString().contains(
                                      'Connection refused',
                                    )) {
                                  errorMessage =
                                      '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
                                } else if (e.toString().contains(
                                      'AuthorizationErrorCode.unknown',
                                    ) ||
                                    e.toString().contains(
                                      'AuthorizationError error 1000',
                                    ) ||
                                    e.toString().contains('error 1000')) {
                                  errorMessage =
                                      'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.';
                                } else {
                                  errorMessage =
                                      'Apple 로그인 실패: ${e.toString()}';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            });
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
                        isLoading: _isSocialLoading,
                        onPressed: () async {
                          await _runSocialLogin(() async {
                            try {
                              await context
                                  .read<AuthProvider>()
                                  .loginWithGoogle();
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
                              String errorMessage = 'Google 로그인 실패';
                              if (e.toString().contains('SocketException') ||
                                  e.toString().contains('Failed host lookup') ||
                                  e.toString().contains('Connection refused')) {
                                errorMessage =
                                    '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
                              } else {
                                errorMessage = 'Google 로그인 실패: ${e.toString()}';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
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
                  // 이메일 로그인
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      hintText: 'example@email.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
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
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isEmailLoading && !_isSocialLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력하세요',
                      prefixIcon: Icon(
                        Icons.lock_outlined,
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
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enabled: !_isEmailLoading && !_isSocialLoading,
                    onSubmitted: (_) => _handleEmailLogin(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isEmailLoading || _isSocialLoading)
                          ? null
                          : _handleEmailLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isEmailLoading
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
                              '로그인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSocialLoading || _isEmailLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
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
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: borderColor ?? backgroundColor, width: 1.5),
        ),
        child: Row(
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
  }
}
