import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/meeting_card.dart';
import 'meeting_detail_screen.dart';

class MyMeetingsScreen extends StatefulWidget {
  const MyMeetingsScreen({super.key});

  @override
  State<MyMeetingsScreen> createState() => _MyMeetingsScreenState();
}

class _MyMeetingsScreenState extends State<MyMeetingsScreen> {
  bool _isLoading = true;
  List<Meeting> _myMeetings = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyMeetings();
    });
  }

  Future<void> _loadMyMeetings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 인증 토큰 설정
        final token = await currentUser.getIdToken();
        if (token != null) {
          _apiService.setToken(token);
        }

        // 내가 호스트인 모든 모임 조회 (완료된 모임 포함)
        final myMeetings = await _apiService.getMeetings(
          hostId: currentUser.uid,
          includeCompleted: true,
        );

        if (mounted) {
          setState(() {
            _myMeetings = myMeetings;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('모임을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  List<Meeting> _getActiveMeetings() {
    return _myMeetings
        .where(
          (meeting) =>
              meeting.status == MeetingStatus.open ||
              meeting.status == MeetingStatus.closed,
        )
        .toList();
  }

  List<Meeting> _getCompletedMeetings() {
    return _myMeetings
        .where(
          (meeting) =>
              meeting.status == MeetingStatus.completed ||
              meeting.status == MeetingStatus.cancelled,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeMeetings = _getActiveMeetings();
    final completedMeetings = _getCompletedMeetings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 만든 모임'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myMeetings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 64,
                    color: AppTheme.textTertiaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 만든 모임이 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMyMeetings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 진행 중인 모임
                  if (activeMeetings.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '진행중',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    ...activeMeetings.map(
                      (meeting) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MeetingCard(
                          meeting: meeting,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MeetingDetailScreen(meetingId: meeting.id),
                              ),
                            );
                            if (result == true) {
                              _loadMyMeetings();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // 완료된 모임
                  if (completedMeetings.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 8),
                      child: Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    ...completedMeetings.map(
                      (meeting) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MeetingCard(
                          meeting: meeting,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MeetingDetailScreen(meetingId: meeting.id),
                              ),
                            );
                            if (result == true) {
                              _loadMyMeetings();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
