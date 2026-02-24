import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/meeting_card.dart';
import 'meeting_detail_screen.dart';

/// 참여한 모임 목록 (승인되어 참가한 모임, 호스트 제외)
class ParticipatedMeetingsScreen extends StatefulWidget {
  const ParticipatedMeetingsScreen({super.key});

  @override
  State<ParticipatedMeetingsScreen> createState() =>
      _ParticipatedMeetingsScreenState();
}

class _ParticipatedMeetingsScreenState extends State<ParticipatedMeetingsScreen> {
  bool _isLoading = true;
  List<Meeting> _meetings = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) _apiService.setToken(token);

      final all = await _apiService.getMeetings(applicantId: uid);
      final participated = all.where((m) {
        final status = m.userApplication?['status']?.toString();
        return status == 'approved' && m.hostId != uid;
      }).toList();

      if (mounted) {
        setState(() {
          _meetings = participated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모임 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  List<Meeting> _getUpcoming() {
    return _meetings
        .where((m) =>
            (m.status == MeetingStatus.open || m.status == MeetingStatus.closed) &&
            m.meetingDate.isAfter(DateTime.now()))
        .toList();
  }

  List<Meeting> _getCompleted() {
    return _meetings
        .where((m) =>
            m.status == MeetingStatus.completed ||
            m.meetingDate.isBefore(DateTime.now()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _getUpcoming();
    final completed = _getCompleted();

    return Scaffold(
      appBar: AppBar(
        title: const Text('참여한 모임'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meetings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 64,
                        color: AppTheme.textTertiaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '참여한 모임이 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '예정',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        ...upcoming.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: MeetingCard(
                              meeting: m,
                              showStatusBadge: true,
                              showHostCreatedBadge: false,
                              onTap: () => _openDetail(m),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (completed.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Text(
                            '참여 완료',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        ...completed.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: MeetingCard(
                              meeting: m,
                              showStatusBadge: true,
                              showHostCreatedBadge: false,
                              onTap: () => _openDetail(m),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  void _openDetail(Meeting meeting) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailScreen(meetingId: meeting.id),
      ),
    );
    if (result == true && mounted) _load();
  }
}
