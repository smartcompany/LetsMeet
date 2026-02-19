import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_lib/share_lib_auth.dart' as share_lib;
import 'package:share_lib/share_lib.dart' hide AuthHelper;
import '../models/meeting.dart';
import '../models/user.dart' as app_models;
import '../providers/meeting_provider.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../utils/auth_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/user_profile_view.dart';
import 'create_meeting_screen.dart';
import 'meeting_chat_screen.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _answerController = TextEditingController();
  final PageController _imagePageController = PageController();
  Meeting? _meeting;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isApplied = false;
  bool _showApplicationForm = false;
  String? _errorMessage;
  int _currentImageIndex = 0;
  String? _chatRoomId;
  final ChatService _chatService = ChatService();

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
      final chatRoomId = await _resolveChatRoomId(meeting);

      if (!mounted) return;

      setState(() {
        _meeting = meeting;
        _chatRoomId = chatRoomId;
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

  bool _canAccessMeetingChat(Meeting meeting) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final isHost = currentUser.uid == meeting.hostId;
    if (isHost) return true;

    final applicationStatus = meeting.userApplication?['status']?.toString();
    if (applicationStatus == 'approved') return true;

    return meeting.participants?.any((p) => p.userId == currentUser.uid) == true;
  }

  Future<String?> _resolveChatRoomId(Meeting meeting) async {
    if (!_canAccessMeetingChat(meeting)) {
      return null;
    }

    return _chatService.getChatRoomId(meeting.id);
  }

  void _navigateToChatRoom() {
    if (_meeting == null || _chatRoomId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingChatScreen(
          roomId: _chatRoomId!,
          meetingTitle: _meeting!.title,
        ),
      ),
    );
  }

  Future<void> _editMeeting() async {
    if (_meeting == null) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMeetingScreen(meeting: _meeting),
      ),
    );

    if (updated == true && mounted) {
      _loadMeeting();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모임 삭제'),
        content: const Text('정말로 이 모임을 삭제하시겠습니까?\n삭제된 모임은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _deleteMeeting();
    }
  }

  Future<void> _deleteMeeting() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }

      await apiService.deleteMeeting(widget.meetingId);

      if (!mounted) return;
      Navigator.pop(context, true); // 삭제 성공 후 이전 화면으로 돌아감
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _showMapAppPicker(Meeting meeting) async {
    final locationName = meeting.format == MeetingFormat.online
        ? (meeting.meetingLink ?? '온라인')
        : (meeting.locationDetail ?? meeting.location);

    await MapService.showMapAppPicker(
      context: context,
      locationName: locationName,
      // TODO: 모임에 좌표 정보가 있다면 추가
      // latitude: meeting.latitude,
      // longitude: meeting.longitude,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _answerController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    debugPrint('🔵 [MeetingDetailScreen] 신청 시작');
    final questions = _meeting?.applicationQuestions ?? [];
    final hasQuestion = questions.isNotEmpty && questions[0].isNotEmpty;

    if (hasQuestion) {
      final answer = _answerController.text.trim();
      debugPrint('🔵 [MeetingDetailScreen] 답변 길이: ${answer.length}');
      if (answer.length < 5 || answer.length > 100) {
        debugPrint('❌ [MeetingDetailScreen] 답변 길이 오류');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('5자 이상 100자 이내로 작성해주세요.')),
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
      final authProvider =
          context.read<share_lib.AuthProvider<app_models.User>>();

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
      appBar: AppBar(
        title: const Text('모임 상세'),
        actions: [
          if (_meeting != null)
            Builder(
              builder: (context) {
                final currentUser = FirebaseAuth.instance.currentUser;
                final isHost =
                    currentUser != null && currentUser.uid == _meeting!.hostId;
                if (!isHost) return const SizedBox.shrink();

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editMeeting();
                    } else if (value == 'delete') {
                      _confirmDelete();
                    }
                  },
                  itemBuilder: (context) {
                    final isCompletedOrCancelled =
                        _meeting!.status == MeetingStatus.completed ||
                            _meeting!.status == MeetingStatus.cancelled;

                    if (isCompletedOrCancelled) {
                      // 완료/취소된 모임은 삭제만 표시
                      return [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제하기', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      // 진행 중인 모임은 수정/삭제 표시
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('수정하기'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제하기', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
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
                  // 0. 모임 사진
                  if (meeting.imageUrls != null &&
                      meeting.imageUrls!.isNotEmpty) ...[
                    SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _imagePageController,
                            itemCount: meeting.imageUrls!.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                meeting.imageUrls![index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 48),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          // 이전 버튼
                          if (_currentImageIndex > 0)
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    _imagePageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // 다음 버튼
                          if (_currentImageIndex <
                              meeting.imageUrls!.length - 1)
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    _imagePageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // 페이지 인디케이터
                          if (meeting.imageUrls!.length > 1)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  meeting.imageUrls!.length,
                                  (index) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // 1. 모임 주제
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          meeting.title,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 모임 상태 + 채팅 이동
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStatusBadge(meeting.status),
                      if (_chatRoomId != null && _canAccessMeetingChat(meeting))
                        OutlinedButton.icon(
                          onPressed: _navigateToChatRoom,
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('채팅방으로 이동'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(
                              horizontal: -1,
                              vertical: -1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 호스트 프로필 카드
                  InkWell(
                    onTap: () {
                      UserProfileView.show(
                        context,
                        userId: meeting.hostId,
                        displayName: meeting.hostName,
                        profileImageUrl: meeting.hostProfileImageUrl,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            backgroundImage:
                                meeting.hostProfileImageUrl != null &&
                                        meeting.hostProfileImageUrl!.isNotEmpty
                                    ? NetworkImage(meeting.hostProfileImageUrl!)
                                    : null,
                            child: meeting.hostProfileImageUrl == null ||
                                    meeting.hostProfileImageUrl!.isEmpty
                                ? Text(
                                    meeting.hostName.isNotEmpty
                                        ? meeting.hostName[0]
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '호스트',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  meeting.hostName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. 호스트 한 마디
                  if (meeting.hostNote != null) ...[
                    _Section(
                      title: '호스트 한 마디',
                      isHost: isHost,
                      onEdit: () => _editMeeting(),
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
                      isHost: isHost,
                      onEdit: () => _editMeeting(),
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
                      isHost: isHost,
                      onEdit: () => _editMeeting(),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _InfoRow(
                                label: '장소',
                                value: meeting.format == MeetingFormat.online
                                    ? (meeting.meetingLink ?? '온라인')
                                    : (meeting.locationDetail ??
                                        meeting.location),
                              ),
                            ),
                            if (meeting.format != MeetingFormat.online)
                              IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () => _showMapAppPicker(meeting),
                                tooltip: '지도 앱에서 위치 보기',
                              ),
                          ],
                        ),
                        if (meeting.format == MeetingFormat.online &&
                            meeting.meetingLink != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            meeting.meetingLink!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.primaryColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6-1. 참가자들
                  if (meeting.participants != null &&
                      meeting.participants!.isNotEmpty) ...[
                    _Section(
                      title: '참가자들',
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: meeting.participants!.map((p) {
                          final bio = p.bio?.trim();
                          final bioLine = bio != null && bio.isNotEmpty
                              ? (bio.length > 30
                                  ? '${bio.substring(0, 30)}...'
                                  : bio)
                              : null;
                          return SizedBox(
                            width: 100,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    UserProfileView.show(
                                      context,
                                      userId: p.userId,
                                      displayName: p.fullName,
                                      profileImageUrl: p.profileImageUrl,
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundImage:
                                        p.profileImageUrl != null &&
                                                p.profileImageUrl!.isNotEmpty
                                            ? NetworkImage(p.profileImageUrl!)
                                            : null,
                                    child: p.profileImageUrl == null ||
                                            p.profileImageUrl!.isEmpty
                                        ? Icon(
                                            Icons.person_rounded,
                                            size: 36,
                                            color: AppTheme.textTertiaryColor,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                if (bioLine != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    bioLine,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 7. 대화 흐름 요약
                  if (meeting.conversationFlow != null) ...[
                    _Section(
                      title: '대화 흐름 요약',
                      isHost: isHost,
                      onEdit: () => _editMeeting(),
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
                      isHost: isHost,
                      onEdit: () => _editMeeting(),
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
                      if (!isHost) ...[
                        // 질문이 있고 아직 신청 폼을 보여주지 않은 경우
                        if (!_showApplicationForm && !_isApplied)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
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
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('신청하기'),
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
                                      meeting.applicationQuestions
                                                      ?.isNotEmpty ==
                                                  true &&
                                              meeting.applicationQuestions![0]
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
                                  maxLength: 100,
                                  decoration: InputDecoration(
                                    hintText: '답변을 작성해주세요.',
                                    counterText:
                                        '${_answerController.text.length}자 / 100자',
                                    counterStyle: TextStyle(
                                      color:
                                          _answerController.text.length >= 5 &&
                                                  _answerController.text.length <=
                                                      100
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
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _answerController,
                                  builder: (context, value, _) {
                                    final len = value.text.trim().length;
                                    final canSubmit =
                                        !_isSubmitting && len >= 5 && len <= 100;
                                    return Row(
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
                                            onPressed: canSubmit
                                                ? _submitApplication
                                                : null,
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
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : const Text('신청하기'),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
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

  Widget _buildStatusBadge(MeetingStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status) {
      case MeetingStatus.open:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        statusText = '모집 중';
        icon = Icons.event_available;
        break;
      case MeetingStatus.closed:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        statusText = '모집 마감';
        icon = Icons.event_busy;
        break;
      case MeetingStatus.completed:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        statusText = '모임 완료';
        icon = Icons.check_circle;
        break;
      case MeetingStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        statusText = '모임 취소';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isHost;
  final VoidCallback? onEdit;

  const _Section({
    required this.title,
    required this.child,
    this.isHost = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (isHost && onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppTheme.textSecondaryColor,
              ),
          ],
        ),
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
