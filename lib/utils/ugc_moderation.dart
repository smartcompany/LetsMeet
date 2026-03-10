import 'package:flutter/material.dart';

import '../models/feed.dart';
import '../models/feed_comment.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';
import '../app_auth_provider.dart';

/// 유저 생성 콘텐츠(피드/댓글)에 대한 간단한 필터·신고·차단 유틸리티.
/// 차단 목록은 서버(DB)에 저장되며, GET /users/me/blocked-ids 로 조회합니다.
class UGCModeration {

  /// 텍스트 검증 (빈 값·최소 길이만). 금칙어 검사는 서버에서만 함.
  static String? validateText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '내용을 입력해주세요.';
    }
    if (trimmed.length < 2) {
      return '조금 더 구체적으로 작성해주세요.';
    }
    return null;
  }

  /// 서버(DB)에서 차단한 사용자 ID 목록 조회. 비로그인 시 빈 집합.
  static Future<Set<String>> getBlockedUserIds() async {
    if (!AppAuthProvider.shared.isLoggedIn()) return {};
    try {
      final list = await ApiService.shared.getBlockedUserIds();
      return list.toSet();
    } catch (e) {
      debugPrint('getBlockedUserIds: $e');
      return {};
    }
  }

  /// 피드 신고 UI + API 호출.
  static Future<void> reportFeed(BuildContext context, Feed feed) async {
    await _showReportSheet(
      context: context,
      targetType: 'feed',
      targetId: feed.id,
      targetUserId: feed.authorId,
    );
  }

  /// 댓글 신고 UI + API 호출.
  static Future<void> reportComment(
    BuildContext context,
    FeedComment comment,
    String feedId,
  ) async {
    await _showReportSheet(
      context: context,
      targetType: 'comment',
      targetId: comment.id,
      targetUserId: comment.userId,
      extra: {'feed_id': feedId},
    );
  }

  /// 모임 신고 UI + API 호출.
  static Future<void> reportMeeting(BuildContext context, Meeting meeting) async {
    await _showReportSheet(
      context: context,
      targetType: 'meeting',
      targetId: meeting.id,
      targetUserId: meeting.hostId,
    );
  }

  /// 사용자 차단: 서버(DB)에 저장. 이후 피드/댓글/모임 목록 API에서 해당 사용자 제외됨.
  static Future<void> blockUser(
    BuildContext context, {
    required String userId,
    required String userName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사용자 차단'),
        content: Text(
          '"$userName" 님을 차단하시겠습니까?\n\n'
          '차단하면 이 사용자의 피드와 댓글이 더 이상 표시되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('차단'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.shared.blockUser(userId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('차단 처리에 실패했습니다: $e')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$userName" 님을 차단했습니다.')),
      );
    }
  }

  /// 공통 신고 바텀시트.
  static Future<void> _showReportSheet({
    required BuildContext context,
    required String targetType,
    required String targetId,
    required String targetUserId,
    Map<String, dynamic>? extra,
  }) async {
    String? selectedReason;
    final controller = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '신고하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('신고 사유를 선택해주세요.'),
                      const SizedBox(height: 8),
                      ...[
                        '스팸/광고',
                        '욕설/비방/혐오 표현',
                        '성적/음란한 내용',
                        '폭력/위협',
                        '기타',
                      ].map(
                        (reason) => RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (value) {
                            setState(() => selectedReason = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: '자세한 내용을 적어주세요. (선택)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedReason == null
                              ? null
                              : () => Navigator.of(ctx).pop(true),
                          child: const Text('신고 보내기'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (result != true || selectedReason == null) return;

    try {
      await ApiService.shared.reportContent(
        targetType: targetType,
        targetId: targetId,
        targetUserId: targetUserId,
        reason: selectedReason!,
        detail: controller.text.trim().isEmpty ? null : controller.text.trim(),
        extra: extra,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다. 감사합니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('신고 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}

