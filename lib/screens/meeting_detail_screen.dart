import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_lib/share_lib_auth.dart' as share_lib;
import '../models/meeting.dart';
import '../models/user.dart' as app_models;
import '../providers/meeting_provider.dart';
import '../services/api_service.dart';
import '../utils/auth_helper.dart';
import '../theme/app_theme.dart';
import 'meeting_applications_screen.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _answerController = TextEditingController();
  Meeting? _meeting;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isApplied = false;
  bool _showApplicationForm = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMeeting();
  }

  Future<void> _loadMeeting() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }

      final meeting = await apiService.getMeeting(widget.meetingId);

      if (!mounted) return;

      setState(() {
        _meeting = meeting;
        _isLoading = false;
        // 사용자가 이미 신청했는지 확인
        if (meeting.userApplication != null) {
          _isApplied = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    debugPrint('🔵 [MeetingDetailScreen] 신청 시작');
    final questions = _meeting?.applicationQuestions ?? [];
    final hasQuestion = questions.isNotEmpty && questions[0].isNotEmpty;

    if (hasQuestion) {
      final answer = _answerController.text.trim();
      debugPrint('🔵 [MeetingDetailScreen] 답변 길이: ${answer.length}');
      if (answer.isEmpty || answer.length < 50) {
        debugPrint('❌ [MeetingDetailScreen] 답변 길이 부족');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 질문에 최소 50자 이상 작성해주세요.')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      debugPrint('🔵 [MeetingDetailScreen] MeetingProvider 가져오기');
      final meetingProvider = context.read<MeetingProvider>();
      debugPrint('🔵 [MeetingDetailScreen] AuthProvider 가져오기');
      final authProvider = context
          .read<share_lib.AuthProvider<app_models.User>>();

      if (authProvider.user == null) {
        debugPrint('❌ [MeetingDetailScreen] 사용자 정보 없음');
        throw Exception('로그인이 필요합니다');
      }

      debugPrint('✅ [MeetingDetailScreen] 사용자 ID: ${authProvider.user!.id}');
      final answer1 = hasQuestion ? _answerController.text.trim() : null;
      debugPrint('🔵 [MeetingDetailScreen] 모임 ID: ${widget.meetingId}');
      debugPrint(
        '🔵 [MeetingDetailScreen] 답변: ${answer1 != null ? "${answer1.substring(0, answer1.length > 50 ? 50 : answer1.length)}..." : "없음"}',
      );

      debugPrint('🔵 [MeetingDetailScreen] applyToMeeting 호출');
      await meetingProvider.applyToMeeting(
        widget.meetingId,
        authProvider.user!.id,
        answer1 ?? '',
        null,
      );

      debugPrint('✅ [MeetingDetailScreen] 신청 성공');
      if (!mounted) return;

      setState(() {
        _isApplied = true;
        _isSubmitting = false;
        _showApplicationForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신청이 완료되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [MeetingDetailScreen] 신청 에러 발생');
      debugPrint('❌ [MeetingDetailScreen] 에러 타입: ${e.runtimeType}');
      debugPrint('❌ [MeetingDetailScreen] 에러 메시지: $e');
      debugPrint('❌ [MeetingDetailScreen] 스택 트레이스: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신청 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모임 상세')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '모임을 불러올 수 없습니다',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadMeeting,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : _meeting == null
          ? const Center(child: Text('모임을 찾을 수 없습니다'))
          : _buildMeetingContent(_meeting!),
    );
  }

  Widget _buildMeetingContent(Meeting meeting) {
    // 현재 사용자가 호스트인지 확인
    final currentUser = FirebaseAuth.instance.currentUser;
    final isHost = currentUser != null && currentUser.uid == meeting.hostId;

    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondaryColor,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (isHost)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MeetingApplicationsScreen(
                                        meetingId: meeting.id,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.people_outline),
                            label: const Text('신청 관리'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        )
                      else ...[
                        // 질문이 있고 아직 신청 폼을 보여주지 않은 경우
                        if (!_showApplicationForm && !_isApplied)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                // 인증이 필요한지 확인
                                final isAuthenticated =
                                    await AuthHelper.requireAuth(context);
                                if (!isAuthenticated || !mounted) return;

                                final questions =
                                    meeting.applicationQuestions ?? [];
                                final hasQuestion =
                                    questions.isNotEmpty &&
                                    questions[0].isNotEmpty;

                                if (hasQuestion) {
                                  // 질문이 있으면 폼 표시
                                  setState(() {
                                    _showApplicationForm = true;
                                  });
                                } else {
                                  // 질문이 없으면 바로 신청
                                  _submitApplication();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('신청하기'),
                            ),
                          ),
                        // 신청 폼 표시
                        if (_showApplicationForm && !_isApplied) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.dividerColor,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      meeting
                                                      .applicationQuestions
                                                      ?.isNotEmpty ==
                                                  true &&
                                              meeting
                                                  .applicationQuestions![0]
                                                  .isNotEmpty
                                          ? meeting.applicationQuestions![0]
                                          : '이 주제에 관심을 갖게 된 이유는?',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '*',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _answerController,
                                  maxLines: 8,
                                  minLines: 5,
                                  decoration: InputDecoration(
                                    hintText: '답변을 작성해주세요.',
                                    helperText: '최소 50자, 권장 100자 이상 작성해주세요.',
                                    helperMaxLines: 2,
                                    counterText:
                                        '${_answerController.text.length}자 / 권장 100자',
                                    counterStyle: TextStyle(
                                      color:
                                          _answerController.text.length >= 100
                                          ? AppTheme.primaryColor
                                          : AppTheme.textTertiaryColor,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '이 답변은 호스트에게만 공유됩니다.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () {
                                                setState(() {
                                                  _showApplicationForm = false;
                                                  _answerController.clear();
                                                });
                                              },
                                        child: const Text('취소'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isSubmitting ||
                                                (_answerController.text
                                                        .trim()
                                                        .length <
                                                    50)
                                            ? null
                                            : _submitApplication,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text('신청하기'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        // 신청 완료 상태
                        if (_isApplied)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.dividerColor,
                                foregroundColor: AppTheme.textTertiaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('신청완료'),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
