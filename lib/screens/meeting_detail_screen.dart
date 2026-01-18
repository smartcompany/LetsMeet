import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../providers/meeting_provider.dart';
import '../utils/auth_helper.dart';
import '../theme/app_theme.dart';
import 'meeting_application_screen.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrollAtBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 50.0; // 하단에서 50px 이내면 활성화

    final isAtBottom = currentScroll >= (maxScroll - threshold);

    if (isAtBottom != _isScrollAtBottom) {
      setState(() {
        _isScrollAtBottom = isAtBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모임 상세')),
      body: Consumer<MeetingProvider>(
        builder: (context, meetingProvider, child) {
          final meeting = meetingProvider.getMeetingById(widget.meetingId);

          if (meeting == null) {
            return const Center(child: Text('모임을 찾을 수 없습니다'));
          }

          return Stack(
            children: [
              // 스크롤 가능한 콘텐츠
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 모임 주제
                    Text(
                      meeting.title,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 24),

                    // 2. 호스트 한 마디
                    if (meeting.hostNote != null) ...[
                      _Section(
                        title: '호스트 한 마디',
                        child: Text(
                          meeting.hostNote!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 3. 모임 설명
                    if (meeting.description != null) ...[
                      _Section(
                        title: '모임 설명',
                        child: Text(
                          meeting.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 4. 다루는 이야기
                    if (meeting.topicsCovered != null &&
                        meeting.topicsCovered!.isNotEmpty) ...[
                      _Section(
                        title: '다루는 이야기',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: meeting.topicsCovered!
                              .map(
                                (topic) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      Expanded(
                                        child: Text(
                                          topic,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 5. 다루지 않는 이야기
                    if (meeting.topicsNotCovered != null &&
                        meeting.topicsNotCovered!.isNotEmpty) ...[
                      _Section(
                        title: '다루지 않는 이야기',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: meeting.topicsNotCovered!
                              .map(
                                (topic) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  AppTheme.textSecondaryColor,
                                            ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          topic,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 6. 진행 방식
                    _Section(
                      title: '진행 방식',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: '인원',
                            value: '${meeting.maxParticipants}명',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: '시간',
                            value: DateFormat(
                              'M월 d일 (E) HH:mm',
                              'ko_KR',
                            ).format(meeting.meetingDate),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: '장소',
                            value: meeting.format == MeetingFormat.online
                                ? (meeting.meetingLink ?? '온라인')
                                : (meeting.locationDetail ?? meeting.location),
                          ),
                          if (meeting.format == MeetingFormat.online &&
                              meeting.meetingLink != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              meeting.meetingLink!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.primaryColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 7. 대화 흐름 요약
                    if (meeting.conversationFlow != null) ...[
                      _Section(
                        title: '대화 흐름 요약',
                        child: Text(
                          meeting.conversationFlow!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 8. 참여 전 질문 (미리보기)
                    if (meeting.applicationQuestions != null &&
                        meeting.applicationQuestions!.isNotEmpty) ...[
                      _Section(
                        title: '참여 전 질문',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: meeting.applicationQuestions!
                              .asMap()
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 하단 여백 (버튼이 가리지 않도록)
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // 하단 고정 버튼
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isScrollAtBottom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '아래로 스크롤하여 신청하기',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        if (!_isScrollAtBottom) const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isScrollAtBottom
                                ? () async {
                                    // 인증이 필요한지 확인
                                    final isAuthenticated =
                                        await AuthHelper.requireAuth(context);
                                    if (!isAuthenticated || !mounted) return;

                                    // 인증 완료 후 모임 신청 화면으로 이동
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MeetingApplicationScreen(
                                              meetingId: meeting.id,
                                            ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isScrollAtBottom
                                  ? AppTheme.primaryColor
                                  : AppTheme.dividerColor,
                              foregroundColor: _isScrollAtBottom
                                  ? Colors.white
                                  : AppTheme.textTertiaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('신청하기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

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
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
