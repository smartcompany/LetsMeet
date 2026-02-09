import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localization.dart';
import '../utils/auth_helper.dart';
import '../providers/meeting_provider.dart';
import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
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
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _chatUnreadNotifier.dispose();
    super.dispose();
  }

  // 탭 영역 패딩 상수
  static const double _tabBarHorizontalPadding = 8.0;
  static const double _tabBarVerticalPadding = 8.0;

  // 피드 화면 새로고침을 위한 GlobalKey
  final GlobalKey<FeedScreenState> _feedScreenKey =
      GlobalKey<FeedScreenState>();

  // 탭 아이템 크기 상수
  static const double _tabItemHorizontalPadding = 12.0;
  static const double _tabItemVerticalPadding = 10.0;
  static const double _tabIconSize = 26.0;
  static const double _tabIconContainerPadding = 8.0;
  static const double _tabIconContainerRadius = 14.0;

  int _currentIndex = 0;

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        {
          // 모임 탭 AppBar - 검색, 찜, 알림 아이콘
          final meetingProvider = context.watch<MeetingProvider>();
          final notificationProvider = context.watch<NotificationProvider>();
          if (_showSearchBar) {
            return AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearchBar = false;
                    _searchController.clear();
                    meetingProvider.setSearchQuery('');
                  });
                },
              ),
              title: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '모임 검색',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: meetingProvider.setSearchQuery,
              ),
            );
          }
          return AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: false,
            title: Text(
              AppLocalization.appName(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            titleSpacing: 20,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _showSearchBar = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _searchFocusNode.requestFocus();
                    });
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  meetingProvider.showFavoritesOnly
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: meetingProvider.showFavoritesOnly ? Colors.red : null,
                ),
                onPressed: () {
                  meetingProvider
                      .setShowFavoritesOnly(!meetingProvider.showFavoritesOnly);
                },
              ),
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationProvider.unreadCount > 99
                                ? '99+'
                                : '${notificationProvider.unreadCount}',
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                  if (context.mounted) {
                    context.read<NotificationProvider>().loadUnreadCount();
                  }
                },
              ),
            ],
          );
        }
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
        appBar: _buildAppBar(context),
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
                          isSelected: _currentIndex == 0,
                          onTap: () => setState(() => _currentIndex = 0),
                        ),
                        _TabItem(
                          icon: Icons.dynamic_feed_rounded,
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
                            isSelected: _currentIndex == 2,
                            onTap: () => setState(() => _currentIndex = 2),
                            badge: count > 0 ? count : null,
                          ),
                        ),
                        _TabItem(
                          icon: Icons.account_circle_rounded,
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
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _TabItem({
    required this.icon,
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
        child: Stack(
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
      ),
    );
  }
}
