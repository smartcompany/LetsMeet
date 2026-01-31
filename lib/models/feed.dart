class Feed {
  final String id;
  final String authorId;
  final String authorNickname;
  final String? authorProfileImage;
  final String content;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final bool isLiked; // 현재 사용자가 좋아요를 눌렀는지 여부
  final DateTime createdAt;
  final DateTime updatedAt;

  Feed({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    this.authorProfileImage,
    required this.content,
    required this.imageUrls,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      id: json['id'],
      authorId: json['author_id'],
      authorNickname: json['author_nickname'] ?? '알 수 없음',
      authorProfileImage: json['author_profile_image'],
      content: json['content'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'content': content,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
