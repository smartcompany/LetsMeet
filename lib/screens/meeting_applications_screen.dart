import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/application.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
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
  bool _isCreatingChatRoom = false;
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
    try {
      await _apiService.approveApplication(applicationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신청이 승인되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('승인 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

    try {
      await _apiService.rejectApplication(applicationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신청이 거절되었습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('거절 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadApplications();
                      await _checkChatRoom();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final applicationData = _applications[index];
                        final application = Application.fromJson(
                          applicationData,
                        );
                        return _ApplicationCard(
                          applicationData: applicationData,
                          onApprove:
                              application.status == ApplicationStatus.pending
                              ? () => _approveApplication(application.id)
                              : null,
                          onReject:
                              application.status == ApplicationStatus.pending
                              ? () => _rejectApplication(application.id)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
                // 채팅방 만들기/이동 버튼
                if (_meeting != null) _buildChatButton(),
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
      print('🔵 [MeetingApplicationsScreen] 승인된 사용자 목록 가져오기 시작');

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

      print(
        '🔵 [MeetingApplicationsScreen] 승인된 사용자 수: ${approvedUsers.length}',
      );
      print(
        '🔵 [MeetingApplicationsScreen] 승인된 사용자 목록: ${approvedUsers.map((u) => u['userId']).toList()}',
      );

      // 호스트 추가
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ [MeetingApplicationsScreen] 로그인되지 않음');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
        return;
      }

      print('🔵 [MeetingApplicationsScreen] 호스트 UID: ${currentUser.uid}');

      final memberIds = [
        currentUser.uid,
        ...approvedUsers.map((u) => u['userId'] as String),
      ];
      final memberNames = <String, String>{currentUser.uid: _meeting!.hostName};
      for (final user in approvedUsers) {
        memberNames[user['userId'] as String] = user['name'] as String;
      }

      print('🔵 [MeetingApplicationsScreen] 최종 멤버 ID 목록: $memberIds');
      print('🔵 [MeetingApplicationsScreen] 최종 멤버 이름: $memberNames');
      print(
        '🔵 [MeetingApplicationsScreen] 채팅방 생성 시작 - 멤버 수: ${memberIds.length}',
      );

      // 채팅방 생성
      final meetingImageUrl =
          (_meeting!.imageUrls != null && _meeting!.imageUrls!.isNotEmpty)
          ? _meeting!.imageUrls!.first
          : null;

      // 호스트: 마이 프로필 사진(profile_image_url) 사용 (로그인 계정 photoURL 아님)
      final memberProfileUrls = <String, String>{};
      try {
        final appUser = await _apiService.getCurrentUser();
        if (appUser.profileImageUrl != null &&
            appUser.profileImageUrl!.isNotEmpty) {
          memberProfileUrls[currentUser.uid] = appUser.profileImageUrl!;
        }
      } catch (_) {
        // 프로필 조회 실패 시 프로필 사진 없이 진행
      }
      for (final user in approvedUsers) {
        final profileUrl = user['profileImageUrl'] as String?;
        if (profileUrl != null && profileUrl.isNotEmpty) {
          memberProfileUrls[user['userId'] as String] = profileUrl;
        }
      }

      final roomId = await _chatService.createChatRoom(
        meetingId: widget.meetingId,
        meetingTitle: _meeting!.title,
        meetingImageUrl: meetingImageUrl,
        memberIds: memberIds,
        memberNames: memberNames,
        memberProfileUrls: memberProfileUrls.isNotEmpty
            ? memberProfileUrls
            : null,
      );

      print('✅ [MeetingApplicationsScreen] 채팅방 생성 완료 - Room ID: $roomId');
      print('✅ [MeetingApplicationsScreen] Firebase Console에서 확인하세요:');
      print('   프로젝트 ID는 콘솔 로그에서 확인 가능합니다');

      if (mounted) {
        // 채팅방 생성 후 상태 업데이트 및 다시 확인
        setState(() {
          _chatRoomId = roomId;
        });
        print('✅ [MeetingApplicationsScreen] _chatRoomId 업데이트 완료: $roomId');

        // 상태가 제대로 저장되었는지 다시 확인
        await _checkChatRoom();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('채팅방이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
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
          child: ElevatedButton.icon(
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ApplicationCard({
    required this.applicationData,
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
                                    '신뢰도: $userTrustScore',
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
                '답변 1',
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
                      onPressed: onReject,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('거절'),
                    ),
                  if (onApprove != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('승인'),
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
