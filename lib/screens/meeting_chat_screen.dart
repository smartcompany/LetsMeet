import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_profile_view.dart';

class MeetingChatScreen extends StatefulWidget {
  final String roomId;
  final String meetingTitle;

  const MeetingChatScreen({
    super.key,
    required this.roomId,
    required this.meetingTitle,
  });

  @override
  State<MeetingChatScreen> createState() => _MeetingChatScreenState();
}

class _MeetingChatScreenState extends State<MeetingChatScreen> {
  final ChatService _chatService = ChatService();
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _userName;
  String? _userProfileUrl;
  ChatRoom? _room;
  Map<String, String> _memberProfileUrls = {};

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final token = await currentUser.getIdToken();
      if (token != null) _apiService.setToken(token);

      final room = await _chatService.getChatRoom(widget.roomId);
      if (room == null || !mounted) return;

      // 항상 API에서 최신 프로필 조회 (Firestore 캐시는 프로필 변경 반영 안 됨)
      final memberProfileUrls = <String, String>{};
      for (final memberId in room.memberIds) {
        try {
          final profile = await _apiService.getUserProfile(memberId);
          final url = profile['profile_image_url'] as String?;
          if (url != null && url.isNotEmpty) {
            memberProfileUrls[memberId] = url;
          }
        } catch (_) {}
      }
      final myProfileUrl = memberProfileUrls[currentUser.uid];

      if (mounted) {
        setState(() {
          _room = room;
          _memberProfileUrls = memberProfileUrls;
          _userName = room.memberNames[currentUser.uid] ?? '알 수 없음';
          _userProfileUrl = myProfileUrl;
        });
      }
    } catch (e) {
      print('채팅방 정보 로드 오류: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_userName == null) {
      await _loadRoom();
    }

    try {
      await _chatService.sendMessage(
        roomId: widget.roomId,
        message: _messageController.text.trim(),
        userName: _userName ?? '알 수 없음',
      );
      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 실패: $e')));
      }
    }
  }

  void _showChatSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatSettingsPanel(
        room:
            _room ??
            ChatRoom(
              id: widget.roomId,
              meetingId: '',
              meetingTitle: widget.meetingTitle,
              memberIds: [],
              memberNames: {},
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
        memberProfileUrls: _memberProfileUrls,
        onLeave: () async {
          Navigator.pop(context);
          await _handleLeave();
        },
        onShare: () async {
          Navigator.pop(context);
          await _handleShare();
        },
        onRefresh: _loadRoom,
      ),
    );
  }

  Future<void> _handleLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('정말 이 채팅방을 나가시겠습니까?\n나가면 채팅 기록을 다시 볼 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _chatService.leaveChatRoom(roomId: widget.roomId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('채팅방을 나갔습니다')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('나가기 실패: $e')));
      }
    }
  }

  Future<void> _handleShare() async {
    try {
      final room = _room ?? await _chatService.getChatRoom(widget.roomId);
      if (room == null || room.meetingId.isEmpty) return;

      final meetingUrl = _getMeetingShareUrl(room.meetingId);
      final text =
          'Let\'s Meet에서 "${room.meetingTitle}" 모임을 초대합니다!\n$meetingUrl';
      await Share.share(text, subject: '${room.meetingTitle} 모임 공유');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공유 실패: $e')));
      }
    }
  }

  String _getMeetingShareUrl(String meetingId) {
    const base = 'https://lets-meet-server.vercel.app';
    return '$base/meeting/$meetingId';
  }

  Widget _buildAvatar({
    required String? profileUrl,
    required String name,
    String? userId,
  }) {
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      backgroundImage: profileUrl != null && profileUrl.isNotEmpty
          ? NetworkImage(profileUrl)
          : null,
      child: profileUrl == null || profileUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0] : '?',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
    if (userId != null && userId.isNotEmpty) {
      return GestureDetector(
        onTap: () => UserProfileView.show(
          context,
          userId: userId,
          displayName: name,
          profileImageUrl: profileUrl,
        ),
        child: avatar,
      );
    }
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    final participantCount = _room?.participantCount ?? 0;
    final titleText = participantCount > 0
        ? '${widget.meetingTitle} ($participantCount명)'
        : widget.meetingTitle;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              '채팅방',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showChatSettingsPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.textTertiaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '아직 메시지가 없습니다',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    if (message.isSystem) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      );
                    }

                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isMyMessage = currentUser?.uid == message.userId;

                    final otherProfileUrl = _memberProfileUrls[message.userId];
                    final myProfileUrl = isMyMessage ? _userProfileUrl : null;
                    final displayName = isMyMessage
                        ? (_userName ?? '알 수 없음')
                        : message.userName;
                    final displayProfileUrl = isMyMessage
                        ? myProfileUrl
                        : otherProfileUrl;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMyMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMyMessage) ...[
                            _buildAvatar(
                              profileUrl: displayProfileUrl,
                              name: displayName,
                              userId: message.userId,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMyMessage
                                    ? AppTheme.primaryColor
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: isMyMessage
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isMyMessage
                                          ? Colors.white
                                          : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.message,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isMyMessage
                                          ? Colors.white
                                          : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMyMessage) ...[
                            const SizedBox(width: 8),
                            _buildAvatar(
                              profileUrl: displayProfileUrl,
                              name: displayName,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: AppTheme.primaryColor,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatSettingsPanel extends StatelessWidget {
  final ChatRoom room;
  final Map<String, String> memberProfileUrls;
  final VoidCallback onLeave;
  final VoidCallback onShare;
  final VoidCallback? onRefresh;

  const _ChatSettingsPanel({
    required this.room,
    required this.memberProfileUrls,
    required this.onLeave,
    required this.onShare,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final participants = room.memberIds.map((id) {
      final name = room.memberNames[id] ?? '알 수 없음';
      final profileUrl = memberProfileUrls[id];
      return _ParticipantInfo(
        userId: id,
        name: name,
        profileImageUrl: profileUrl,
        isCurrentUser: id == currentUser?.uid,
      );
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '채팅 설정',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          // 참가자 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '참가자',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: participants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = participants[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    UserProfileView.show(
                      context,
                      userId: p.userId,
                      displayName: p.name,
                      profileImageUrl: p.profileImageUrl,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage:
                            p.profileImageUrl != null &&
                                p.profileImageUrl!.isNotEmpty
                            ? NetworkImage(p.profileImageUrl!)
                            : null,
                        child:
                            p.profileImageUrl == null ||
                                p.profileImageUrl!.isEmpty
                            ? Text(
                                p.name.isNotEmpty ? p.name[0] : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${p.name}${p.isCurrentUser ? ' (나)' : ''}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('모임 공유'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onLeave,
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('나가기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantInfo {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final bool isCurrentUser;

  _ParticipantInfo({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    required this.isCurrentUser,
  });
}
