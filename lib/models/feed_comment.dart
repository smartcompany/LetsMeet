class FeedComment {
  final String id;
  final String feedId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedComment({
    required this.id,
    required this.feedId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'],
      feedId: json['feed_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '알 수 없음',
      userProfileImage: json['user_profile_image'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
