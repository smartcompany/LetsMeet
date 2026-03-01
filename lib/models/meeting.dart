class Meeting {
  final String id;
  final String hostId;
  final String hostName;
  final String? hostProfileImageUrl;
  final String title;
  final String? description;
  final String? shortDescription; // 한 줄 설명
  final String? hostNote; // 호스트 한 마디
  final DateTime meetingDate;
  final String location;
  final String? locationDetail;
  final String? meetingLink; // 온라인 모임 링크
  final List<String>? imageUrls; // 모임 사진 URL 목록
  final int maxParticipants;
  final List<String> interests;
  final String? category;
  final int? participationFee;
  final GenderRestriction? genderRestriction;
  final int? ageRangeMin;
  final int? ageRangeMax;
  final ApprovalType? approvalType;
  final MeetingFormat format; // 온라인/오프라인
  final List<String>? topicsCovered; // 다루는 이야기
  final List<String>? topicsNotCovered; // 다루지 않는 이야기
  final String? conversationFlow; // 대화 흐름 요약
  final List<String>? applicationQuestions; // 참여 전 질문
  final MeetingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? userApplication; // 현재 사용자의 신청 정보
  final List<MeetingParticipant>? participants; // 참가자 목록 (호스트 + 승인된 신청자)
  final int? participantCount; // 현재 참가자 수 (목록 API에서 사용, 상세는 participants.length)

  Meeting({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostProfileImageUrl,
    required this.title,
    this.description,
    this.shortDescription,
    this.hostNote,
    required this.meetingDate,
    required this.location,
    this.locationDetail,
    this.meetingLink,
    this.imageUrls,
    required this.maxParticipants,
    required this.interests,
    this.category,
    this.participationFee,
    this.genderRestriction,
    this.ageRangeMin,
    this.ageRangeMax,
    this.approvalType,
    required this.format,
    this.topicsCovered,
    this.topicsNotCovered,
    this.conversationFlow,
    this.applicationQuestions,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userApplication,
    this.participants,
    this.participantCount,
  });

  int get currentParticipantCount =>
      participantCount ?? participants?.length ?? 0;

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      hostId: json['host_id'],
      hostName: json['host_name'] ?? '',
      hostProfileImageUrl: json['host_profile_image_url'] as String?,
      title: json['title'],
      description: json['description'],
      shortDescription: json['short_description'],
      hostNote: json['host_note'],
      meetingDate: DateTime.parse(json['meeting_date']),
      location: json['location'],
      locationDetail: json['location_detail'],
      meetingLink: json['meeting_link'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      maxParticipants: json['max_participants'],
      interests: List<String>.from(json['interests'] ?? []),
      category: json['category'],
      participationFee: json['participation_fee'],
      genderRestriction: json['gender_restriction'] != null
          ? GenderRestriction.fromString(json['gender_restriction'])
          : null,
      ageRangeMin: json['age_range_min'],
      ageRangeMax: json['age_range_max'],
      approvalType: json['approval_type'] != null
          ? ApprovalType.fromString(json['approval_type'])
          : null,
      format: MeetingFormat.fromString(json['format'] ?? 'offline'),
      topicsCovered: json['topics_covered'] != null
          ? List<String>.from(json['topics_covered'])
          : null,
      topicsNotCovered: json['topics_not_covered'] != null
          ? List<String>.from(json['topics_not_covered'])
          : null,
      conversationFlow: json['conversation_flow'],
      applicationQuestions: json['application_questions'] != null
          ? List<String>.from(json['application_questions'])
          : null,
      status: MeetingStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userApplication: json['user_application'] != null
          ? Map<String, dynamic>.from(json['user_application'])
          : null,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((e) => MeetingParticipant.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : null,
      participantCount: json['participant_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'host_name': hostName,
      'title': title,
      'description': description,
      'short_description': shortDescription,
      'host_note': hostNote,
      'meeting_date': meetingDate.toIso8601String(),
      'location': location,
      'location_detail': locationDetail,
      'meeting_link': meetingLink,
      'image_urls': imageUrls,
      'max_participants': maxParticipants,
      'interests': interests,
      'category': category,
      'participation_fee': participationFee,
      'gender_restriction': genderRestriction?.toString(),
      'age_range_min': ageRangeMin,
      'age_range_max': ageRangeMax,
      'approval_type': approvalType?.toString(),
      'format': format.toString(),
      'topics_covered': topicsCovered,
      'topics_not_covered': topicsNotCovered,
      'conversation_flow': conversationFlow,
      'application_questions': applicationQuestions,
      'status': status.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MeetingParticipant {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final String? bio;

  MeetingParticipant({
    required this.userId,
    required this.fullName,
    this.profileImageUrl,
    this.bio,
  });

  factory MeetingParticipant.fromJson(Map<String, dynamic> json) {
    return MeetingParticipant(
      userId: json['user_id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}

enum MeetingFormat {
  online,
  offline,
  hybrid;

  static MeetingFormat fromString(String value) {
    switch (value) {
      case 'online':
        return MeetingFormat.online;
      case 'offline':
        return MeetingFormat.offline;
      case 'hybrid':
        return MeetingFormat.hybrid;
      default:
        return MeetingFormat.offline;
    }
  }
}

enum MeetingStatus {
  open,
  closed,
  completed,
  cancelled,
  suspended,
  underReview;

  static MeetingStatus fromString(String value) {
    switch (value) {
      case 'open':
        return MeetingStatus.open;
      case 'closed':
        return MeetingStatus.closed;
      case 'completed':
        return MeetingStatus.completed;
      case 'cancelled':
        return MeetingStatus.cancelled;
      case 'suspended':
        return MeetingStatus.suspended;
      case 'under_review':
        return MeetingStatus.underReview;
      default:
        return MeetingStatus.open;
    }
  }

  @override
  String toString() {
    switch (this) {
      case MeetingStatus.open:
        return 'open';
      case MeetingStatus.closed:
        return 'closed';
      case MeetingStatus.completed:
        return 'completed';
      case MeetingStatus.cancelled:
        return 'cancelled';
      case MeetingStatus.suspended:
        return 'suspended';
      case MeetingStatus.underReview:
        return 'under_review';
    }
  }
}

enum GenderRestriction {
  all,
  male,
  female;

  static GenderRestriction fromString(String value) {
    switch (value) {
      case 'all':
        return GenderRestriction.all;
      case 'male':
        return GenderRestriction.male;
      case 'female':
        return GenderRestriction.female;
      default:
        return GenderRestriction.all;
    }
  }

  @override
  String toString() {
    switch (this) {
      case GenderRestriction.all:
        return 'all';
      case GenderRestriction.male:
        return 'male';
      case GenderRestriction.female:
        return 'female';
    }
  }
}

enum ApprovalType {
  immediate,
  approvalRequired;

  static ApprovalType fromString(String value) {
    switch (value) {
      case 'immediate':
        return ApprovalType.immediate;
      case 'approval_required':
        return ApprovalType.approvalRequired;
      default:
        return ApprovalType.immediate;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ApprovalType.immediate:
        return 'immediate';
      case ApprovalType.approvalRequired:
        return 'approval_required';
    }
  }
}
