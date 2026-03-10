import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../utils/app_localization.dart';
import '../utils/auth_helper.dart';
import '../providers/meeting_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'feed_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'create_meeting_screen.dart';
import 'meeting_evaluation_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen>
    with WidgetsBindingObserver {
  final ValueNotifier<int> _chatUnreadNotifier = ValueNotifier<int>(0);
  bool _showSearchBar = false;
  bool _isCheckingEvaluations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationProvider.shared.loadUnreadCount();
      _checkPendingEvaluations();
    });
  }

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _chatUnreadNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingEvaluations();
    }
  }

  Future<void> _checkPendingEvaluations() async {
    if (_isCheckingEvaluations || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isCheckingEvaluations = true);
    try {
      final pending = await ApiService.shared.getPendingEvaluations();
      if (!mounted || pending.isEmpty) return;

      final first = pending.first;
      final meetingId = first['id'] as String?;
      final title = first['title'] as String? ?? '모임';

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('모임 평가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('참여한 모임에 대한 평가가 있습니다.'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('이 모임에 대해 평가를 작성하시겠습니까?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitEmptyAndCheckNext(meetingId!);
              },
              child: const Text('평가 안함'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openEvaluationScreenWithLoading(meetingId!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('평가하기'),
            ),
          ],
        ),
      );
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isCheckingEvaluations = false);
    }
  }

  Future<void> _submitEmptyAndCheckNext(String meetingId) async {
    try {
      await ApiService.shared.submitMeetingEvaluation(meetingId);
    } catch (_) {}
    if (mounted) _checkPendingEvaluations();
  }

  Future<void> _openEvaluationScreenWithLoading(String meetingId) async {
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('평가 화면 불러오는 중...')),
            ],
          ),
        ),
      ),
    );
    try {
      final meeting = await ApiService.shared.getMeeting(meetingId);
      if (!mounted) return;
      navigator.pop();
      if (!mounted) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (ctx) => MeetingEvaluationScreen(meeting: meeting),
        ),
      );
    } catch (e) {
      if (mounted) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('불러오기 실패: $e')),
        );
      }
    }
    if (mounted) _checkPendingEvaluations();
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
          final meetingProvider = MeetingProvider.shared;
          final notificationProvider = NotificationProvider.shared;
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
                    NotificationProvider.shared.loadUnreadCount();
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
      child: ListenableBuilder(
        listenable: Listenable.merge([
          MeetingProvider.shared,
          NotificationProvider.shared,
        ]),
        builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        extendBody: false,
        extendBodyBehindAppBar: false,
        // 키보드가 올라와도 레이아웃을 줄이지 않음 → FAB이 화면 맨 아래에 남아 키보드 뒤로 가려짐
        resizeToAvoidBottomInset: false,
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
                      final navigator = Navigator.of(context);
                      final isAuthenticated = await AuthHelper.requireAuth(
                        context,
                      );
                      if (!isAuthenticated || !mounted) return;

                      navigator.push(
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
