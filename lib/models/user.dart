class User {
  final String id;
  final String phoneNumber;
  final String nickname;
  final String? profileImageUrl;
  final int trustScore;
  final TrustLevel trustLevel;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  User({
    required this.id,
    required this.phoneNumber,
    required this.nickname,
    this.profileImageUrl,
    required this.trustScore,
    required this.trustLevel,
    required this.interests,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'],
      nickname: json['nickname'],
      profileImageUrl: json['profile_image_url'],
      trustScore: json['trust_score'],
      trustLevel: TrustLevel.fromString(json['trust_level']),
      interests: List<String>.from(json['interests'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'nickname': nickname,
      'profile_image_url': profileImageUrl,
      'trust_score': trustScore,
      'trust_level': trustLevel.toString(),
      'interests': interests,
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

