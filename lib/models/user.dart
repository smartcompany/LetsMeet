class User {
  final String id;
  final String? phoneNumber; // nullable for social login users
  final String nickname;
  final String? profileImageUrl;
  final String? fullName;
  final String? gender; // 'male' or 'female'
  final String? bio;
  final String? backgroundImageUrl;
  final int trustScore;
  final TrustLevel trustLevel;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  User({
    required this.id,
    this.phoneNumber,
    required this.nickname,
    this.profileImageUrl,
    this.fullName,
    this.gender,
    this.bio,
    this.backgroundImageUrl,
    required this.trustScore,
    required this.trustLevel,
    required this.interests,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final trustScore = json['trust_score'] as int;
    return User(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String?,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      backgroundImageUrl: json['background_image_url'] as String?,
      trustScore: trustScore,
      trustLevel: _calculateTrustLevel(trustScore),
      interests: List<String>.from(json['interests'] ?? []),
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
      'nickname': nickname,
      'profile_image_url': profileImageUrl,
      'full_name': fullName,
      'gender': gender,
      'bio': bio,
      'background_image_url': backgroundImageUrl,
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
