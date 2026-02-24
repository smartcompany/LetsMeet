import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/application.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../utils/trust_score_utils.dart';
import '../widgets/user_profile_view.dart';
import 'meeting_chat_screen.dart';

class MeetingApplicationsScreen extends StatefulWidget {
  final String meetingId;

  const MeetingApplicationsScreen({super.key, required this.meetingId});

  @override
  State<MeetingApplicationsScreen> createState() =>
      _MeetingApplicationsScreenState();
}

class _MeetingApplicationsScreenState extends State<MeetingApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  Meeting? _meeting;
  bool _isLoading = true;
  String? _processingApplicationId; // 승인/거절 처리 중인 신청 ID
  bool _isCreatingChatRoom = false;
  bool _isDeletingChatRoom = false;
  String? _errorMessage;
  String? _chatRoomId;
  final ApiService _apiService = ApiService();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _loadMeeting();
    _loadApplications();
    _checkChatRoom();
  }

  Future<void> _loadMeeting() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          _apiService.setToken(token);
        }
      }

      final meeting = await _apiService.getMeeting(widget.meetingId);
      if (mounted) {
        setState(() {
          _meeting = meeting;
        });
      }
    } catch (e) {
      print('모임 정보 로드 오류: $e');
    }
  }

  Future<void> _checkChatRoom() async {
    try {
      print(
        '🔵 [MeetingApplicationsScreen] 채팅방 확인 시작 - meetingId: ${widget.meetingId}',
      );
      final roomId = await _chatService.getChatRoomId(widget.meetingId);
      print('🔵 [MeetingApplicationsScreen] 채팅방 확인 결과: $roomId');
      if (mounted) {
        setState(() {
          _chatRoomId = roomId;
        });
        print('✅ [MeetingApplicationsScreen] _chatRoomId 업데이트: $roomId');
      }
    } catch (e, stackTrace) {
      print('❌ [MeetingApplicationsScreen] 채팅방 확인 오류: $e');
      print('❌ [MeetingApplicationsScreen] 스택 트레이스: $stackTrace');
    }
  }

  Future<void> _loadApplications() async {
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

      final applications = await _apiService.getApplications(widget.meetingId);

      if (!mounted) return;

      // 즉시 참여 모임인데 대기 중인 신청이 있으면 자동 승인 (기존 데이터 정합성)
      Meeting? meeting = _meeting;
      if (meeting == null) {
        meeting = await _apiService.getMeeting(widget.meetingId);
        if (mounted) setState(() => _meeting = meeting);
      }
      var finalApplications = applications;
      if (meeting.approvalType == ApprovalType.immediate && mounted) {
        for (final app in applications) {
          if (Application.fromJson(app).status == ApplicationStatus.pending) {
            try {
              await _apiService.approveApplication(app['id'] as String);
            } catch (_) {}
          }
        }
        if (!mounted) return;
        finalApplications = await _apiService.getApplications(widget.meetingId);
      }

      if (!mounted) return;
      setState(() {
        _applications = finalApplications;
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

  Future<void> _approveApplication(String applicationId) async {
    if (_processingApplicationId != null) return;
    setState(() => _processingApplicationId = applicationId);
    try {
      await _apiService.approveApplication(applicationId);
      if (!mounted) return;
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('승인 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingApplicationId = null);
    }
  }

  Future<void> _rejectApplication(String applicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신청 거절'),
        content: const Text('정말 이 신청을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_processingApplicationId != null) return;
    setState(() => _processingApplicationId = applicationId);
    try {
      await _apiService.rejectApplication(applicationId);
      if (!mounted) return;
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('거절 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingApplicationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('신청 관리')),
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
                    '신청 목록을 불러올 수 없습니다',
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
                    onPressed: _loadApplications,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : _applications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppTheme.textTertiaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 신청이 없습니다',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadApplications();
                      await _checkChatRoom();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 모임 질문 상단 표시
                        if (_meeting?.applicationQuestions != null &&
                            _meeting!.applicationQuestions!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.help_outline,
                                      size: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '참가 전 질문',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _meeting!.applicationQuestions!.first,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                        ...List.generate(_applications.length, (index) {
                          final applicationData = _applications[index];
                          final application = Application.fromJson(
                            applicationData,
                          );
                          return _ApplicationCard(
                            applicationData: applicationData,
                            questionText: _meeting?.applicationQuestions != null &&
                                _meeting!.applicationQuestions!.isNotEmpty
                                ? _meeting!.applicationQuestions!.first
                                : null,
                            isProcessing: _processingApplicationId != null,
                            onApprove:
                                application.status == ApplicationStatus.pending
                                    ? () => _approveApplication(application.id)
                                    : null,
                            onReject:
                                application.status == ApplicationStatus.pending
                                    ? () => _rejectApplication(application.id)
                                    : null,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                    // 채팅방 만들기/이동 버튼
                    if (_meeting != null) _buildChatButton(),
                  ],
                ),
                if (_processingApplicationId != null)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _createChatRoom() async {
    print('🔵 [MeetingApplicationsScreen] 채팅방 만들기 버튼 클릭');

    if (_isCreatingChatRoom) {
      print('⚠️ [MeetingApplicationsScreen] 이미 채팅방 생성 중');
      return;
    }

    if (_meeting == null) {
      print('⚠️ [MeetingApplicationsScreen] 모임 정보가 없습니다');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모임 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingChatRoom = true;
    });

    try {
      debugPrint('🔵 [채팅방생성] 1. 승인된 사용자 목록 가져오기');
      // 승인된 사용자 목록 가져오기
      final approvedUsers = _applications
          .where(
            (app) =>
                Application.fromJson(app).status == ApplicationStatus.approved,
          )
          .map((app) {
            final userInfo = app['letsmeet_users'] as Map<String, dynamic>?;
            final userId = app['user_id'] as String;
            final name = userInfo?['full_name'] ?? '알 수 없음';
            final profileImageUrl = userInfo?['profile_image_url'] as String?;
            print(
              '🔵 [MeetingApplicationsScreen] 승인된 사용자: userId=$userId, name=$name',
            );
            return {
              'userId': userId,
              'name': name,
              'profileImageUrl': profileImageUrl,
            };
          })
          .toList();
      debugPrint('🔵 [채팅방생성] 2. 승인된 사용자 ${approvedUsers.length}명');

      // 호스트 추가
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ [MeetingApplicationsScreen] 로그인되지 않음');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      final memberIds = [
        currentUser.uid,
        ...approvedUsers.map((u) => u['userId'] as String),
      ];
      final memberNames = <String, String>{currentUser.uid: _meeting!.hostName};
      for (final user in approvedUsers) {
        memberNames[user['userId'] as String] = user['name'] as String;
      }

      // 채팅방 생성
      final meetingImageUrl =
          (_meeting!.imageUrls != null && _meeting!.imageUrls!.isNotEmpty)
          ? _meeting!.imageUrls!.first
          : null;

      // 호스트: 마이 프로필 사진(profile_image_url) 사용 (로그인 계정 photoURL 아님)
      debugPrint('🔵 [채팅방생성] 3. getCurrentUser() 호출 (API)');
      final memberProfileUrls = <String, String>{};
      try {
        final appUser = await _apiService.getCurrentUser();
        debugPrint('🔵 [채팅방생성] 3. getCurrentUser() 완료');
        if (appUser.profileImageUrl != null &&
            appUser.profileImageUrl!.isNotEmpty) {
          memberProfileUrls[currentUser.uid] = appUser.profileImageUrl!;
        }
      } catch (e) {
        debugPrint('🔵 [채팅방생성] 3. getCurrentUser() 실패(무시): $e');
      }
      for (final user in approvedUsers) {
        final profileUrl = user['profileImageUrl'] as String?;
        if (profileUrl != null && profileUrl.isNotEmpty) {
          memberProfileUrls[user['userId'] as String] = profileUrl;
        }
      }

      debugPrint('🔵 [채팅방생성] 4. createChatRoom() 호출 (Firestore)');
      final roomId = await _chatService.createChatRoom(
        meetingId: widget.meetingId,
        meetingTitle: _meeting!.title,
        meetingImageUrl: meetingImageUrl,
        memberIds: memberIds,
        memberNames: memberNames,
        memberProfileUrls: memberProfileUrls.isNotEmpty
            ? memberProfileUrls
            :         null,
      );
      debugPrint('🔵 [채팅방생성] 5. createChatRoom() 완료 roomId=$roomId');

      // 승인된 참가자들에게 채팅방 생성 알림 전송 (백그라운드, UI 블로킹 방지)
      final recipientIds = approvedUsers.map((u) => u['userId'] as String).toList();
      if (recipientIds.isNotEmpty) {
        unawaited(
          _apiService
              .notifyChatMessage(
                recipientUserIds: recipientIds,
                title: '${_meeting!.title}',
                body: '모임장이 채팅방을 만들었습니다. 대화를 시작해보세요!',
                data: {
                  'type': 'chat_room_created',
                  'room_id': roomId,
                  'meeting_id': widget.meetingId,
                },
              )
              .catchError((_) {}),
        );
      }

      if (mounted) {
        // 채팅방 생성 후 상태 업데이트 및 다시 확인
        setState(() {
          _chatRoomId = roomId;
        });
        print('✅ [MeetingApplicationsScreen] _chatRoomId 업데이트 완료: $roomId');
        // 채팅 화면으로 이동
        _navigateToChat(roomId);
      }
    } catch (e, stackTrace) {
      print('❌ [MeetingApplicationsScreen] 채팅방 생성 오류: $e');
      print('❌ [MeetingApplicationsScreen] 스택 트레이스: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅방 생성 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChatRoom = false;
        });
      }
    }
  }

  void _navigateToChat(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingChatScreen(
          roomId: roomId,
          meetingTitle: _meeting?.title ?? '모임 채팅',
        ),
      ),
    );
  }

  Future<void> _deleteChatRoom() async {
    if (_chatRoomId == null || _isDeletingChatRoom) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방 삭제'),
        content: const Text('채팅방을 삭제하시겠습니까? (디버그 전용)'),
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
    if (confirmed != true) return;

    setState(() {
      _isDeletingChatRoom = true;
    });
    try {
      await _chatService.deleteChatRoom(_chatRoomId!);
      if (!mounted) return;
      setState(() {
        _chatRoomId = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 삭제 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingChatRoom = false;
        });
      }
    }
  }

  Widget _buildChatButton() {
    final approvedCount = _applications
        .where(
          (app) =>
              Application.fromJson(app).status == ApplicationStatus.approved,
        )
        .length;

    if (approvedCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              '승인된 사용자가 없어 채팅방을 만들 수 없습니다',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: kDebugMode && _chatRoomId != null
              ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCreatingChatRoom
                            ? null
                            : () => _navigateToChat(_chatRoomId!),
                        icon: _isCreatingChatRoom
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.chat),
                        label: Text(
                          _isCreatingChatRoom ? '채팅방 생성 중...' : '채팅으로 이동',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCreatingChatRoom
                              ? AppTheme.primaryColor.withOpacity(0.6)
                              : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isDeletingChatRoom ? null : _deleteChatRoom,
                      icon: _isDeletingChatRoom
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: const Text('삭제'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: _isCreatingChatRoom
                      ? null
                      : (_chatRoomId != null
                            ? () => _navigateToChat(_chatRoomId!)
                            : _createChatRoom),
                  icon: _isCreatingChatRoom
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(_chatRoomId != null ? Icons.chat : Icons.add),
                  label: Text(
                    _isCreatingChatRoom
                        ? '채팅방 생성 중...'
                        : (_chatRoomId != null ? '채팅으로 이동' : '채팅방 만들기'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCreatingChatRoom
                        ? AppTheme.primaryColor.withOpacity(0.6)
                        : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> applicationData;
  final String? questionText;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ApplicationCard({
    required this.applicationData,
    this.questionText,
    this.isProcessing = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final application = Application.fromJson(applicationData);
    final userId = applicationData['user_id'] as String? ?? '';
    final userInfo = applicationData['letsmeet_users'] as Map<String, dynamic>?;
    final userName = userInfo?['full_name'] ?? '알 수 없음';
    final profileImageUrl = userInfo?['profile_image_url'] as String?;
    final userTrustScore = userInfo?['trust_score'] ?? 0;

    final statusColor = {
      ApplicationStatus.pending: Colors.orange,
      ApplicationStatus.approved: Colors.green,
      ApplicationStatus.rejected: Colors.red,
      ApplicationStatus.cancelled: Colors.grey,
    }[application.status];

    final statusText = {
      ApplicationStatus.pending: '대기 중',
      ApplicationStatus.approved: '승인됨',
      ApplicationStatus.rejected: '거절됨',
      ApplicationStatus.cancelled: '취소됨',
    }[application.status];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: userId.isNotEmpty
                        ? () => UserProfileView.show(
                            context,
                            userId: userId,
                            displayName: userName,
                            profileImageUrl: profileImageUrl,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          backgroundImage:
                              profileImageUrl != null &&
                                  profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child:
                              profileImageUrl == null || profileImageUrl.isEmpty
                              ? Text(
                                  userName.isNotEmpty ? userName[0] : '?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '신뢰도: ${TrustScoreUtils.toDisplayString(TrustScoreUtils.parse(userTrustScore))}점',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor ?? Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusText ?? '',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (application.answer1 != null) ...[
              const SizedBox(height: 16),
              Text(
                questionText ?? '답변',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                application.answer1!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (application.answer2 != null) ...[
              const SizedBox(height: 16),
              Text(
                '답변 2',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                application.answer2!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '신청일: ${DateFormat('yyyy년 M월 d일 HH:mm', 'ko_KR').format(application.appliedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiaryColor,
              ),
            ),
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    TextButton(
                      onPressed: isProcessing ? null : onReject,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('거절'),
                    ),
                  if (onApprove != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isProcessing ? null : onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text('승인'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
