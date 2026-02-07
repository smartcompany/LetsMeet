class User {
  final String id;
  final String? phoneNumber; // nullable for social login users
  final String fullName;
  final String? profileImageUrl;
  final String? gender; // 'male' or 'female'
  final String? bio;
  final String? backgroundImageUrl;
  final int trustScore;
  final TrustLevel trustLevel;
  final String? lifeSceneId;
  final String? selfStatementId;
  final String? interactionStyleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  User({
    required this.id,
    this.phoneNumber,
    required this.fullName,
    this.profileImageUrl,
    this.gender,
    this.bio,
    this.backgroundImageUrl,
    required this.trustScore,
    required this.trustLevel,
    this.lifeSceneId,
    this.selfStatementId,
    this.interactionStyleId,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final trustScore = (json['trust_score'] is int)
        ? json['trust_score'] as int
        : int.tryParse(json['trust_score']?.toString() ?? '70') ?? 70;
    return User(
      id: (json['id'] ?? json['user_id']) as String,
      phoneNumber: json['phone_number'] as String?,
      fullName: (json['full_name'] as String?) ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      backgroundImageUrl: json['background_image_url'] as String?,
      trustScore: trustScore,
      trustLevel: _calculateTrustLevel(trustScore),
      lifeSceneId: json['life_scene_id'] as String?,
      selfStatementId: json['self_statement_id'] as String?,
      interactionStyleId: json['interaction_style_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool,
    );
  }

  static TrustLevel _calculateTrustLevel(int trustScore) {
    if (trustScore >= 90) {
      return TrustLevel.trust;
    } else if (trustScore >= 70) {
      return TrustLevel.stable;
    } else if (trustScore >= 50) {
      return TrustLevel.caution;
    } else {
      return TrustLevel.restricted;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
      'gender': gender,
      'bio': bio,
      'background_image_url': backgroundImageUrl,
      'trust_score': trustScore,
      'trust_level': trustLevel.toString(),
      'life_scene_id': lifeSceneId,
      'self_statement_id': selfStatementId,
      'interaction_style_id': interactionStyleId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

enum TrustLevel {
  trust,
  stable,
  caution,
  restricted;

  static TrustLevel fromString(String value) {
    switch (value) {
      case 'trust':
        return TrustLevel.trust;
      case 'stable':
        return TrustLevel.stable;
      case 'caution':
        return TrustLevel.caution;
      case 'restricted':
        return TrustLevel.restricted;
      default:
        return TrustLevel.stable;
    }
  }

  String get displayName {
    switch (this) {
      case TrustLevel.trust:
        return '신뢰';
      case TrustLevel.stable:
        return '안정';
      case TrustLevel.caution:
        return '주의';
      case TrustLevel.restricted:
        return '제한';
    }
  }
}
