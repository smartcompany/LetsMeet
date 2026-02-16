import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../config/auth_config.dart';
import 'profile_setup_screen.dart';
import 'my_meetings_screen.dart';
import 'my_feeds_screen.dart';
import '../widgets/profile_card.dart';
import '../widgets/profile_style_section.dart';

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

                        // 로그인 성공 후 프로필 없거나 미완성이면 프로필 설정 화면 표시
                        if (result == true && context.mounted) {
                          final ap = context.read<AuthProvider<User>>();
                          // 로딩 완료까지 대기
                          for (var i = 0; i < 50 && context.mounted; i++) {
                            if (!ap.isLoading) break;
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                          }
                          if (!context.mounted) return;
                          final u = context.read<AuthProvider<User>>().user;
                          final needSetup = u == null ||
                              (authConfig.shouldShowProfileSetup != null &&
                                  authConfig.shouldShowProfileSetup!(u));
                          if (needSetup) {
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
              // 프로필 카드 (스타일 제외)
              ProfileCard(
                fullName: user.fullName,
                profileImageUrl: user.profileImageUrl,
                backgroundImageUrl: user.backgroundImageUrl,
                createdAt: user.createdAt,
                bio: user.bio,
                gender: user.gender,
                trustScore: user.trustScore,
                trustLevel: user.trustLevel,
                showTrustBadge: true,
                showStyleSentences: false,
                margin: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),

              // 나를 설명하면 이런 편이에요 (스타일 섹션)
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, _) {
                  final opts = settingsProvider.profileStyleOptions;
                  if (opts == null) return const SizedBox.shrink();
                  String? _resolve(String? id, List<ProfileStyleOption> list) {
                    if (id == null) return null;
                    try {
                      return list.firstWhere((e) => e.id == id).text;
                    } catch (_) {
                      return null;
                    }
                  }
                  return ProfileStyleSection(
                    sectionTitle: opts.description,
                    lifeSceneText: _resolve(user.lifeSceneId, opts.lifeScenes),
                    selfStatementText: _resolve(user.selfStatementId, opts.selfStatements),
                    interactionStyleText: _resolve(user.interactionStyleId, opts.interactionStyles),
                    showSettingsButton: false,
                  );
                },
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
                    icon: Icons.event_note_rounded,
                    title: '내 모임',
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
                    icon: Icons.feed_rounded,
                    title: '내 피드 보기',
                    onTap: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyFeedsScreen(),
                        ),
                      );
                      if (context.mounted && created == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('피드가 등록되었습니다.')),
                        );
                      }
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
