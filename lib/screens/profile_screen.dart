import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'profile_setup_screen.dart';
import 'my_meetings_screen.dart';
import 'my_feeds_screen.dart';
import 'delete_account_screen.dart';
import 'community_guidelines_screen.dart';
import 'blocked_list_screen.dart';
import '../widgets/profile_card.dart';
import '../widgets/profile_style_section.dart';
import '../widgets/auth_required_content.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthRequiredContent(
      child: Consumer<AuthProvider<User>>(
        builder: (context, authProvider, _) {
          final userProfile = authProvider.userProfile!;
          return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 프로필 카드 (스타일 제외)
              ProfileCard(
                fullName: userProfile.fullName,
                profileImageUrl: userProfile.profileImageUrl,
                backgroundImageUrl: userProfile.backgroundImageUrl,
                createdAt: userProfile.createdAt,
                bio: userProfile.bio,
                gender: userProfile.gender,
                trustScore: userProfile.trustScore,
                trustLevel: userProfile.trustLevel,
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
                    lifeSceneText:
                        _resolve(userProfile.lifeSceneId, opts.lifeScenes),
                    selfStatementText: _resolve(
                        userProfile.selfStatementId, opts.selfStatements),
                    interactionStyleText: _resolve(
                        userProfile.interactionStyleId, opts.interactionStyles),
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
                    icon: Icons.feed_rounded,
                    title: '내 피드 보기',
                    onTap: () async {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyFeedsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.block_rounded,
                    title: '차단 목록',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BlockedListScreen(),
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
                    icon: Icons.delete_forever_rounded,
                    title: '계정 삭제',
                    titleColor: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeleteAccountScreen(),
                        ),
                      );
                    },
                  ),
                  if (kDebugMode)
                    _MenuItem(
                      icon: Icons.assignment_outlined,
                      title: '약관 동의 초기화 (테스트용)',
                      onTap: () async {
                        await resetCommunityGuidelinesAcceptedForTesting();
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('초기화 완료'),
                            content: const Text(
                              '약관 동의 상태를 초기화했습니다.\n'
                              '로그아웃 후 다시 로그인하면 약관 화면이 표시됩니다.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        );
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
                        await clearCommunityGuidelinesAccepted();
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
      ),
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
