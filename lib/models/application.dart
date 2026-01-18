class Application {
  final String id;
  final String meetingId;
  final String userId;
  final String? answer1; // 필수 질문 답변
  final String? answer2; // 선택 질문 답변
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;

  Application({
    required this.id,
    required this.meetingId,
    required this.userId,
    this.answer1,
    this.answer2,
    required this.status,
    required this.appliedAt,
    this.reviewedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      meetingId: json['meeting_id'],
      userId: json['user_id'],
      answer1: json['answer1'],
      answer2: json['answer2'],
      status: ApplicationStatus.fromString(json['status']),
      appliedAt: DateTime.parse(json['applied_at']),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'user_id': userId,
      'answer1': answer1,
      'answer2': answer2,
      'status': status.toString(),
      'applied_at': appliedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }
}

enum ApplicationStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static ApplicationStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'cancelled':
        return ApplicationStatus.cancelled;
      default:
        return ApplicationStatus.pending;
    }
  }
}

