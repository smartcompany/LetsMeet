import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../providers/meeting_provider.dart';
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
      final meetingProvider = context.read<MeetingProvider>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 모든 모임을 불러온 후 내가 호스트인 것만 필터링
        // (추후 API에서 내가 만든 모임만 가져오는 기능이 추가되면 최적화 가능)
        await meetingProvider.loadMeetings();
        final allMeetings = meetingProvider.meetings;

        setState(() {
          _myMeetings = allMeetings
              .where((m) => m.hostId == currentUser.uid)
              .toList();
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myMeetings.length,
                itemBuilder: (context, index) {
                  final meeting = _myMeetings[index];
                  return Padding(
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
                  );
                },
              ),
            ),
    );
  }
}
