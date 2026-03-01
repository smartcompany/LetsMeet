import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/meeting_card.dart';
import 'meeting_detail_screen.dart';
import 'meeting_applications_screen.dart';

class MyMeetingsScreen extends StatefulWidget {
  const MyMeetingsScreen({super.key});

  @override
  State<MyMeetingsScreen> createState() => _MyMeetingsScreenState();
}

class _MyMeetingsScreenState extends State<MyMeetingsScreen> {
  bool _isLoading = true;
  List<Meeting> _myMeetings = []; // 내가 만든 모임
  Map<String, int> _pendingCounts = {};
  final ApiService _apiService = ApiService();

  Future<void> _loadPendingCounts() async {
    try {
      final counts = await _apiService.getPendingApplicationCounts();
      if (mounted) setState(() => _pendingCounts = counts);
    } catch (_) {}
  }

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
          _loadPendingCounts();
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

  List<Meeting> _getSuspendedOrUnderReviewMeetings() {
    return _myMeetings
        .where(
          (meeting) =>
              meeting.status == MeetingStatus.suspended ||
              meeting.status == MeetingStatus.underReview,
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

  void _openApplications(String meetingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingApplicationsScreen(meetingId: meetingId),
      ),
    ).then((_) => _loadPendingCounts());
  }

  Widget _buildManageApplicationsButton(String meetingId) {
    final pending = _pendingCounts[meetingId];
    final label = pending != null && pending > 0 ? '신청 관리 ($pending)' : '신청 관리';
    return OutlinedButton.icon(
      onPressed: () => _openApplications(meetingId),
      icon: const Icon(Icons.people_outline, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        side: const BorderSide(color: AppTheme.primaryColor),
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMeetings = _getActiveMeetings();
    final suspendedOrUnderReview = _getSuspendedOrUnderReviewMeetings();
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
                        '만든 모임이 없습니다.',
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
                      // 내가 만든 모임
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MeetingCard(
                                  meeting: meeting,
                                  showStatusBadge: false,
                                  showHostCreatedBadge: false,
                                  trailingAction: _buildManageApplicationsButton(
                                    meeting.id,
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MeetingDetailScreen(
                                                meetingId: meeting.id),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadMyMeetings();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // 정지/검토 중
                      if (suspendedOrUnderReview.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Text(
                            '정지/검토 중',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                        ...suspendedOrUnderReview.map(
                          (meeting) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MeetingCard(
                                  meeting: meeting,
                                  showStatusBadge: true,
                                  showHostCreatedBadge: false,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MeetingDetailScreen(
                                                meetingId: meeting.id),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadMyMeetings();
                                    }
                                  },
                                ),
                              ],
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MeetingCard(
                                  meeting: meeting,
                                  showStatusBadge: false,
                                  showHostCreatedBadge: false,
                                  trailingAction: _buildManageApplicationsButton(
                                    meeting.id,
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MeetingDetailScreen(
                                                meetingId: meeting.id),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadMyMeetings();
                                    }
                                  },
                                ),
                              ],
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
