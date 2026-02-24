import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MeetingEvaluationScreen extends StatefulWidget {
  final Meeting meeting;
  final VoidCallback? onSubmitted;

  const MeetingEvaluationScreen({
    super.key,
    required this.meeting,
    this.onSubmitted,
  });

  @override
  State<MeetingEvaluationScreen> createState() => _MeetingEvaluationScreenState();
}

class _MeetingEvaluationScreenState extends State<MeetingEvaluationScreen> {
  final ApiService _apiService = ApiService();
  int? _meetingRating;
  final Map<String, int> _participantScores = {};
  bool _isSubmitting = false;

  List<MeetingParticipant> get _rateableParticipants {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final fromList = (widget.meeting.participants ?? [])
        .where((p) => p.userId != uid)
        .toList();
    // 호스트가 participants에 없을 수 있으므로 포함
    final hasHost = fromList.any((p) => p.userId == widget.meeting.hostId);
    if (!hasHost && widget.meeting.hostId != uid) {
      return [
        MeetingParticipant(
          userId: widget.meeting.hostId,
          fullName: widget.meeting.hostName,
          profileImageUrl: widget.meeting.hostProfileImageUrl,
        ),
        ...fromList,
      ];
    }
    return fromList;
  }

  @override
  void initState() {
    super.initState();
    _initToken();
  }

  Future<void> _initToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) _apiService.setToken(token);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    debugPrint('🔵 [MeetingEvaluationScreen] 제출: meetingId=${widget.meeting.id}, status=${widget.meeting.status}');
    try {
      await _apiService.submitMeetingEvaluation(
        widget.meeting.id,
        meetingRating: _meetingRating,
        participantScores:
            _participantScores.isEmpty ? null : Map.from(_participantScores),
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('평가가 저장되었습니다.')),
      );
    } catch (e, stack) {
      debugPrint('❌ [MeetingEvaluationScreen] 저장 실패: $e');
      debugPrint('❌ [MeetingEvaluationScreen] stack: $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _isSubmitting = true);
    try {
      await _apiService.submitMeetingEvaluation(widget.meeting.id);
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rateables = _rateableParticipants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 평가'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => _skip(),
            child: const Text('평가 안함'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.meeting.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '참여해 주셔서 감사합니다. 평가는 선택 사항입니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('모임은 어떠셨나요? (선택)'),
            _buildStarRow(
              value: _meetingRating,
              onChanged: (v) => setState(() => _meetingRating = v),
            ),
            const SizedBox(height: 24),

            if (rateables.isNotEmpty) ...[
              _buildSectionTitle('참가자 평가 (선택)'),
              const SizedBox(height: 12),
              ...rateables.map((p) => _buildParticipantRow(p)),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('제출하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStarRow({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        final selected = value != null && value >= star;
        return IconButton(
          onPressed: () => onChanged(value == star ? null : star),
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
            color: selected ? Colors.amber : AppTheme.textTertiaryColor,
            size: 36,
          ),
        );
      }),
    );
  }

  Widget _buildParticipantRow(MeetingParticipant p) {
    final score = _participantScores[p.userId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: p.profileImageUrl != null && p.profileImageUrl!.isNotEmpty
                ? NetworkImage(p.profileImageUrl!)
                : null,
            child: p.profileImageUrl == null || p.profileImageUrl!.isEmpty
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              p.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              final selected = score != null && score >= star;
              return IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  setState(() {
                    if (score == star) {
                      _participantScores.remove(p.userId);
                    } else {
                      _participantScores[p.userId] = star;
                    }
                  });
                },
                icon: Icon(
                  selected ? Icons.star : Icons.star_border,
                  color: selected ? Colors.amber : AppTheme.textTertiaryColor,
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
