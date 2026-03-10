import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feed.dart';
import '../theme/app_theme.dart';
import 'user_profile_view.dart';

/// 피드 탭/사용자 피드 화면에서 공통으로 사용하는 피드 카드
class FeedCard extends StatelessWidget {
  final Feed feed;
  final VoidCallback onLike;
  final VoidCallback onComment;
  /// 본인 글이 아니면 신고/차단, 본인 글이면 수정/삭제. currentUserId가 null이면 항상 신고/차단만 표시.
  final String? currentUserId;
  final VoidCallback? onReport;
  final VoidCallback? onBlockUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FeedCard({
    super.key,
    required this.feed,
    required this.onLike,
    required this.onComment,
    this.currentUserId,
    this.onReport,
    this.onBlockUser,
    this.onEdit,
    this.onDelete,
  });

  bool get _isMyFeed =>
      currentUserId != null && feed.authorId == currentUserId;

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
            child: InkWell(
              onTap: () => UserProfileView.show(
                context,
                userId: feed.authorId,
                displayName: feed.authorName,
                profileImageUrl: feed.authorProfileImage,
              ),
              borderRadius: BorderRadius.circular(8),
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
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (_isMyFeed) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      } else {
                        if (value == 'report' && onReport != null) {
                          onReport!();
                        } else if (value == 'block' && onBlockUser != null) {
                          onBlockUser!();
                        }
                      }
                    },
                    itemBuilder: (context) => _isMyFeed
                        ? [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('수정'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ]
                        : [
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('신고'),
                            ),
                            const PopupMenuItem(
                              value: 'block',
                              child: Text('사용자 차단'),
                            ),
                          ],
                  ),
                ],
              ),
            ),
          ),
          if (feed.imageUrls.isNotEmpty)
            Container(
              width: double.infinity,
              height: 280,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: PageView.builder(
                itemCount: feed.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    feed.imageUrls[index],
                    fit: BoxFit.contain,
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
