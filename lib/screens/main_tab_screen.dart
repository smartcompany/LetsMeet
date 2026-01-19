import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/auth_helper.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'create_meeting_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        // 모임 탭 AppBar
        return AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'LetsMeet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      case 1:
        // 채팅 탭 AppBar
        return AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            '채팅',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        );
      case 2:
        // 마이페이지 탭 AppBar
        return AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            '마이페이지',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        );
      default:
        return AppBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        extendBody: false,
        extendBodyBehindAppBar: false,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: const [HomeScreen(), ChatScreen(), ProfileScreen()],
          ),
        ),
        bottomNavigationBar: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 모임 탭
                        _TabItem(
                          icon: Icons.group_rounded,
                          label: '모임',
                          isSelected: _currentIndex == 0,
                          onTap: () => setState(() => _currentIndex = 0),
                        ),

                        // 채팅 탭
                        _TabItem(
                          icon: Icons.forum_rounded,
                          label: '채팅',
                          isSelected: _currentIndex == 1,
                          onTap: () => setState(() => _currentIndex = 1),
                          badge: 6, // 임시 뱃지
                        ),

                        // 중앙 플러스 버튼
                        const SizedBox(width: 40),

                        // 마이페이지 탭
                        _TabItem(
                          icon: Icons.account_circle_rounded,
                          label: '마이페이지',
                          isSelected: _currentIndex == 2,
                          onTap: () => setState(() => _currentIndex = 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // SafeArea 밖 영역까지 흰색 배경 확장
              if (bottomPadding > 0)
                Container(color: Colors.white, height: bottomPadding),
            ],
          ),
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 30),
          child: FloatingActionButton(
            onPressed: () async {
              // 인증이 필요한지 확인
              final isAuthenticated = await AuthHelper.requireAuth(context);
              if (!isAuthenticated || !mounted) return;

              // 인증 완료 후 모임 만들기 화면으로 이동
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateMeetingScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textTertiaryColor,
                  ),
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge! > 9 ? '9+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
