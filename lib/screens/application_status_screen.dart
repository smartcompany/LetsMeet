import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../models/application.dart';
import '../providers/meeting_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ApplicationStatusScreen extends StatelessWidget {
  final String meetingId;
  final ApplicationStatus status;

  const ApplicationStatusScreen({
    super.key,
    required this.meetingId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신청 상태'),
      ),
      body: Consumer2<MeetingProvider, AuthProvider>(
        builder: (context, meetingProvider, authProvider, child) {
          final meeting = meetingProvider.getMeetingById(meetingId);
          
          if (meeting == null) {
            return const Center(child: Text('모임을 찾을 수 없습니다'));
          }

          if (authProvider.user == null) {
            return const Center(child: Text('로그인이 필요합니다'));
          }

          final application = meetingProvider.getApplicationByMeetingId(
            meetingId,
            authProvider.user!.id,
          );

          final currentStatus = application?.status ?? status;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 모임 정보 카드
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meeting.shortDescription ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 상태별 UI
                if (currentStatus == ApplicationStatus.pending) ...[
                  _PendingStatus(),
                ] else if (currentStatus == ApplicationStatus.approved) ...[
                  _ApprovedStatus(meeting: meeting),
                ] else if (currentStatus == ApplicationStatus.rejected) ...[
                  _RejectedStatus(),
                ],

                const SizedBox(height: 24),

                // 홈으로 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('홈으로'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.hourglass_empty,
          size: 64,
          color: AppTheme.textTertiaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          '승인 대기 중',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        Text(
          '호스트가 신청을 검토 중입니다.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '관련 주제 모임 추천',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '다른 유사한 모임도 둘러보세요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApprovedStatus extends StatelessWidget {
  final Meeting meeting;

  const _ApprovedStatus({
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          '승인 완료',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '일정 요약',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: '날짜',
                  value: meeting.meetingDate.toString().split(' ')[0],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: '장소',
                  value: meeting.format == MeetingFormat.online
                      ? (meeting.meetingLink ?? '온라인')
                      : (meeting.locationDetail ?? meeting.location),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개인 메모',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '참여 전 생각을 정리해보세요. (비공개)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RejectedStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.cancel_outlined,
          size: 64,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          '신청이 거절되었습니다',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '이번 모임의 방향과는 맞지 않았어요.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
