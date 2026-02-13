import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_card.dart';
import 'feed_comments_sheet.dart';
import 'my_feeds_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  FeedScreenState createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen> {
  bool _isLoading = true;
  List<Feed> _feeds = [];
  final Map<String, bool> _likingFeeds = {}; // 좋아요 처리 중인 피드 ID

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeeds();
    });
  }

  // 외부에서 호출할 수 있는 새로고침 메서드
  void refresh() {
    _loadFeeds();
  }

  Future<void> _toggleLike(Feed feed) async {
    if (_likingFeeds[feed.id] == true) return; // 이미 처리 중이면 무시

    setState(() {
      _likingFeeds[feed.id] = true;
      // 낙관적 업데이트
      final index = _feeds.indexWhere((f) => f.id == feed.id);
      if (index != -1) {
        _feeds[index] = Feed(
          id: feed.id,
          authorId: feed.authorId,
          authorName: feed.authorName,
          authorProfileImage: feed.authorProfileImage,
          content: feed.content,
          imageUrls: feed.imageUrls,
          likeCount: feed.isLiked ? feed.likeCount - 1 : feed.likeCount + 1,
          commentCount: feed.commentCount,
          isLiked: !feed.isLiked,
          createdAt: feed.createdAt,
          updatedAt: feed.updatedAt,
        );
      }
    });

    try {
      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }

      await apiService.toggleFeedLike(feed.id);
      // 성공 시 피드 목록 새로고침
      await _loadFeeds();
    } catch (e) {
      // 실패 시 원래 상태로 복구
      await _loadFeeds();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좋아요 처리 실패: $e')));
      }
    } finally {
      setState(() {
        _likingFeeds[feed.id] = false;
      });
    }
  }

  Future<void> _showComments(Feed feed) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(feedId: feed.id),
    );
    // 댓글 시트가 닫힌 후 피드 목록 새로고침 (댓글 개수 업데이트)
    if (result == true || mounted) {
      _loadFeeds();
    }
  }

  Future<void> _loadFeeds() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }
      final feeds = await apiService.getFeeds();
      setState(() {
        _feeds = feeds..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('피드를 불러오는데 실패했습니다: $e')));
      }
    }
  }

  void _navigateToMyFeeds() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const MyFeedsScreen(),
      ),
    );
    if (mounted && created == true) {
      refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드가 등록되었습니다.')),
      );
    }
  }

  Widget _buildWriteFeedPrompt() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _navigateToMyFeeds,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? Text(
                      (user.displayName?.isNotEmpty == true
                              ? user.displayName!.substring(0, 1)
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '무슨 생각을 하고 계신가요?',
                  style: TextStyle(
                    color: AppTheme.textTertiaryColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final writePrompt = _buildWriteFeedPrompt();

    if (_feeds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFeeds,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              writePrompt,
              SizedBox(
                height: MediaQuery.of(context).size.height - 220,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.feed_outlined,
                        size: 64,
                        color: AppTheme.textTertiaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '아직 올라온 피드가 없습니다.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeeds,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: writePrompt),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final feed = _feeds[index];
                  return FeedCard(
                    feed: feed,
                    onLike: () => _toggleLike(feed),
                    onComment: () => _showComments(feed),
                  );
                },
                childCount: _feeds.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
