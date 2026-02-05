import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../utils/auth_helper.dart';
import 'home_screen.dart';
import 'feed_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'create_meeting_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  final ValueNotifier<int> _chatUnreadNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _chatUnreadNotifier.dispose();
    super.dispose();
  }

  // 탭 영역 패딩 및 간격 상수
  static const double _tabBarHorizontalPadding = 8.0;
  static const double _tabBarVerticalPadding = 8.0;
  static const double _tabSpacing = 0.0; // 탭 간 간격 (0이면 spaceEvenly로 자동 간격)

  // 피드 화면 새로고침을 위한 GlobalKey
  final GlobalKey<FeedScreenState> _feedScreenKey =
      GlobalKey<FeedScreenState>();

  // 탭 아이템 크기 상수
  static const double _tabItemHorizontalPadding = 12.0;
  static const double _tabItemVerticalPadding = 4.0;
  static const double _tabIconSize = 23.0;
  static const double _tabIconContainerPadding = 6.0;
  static const double _tabIconContainerRadius = 12.0;
  static const double _tabLabelFontSize = 13.0;
  static const double _tabIconLabelSpacing = 3.0;

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
        // 피드 탭 AppBar
        return AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            '피드',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        );
      case 2:
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
      case 3:
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
            children: [
              const HomeScreen(),
              FeedScreen(key: _feedScreenKey),
              ChatScreen(
                onUnreadCountChanged: (count) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _chatUnreadNotifier.value = count;
                  });
                },
              ),
              const ProfileScreen(),
            ],
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
                      horizontal: _tabBarHorizontalPadding,
                      vertical: _tabBarVerticalPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TabItem(
                          icon: Icons.group_rounded,
                          label: '모임',
                          isSelected: _currentIndex == 0,
                          onTap: () => setState(() => _currentIndex = 0),
                        ),
                        _TabItem(
                          icon: Icons.dynamic_feed_rounded,
                          label: '피드',
                          isSelected: _currentIndex == 1,
                          onTap: () {
                            setState(() => _currentIndex = 1);
                            // 피드 탭으로 이동할 때 새로고침
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _feedScreenKey.currentState?.refresh();
                            });
                          },
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _chatUnreadNotifier,
                          builder: (_, count, __) => _TabItem(
                            icon: Icons.forum_rounded,
                            label: '채팅',
                            isSelected: _currentIndex == 2,
                            onTap: () => setState(() => _currentIndex = 2),
                            badge: count > 0 ? count : null,
                          ),
                        ),
                        _TabItem(
                          icon: Icons.account_circle_rounded,
                          label: '마이페이지',
                          isSelected: _currentIndex == 3,
                          onTap: () => setState(() => _currentIndex = 3),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // 인증이 필요한지 확인
                      final isAuthenticated = await AuthHelper.requireAuth(
                        context,
                      );
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
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                  ),
                ),
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
        padding: EdgeInsets.symmetric(
          horizontal: _MainTabScreenState._tabItemHorizontalPadding,
          vertical: _MainTabScreenState._tabItemVerticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    _MainTabScreenState._tabIconContainerPadding,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      _MainTabScreenState._tabIconContainerRadius,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: _MainTabScreenState._tabIconSize,
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
            SizedBox(height: _MainTabScreenState._tabIconLabelSpacing),
            Text(
              label,
              style: TextStyle(
                fontSize: _MainTabScreenState._tabLabelFontSize,
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
