import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/feed.dart';
import '../models/user.dart' as app_models;
import '../app_auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_card.dart';
import 'feed_comments_sheet.dart';
import 'my_feeds_screen.dart';
import '../utils/ugc_moderation.dart';
import 'package:share_lib/share_lib_auth.dart' as share_lib;

/// 특정 사용자가 작성한 피드 목록 화면 (프로필에서 "피드 보기" 선택 시)
class UserFeedsScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const UserFeedsScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<UserFeedsScreen> createState() => _UserFeedsScreenState();
}

class _UserFeedsScreenState extends State<UserFeedsScreen> {
  bool _isLoading = true;
  List<Feed> _feeds = [];
  final Map<String, bool> _likingFeeds = {};

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _toggleLike(Feed feed) async {
    if (_likingFeeds[feed.id] == true) return;

    setState(() {
      _likingFeeds[feed.id] = true;
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
      await ApiService.shared.toggleFeedLike(feed.id);
      await _loadFeeds();
    } catch (e) {
      await _loadFeeds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('좋아요 처리 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _likingFeeds[feed.id] = false;
      });
    }
  }

  Future<void> _showComments(Feed feed) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(feedId: feed.id),
    );
    if (mounted) {
      _loadFeeds();
    }
  }

  Future<void> _deleteFeed(Feed feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('피드 삭제'),
        content: const Text('정말로 이 피드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.shared.deleteFeed(feed.id);
      if (!mounted) return;
      setState(() => _feeds.removeWhere((f) => f.id == feed.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('피드 삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _loadFeeds() async {
    setState(() => _isLoading = true);
    try {
      final feeds = await ApiService.shared.getFeedsByUser(widget.userId);
      setState(() {
        _feeds = feeds..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('피드를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.displayName}의 피드'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
            Text(
              '작성한 피드가 없습니다.',
              style: const TextStyle(color: AppTheme.textSecondaryColor),
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
          final currentUserId =
              AppAuthProvider.shared.userProfile?.id;
          return FeedCard(
            feed: feed,
            onLike: () => _toggleLike(feed),
            onComment: () => _showComments(feed),
            currentUserId: currentUserId,
            onReport: () => UGCModeration.reportFeed(context, feed),
            onBlockUser: () async {
              await UGCModeration.blockUser(
                context,
                userId: feed.authorId,
                userName: feed.authorName,
              );
              if (!context.mounted) return;
              setState(() {
                _feeds.removeWhere((f) => f.authorId == feed.authorId);
              });
            },
            onEdit: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => MyFeedsScreen(editFeed: feed),
                ),
              );
              if (updated == true && mounted) _loadFeeds();
            },
            onDelete: () => _deleteFeed(feed),
          );
        },
      ),
    );
  }
}
