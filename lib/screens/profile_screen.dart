import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../config/auth_config.dart';
import 'profile_setup_screen.dart';
import 'my_meetings_screen.dart';
import 'my_feeds_screen.dart';
import '../widgets/profile_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider<User>>(
      builder: (context, authProvider, child) {
        if (!authProvider.isInitialized && !authProvider.isInitializing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<AuthProvider<User>>().initialize();
          });
        }

        final user = authProvider.user;

        // 로그인 안 되어 있으면 로그인 안내 화면
        if (user == null) {
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
                    authConfig
                        .getLocalizations(context)
                        .loginRequiredDescription,
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
                      onPressed: () async {
                        // 로그인 화면으로 이동
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AuthScreen<User>(config: authConfig),
                            fullscreenDialog: true,
                          ),
                        );

                        // 로그인 성공 후 프로필이 없으면 프로필 설정 화면 표시
                        if (result == true && context.mounted) {
                          final currentAuthProvider = context
                              .read<AuthProvider<User>>();

                          // 사용자 정보를 가져올 때까지 대기 (최대 3초)
                          int attempts = 0;
                          while (currentAuthProvider.user == null &&
                              !currentAuthProvider.isLoading &&
                              attempts < 30 &&
                              context.mounted) {
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            attempts++;
                          }

                          // 사용자 정보가 없으면 프로필 설정 화면 표시
                          // (카카오 로그인 후 프로필이 아직 설정되지 않은 경우)
                          if (context.mounted &&
                              currentAuthProvider.user == null &&
                              !currentAuthProvider.isLoading) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileSetupScreen(),
                              ),
                            );
                          }
                        }
                      },
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 프로필 카드
              ProfileCard(
                fullName: user.fullName,
                profileImageUrl: user.profileImageUrl,
                backgroundImageUrl: user.backgroundImageUrl,
                createdAt: user.createdAt,
                bio: user.bio,
                gender: user.gender,
                trustScore: user.trustScore,
                trustLevel: user.trustLevel,
                interests: user.interests,
                showTrustBadge: true,
                showInterests: true,
                margin: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // 프로필 수정 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSetupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('프로필 수정'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 설정 메뉴
              _MenuSection(
                items: [
                  _MenuItem(
                    icon: Icons.feed_rounded,
                    title: '내 피드 보기',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyFeedsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.event_note_rounded,
                    title: '내가 만든 모임',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyMeetingsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.settings_rounded,
                    title: '설정',
                    onTap: () {
                      // 설정 화면으로 이동 (추후 구현)
                    },
                  ),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    title: '로그아웃',
                    titleColor: const Color(0xFFEF4444),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text('정말 로그아웃 하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                '로그아웃',
                                style: TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await authProvider.logout();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(children: items.map((item) => item).toList());
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: titleColor ?? AppTheme.textPrimaryColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppTheme.textTertiaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
