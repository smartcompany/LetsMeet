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

  const FeedCard({
    super.key,
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
                ],
              ),
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
