import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed.dart';
import '../models/feed_comment.dart';
import '../services/api_service.dart';

/// 유저 생성 콘텐츠(피드/댓글)에 대한 간단한 필터·신고·차단 유틸리티.
class UGCModeration {
  static const _blockedUsersKey = 'blocked_user_ids_v1';

  /// 텍스트 검증 (빈 값/길이 + 금지어). 금지어는 [bannedWords]로 전달 (보통 settings API에서 내려준 목록).
  static String? validateText(String text, {List<String>? bannedWords}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '내용을 입력해주세요.';
    }
    if (trimmed.length < 2) {
      return '조금 더 구체적으로 작성해주세요.';
    }
    final words = bannedWords ?? [];
    if (words.isNotEmpty) {
      final lower = trimmed.toLowerCase();
      for (final word in words) {
        final w = word.trim();
        if (w.isEmpty) continue;
        if (lower.contains(w.toLowerCase())) {
          return '커뮤니티 가이드라인에 따라 부적절한 표현이 포함되어 있습니다.';
        }
      }
    }
    return null;
  }

  /// 로컬에 차단 사용자 ID 집합을 저장/로드.
  static Future<Set<String>> getBlockedUserIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_blockedUsersKey) ?? const [];
    return list.toSet();
  }

  static Future<void> addBlockedUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_blockedUsersKey) ?? const [];
    if (current.contains(userId)) return;
    await prefs.setStringList(_blockedUsersKey, [...current, userId]);
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

  /// 사용자 차단: 서버에 통지하고, 로컬에서도 즉시 차단 처리.
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
      final api = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          api.setToken(token);
        }
      }
      // 서버에도 차단 요청 (없으면 404가 날 수 있으므로 예외는 무시 가능)
      await api.blockUser(userId);
    } catch (e) {
      // 네트워크 에러가 나더라도 로컬 차단은 진행
      debugPrint('⚠️ blockUser API 실패: $e');
    }

    await addBlockedUser(userId);

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
      final api = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          api.setToken(token);
        }
      }
      await api.reportContent(
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

