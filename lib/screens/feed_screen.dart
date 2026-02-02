import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'feed_comments_sheet.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeeds,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feeds.length,
        itemBuilder: (context, index) {
          final feed = _feeds[index];
          return _FeedCard(
            feed: feed,
            onLike: () => _toggleLike(feed),
            onComment: () => _showComments(feed),
          );
        },
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Feed feed;
  final VoidCallback onLike;
  final VoidCallback onComment;
  const _FeedCard({
    required this.feed,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: feed.authorProfileImage != null
                      ? NetworkImage(feed.authorProfileImage!)
                      : null,
                  child: feed.authorProfileImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('yyyy.MM.dd HH:mm').format(feed.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (feed.imageUrls.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: feed.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    feed.imageUrls[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          Padding(padding: const EdgeInsets.all(16), child: Text(feed.content)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        feed.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: feed.isLiked
                            ? Colors.red
                            : AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${feed.likeCount}',
                        style: TextStyle(
                          fontSize: 14,
                          color: feed.isLiked ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onComment,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${feed.commentCount}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
