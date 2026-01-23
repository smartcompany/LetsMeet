import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_lib/share_lib_auth.dart' as share_lib;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../models/application.dart';
import '../models/user.dart' as app_models;
import '../providers/meeting_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'application_status_screen.dart';

class MeetingApplicationScreen extends StatefulWidget {
  final String meetingId;

  const MeetingApplicationScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<MeetingApplicationScreen> createState() =>
      _MeetingApplicationScreenState();
}

class _MeetingApplicationScreenState extends State<MeetingApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isAnswer1Pasted = false;
  bool _isAnswer2Pasted = false;
  bool _isSubmitting = false;
  Meeting? _meeting;
  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // 복사 감지를 위한 리스너
    _answer1Controller.addListener(_checkPaste);
    _answer2Controller.addListener(_checkPaste);
    _loadMeeting();
  }

  Future<void> _loadMeeting() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          _apiService.setToken(token);
        }
      }

      final meeting = await _apiService.getMeeting(widget.meetingId);

      if (!mounted) return;

      setState(() {
        _meeting = meeting;
        _isLoading = false;
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
    _answer1Controller.removeListener(_checkPaste);
    _answer2Controller.removeListener(_checkPaste);
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkPaste() {
    // 클립보드에서 텍스트를 가져와서 비교
    Clipboard.getData(Clipboard.kTextPlain).then((clipboardData) {
      if (clipboardData?.text != null) {
        final clipboardText = clipboardData!.text!;
        final answer1Text = _answer1Controller.text;
        final answer2Text = _answer2Controller.text;
        
        // 붙여넣기 감지 (클립보드 내용이 텍스트에 포함되어 있고 길이가 일치)
        if (answer1Text.contains(clipboardText) &&
            answer1Text.length >= clipboardText.length &&
            clipboardText.length > 10) {
          if (!_isAnswer1Pasted) {
            setState(() {
              _isAnswer1Pasted = true;
            });
          }
        }
        
        if (answer2Text.contains(clipboardText) &&
            answer2Text.length >= clipboardText.length &&
            clipboardText.length > 10) {
          if (!_isAnswer2Pasted) {
            setState(() {
              _isAnswer2Pasted = true;
            });
          }
        }
      }
    });
  }

  bool _isValid() {
    final questions = _meeting?.applicationQuestions ?? [];
    // 질문이 없으면 항상 유효 (답변 불필요)
    if (questions.isEmpty || questions[0].isEmpty) {
      return true;
    }
    // 질문이 있으면 최소 50자 이상 입력 필요
    final answer1 = _answer1Controller.text.trim();
    return answer1.isNotEmpty && answer1.length >= 50;
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 질문에 최소 50자 이상 작성해주세요.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final meetingProvider = context.read<MeetingProvider>();
      final authProvider = context.read<share_lib.AuthProvider<app_models.User>>();
      
      if (authProvider.user == null) {
        throw Exception('로그인이 필요합니다');
      }

      final questions = _meeting?.applicationQuestions ?? [];
      final answer1 = questions.isNotEmpty && questions[0].isNotEmpty
          ? _answer1Controller.text.trim()
          : null;

      await meetingProvider.applyToMeeting(
        widget.meetingId,
        authProvider.user!.id,
        answer1 ?? '',
        null, // 질문 2는 제거
      );

      if (!mounted) return;

      // 신청 완료 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ApplicationStatusScreen(
            meetingId: widget.meetingId,
            status: ApplicationStatus.pending,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신청 중 오류가 발생했습니다: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('모임 신청')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _meeting == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('모임 신청')),
        body: Center(
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
              if (_errorMessage != null)
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
        ),
      );
    }

    final dateFormat = DateFormat('M월 d일 (E) HH:mm', 'ko_KR');
    final questions = _meeting!.applicationQuestions ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 신청'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 모임 요약 카드
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _meeting!.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormat.format(_meeting!.meetingDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                ),
                              ],
                            ),
                            if (_meeting!.locationDetail != null ||
                                _meeting!.location.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _meeting!.format == MeetingFormat.online
                                        ? Icons.videocam_outlined
                                        : Icons.location_on_outlined,
                                    size: 16,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _meeting!.format == MeetingFormat.online
                                          ? (_meeting!.meetingLink ?? '온라인')
                                          : (_meeting!.locationDetail ??
                                              _meeting!.location),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 질문이 있는 경우에만 답변 입력 필드 표시
                    if (questions.isNotEmpty && questions[0].isNotEmpty) ...[
                      _QuestionField(
                        label: questions[0],
                        required: true,
                        controller: _answer1Controller,
                        minLength: 50,
                        recommendedLength: 100,
                        isPasted: _isAnswer1Pasted,
                        onPasteWarningDismiss: () {
                          setState(() {
                            _isAnswer1Pasted = false;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // 안내 문구
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
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // 하단 버튼 공간
                  ],
                ),
              ),
            ),
            
            // 하단 신청 버튼
            Container(
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isValid() && !_isSubmitting
                        ? _submitApplication
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid() && !_isSubmitting
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                      foregroundColor: _isValid() && !_isSubmitting
                          ? Colors.white
                          : AppTheme.textTertiaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('신청 완료'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionField extends StatefulWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final int minLength;
  final int recommendedLength;
  final bool isPasted;
  final VoidCallback onPasteWarningDismiss;

  const _QuestionField({
    required this.label,
    required this.required,
    required this.controller,
    required this.minLength,
    required this.recommendedLength,
    required this.isPasted,
    required this.onPasteWarningDismiss,
  });

  @override
  State<_QuestionField> createState() => _QuestionFieldState();
}

class _QuestionFieldState extends State<_QuestionField> {
  @override
  Widget build(BuildContext context) {
    final currentLength = widget.controller.text.length;
    final isValid = widget.required
        ? currentLength >= widget.minLength
        : currentLength == 0 || currentLength >= widget.minLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.controller,
          maxLines: 8,
          minLines: 5,
          decoration: InputDecoration(
            hintText: '답변을 작성해주세요.',
            helperText: widget.required
                ? '최소 ${widget.minLength}자, 권장 ${widget.recommendedLength}자 이상 작성해주세요.'
                : '선택 사항입니다. (권장 ${widget.recommendedLength}자 이상)',
            helperMaxLines: 2,
            counterText:
                '${currentLength}자 ${widget.recommendedLength > 0 ? '/ 권장 ${widget.recommendedLength}자' : ''}',
            counterStyle: TextStyle(
              color: currentLength >= widget.recommendedLength
                  ? AppTheme.primaryColor
                  : AppTheme.textTertiaryColor,
            ),
          ),
          validator: (value) {
            if (widget.required && (value == null || value.trim().isEmpty)) {
              return '필수 질문입니다. 답변을 작성해주세요.';
            }
            if (widget.required &&
                value != null &&
                value.trim().length < widget.minLength) {
              return '최소 ${widget.minLength}자 이상 작성해주세요.';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
        if (widget.isPasted) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '복사/붙여넣기가 감지되었습니다. 본인의 진솔한 답변을 작성해주세요.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: widget.onPasteWarningDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.orange.shade700,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (!isValid && currentLength > 0)
          Text(
            '최소 ${widget.minLength}자 이상 작성해주세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                ),
          ),
      ],
    );
  }
}
