import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../widgets/auth_required_content.dart';
import 'meeting_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  final void Function(int totalUnread)? onUnreadCountChanged;

  const ChatScreen({super.key, this.onUnreadCountChanged});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  Stream<List<ChatRoom>>? _chatRoomsStream;
  String? _streamUserId;

  Stream<List<ChatRoom>> _getChatRoomsStream(BuildContext context) {
    final uid = AppAuthProvider.shared.userProfile?.id;
    if (uid == _streamUserId && _chatRoomsStream != null) {
      return _chatRoomsStream!;
    }
    _streamUserId = uid;
    _chatRoomsStream = _chatService.getUserChatRoomsStream();
    return _chatRoomsStream!;
  }

  @override
  Widget build(BuildContext context) {
    return AuthRequiredContent(
      child: ListenableBuilder(
        listenable: AppAuthProvider.shared,
        builder: (context, _) {
          if (!AppAuthProvider.shared.isInitialized ||
              AppAuthProvider.shared.isInitializing) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<ChatRoom>>(
            stream: _getChatRoomsStream(context),
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '채팅방 목록을 불러올 수 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.forum_rounded,
                      size: 64,
                      color: AppTheme.primaryColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '채팅 목록이 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '승인된 모임의 채팅방이 여기에 표시됩니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textTertiaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final meetingRooms =
              chatRooms.where((r) => r.meetingId.isNotEmpty).toList();
          final personalRooms =
              chatRooms.where((r) => r.meetingId.isEmpty).toList();
          final currentUser =
              AppAuthProvider.shared.userProfile;

          return _ChatListWithTabs(
            meetingRooms: meetingRooms,
            personalRooms: personalRooms,
            chatService: _chatService,
            onUnreadTotalChanged: widget.onUnreadCountChanged,
            onRoomTap: (room) {
              String title = room.meetingTitle;
              if (title.isEmpty) {
                title = room.memberIds
                    .where((id) => id != currentUser?.id)
                    .map((id) => room.memberNames[id] ?? '')
                    .join(', ');
                if (title.isEmpty) title = '채팅';
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingChatScreen(
                    roomId: room.id,
                    meetingTitle: title,
                  ),
                ),
              );
            },
          );
          },
          );
        },
      ),
    );
  }
}

class _ChatListWithTabs extends StatefulWidget {
  final List<ChatRoom> meetingRooms;
  final List<ChatRoom> personalRooms;
  final ChatService chatService;
  final void Function(int)? onUnreadTotalChanged;
  final void Function(ChatRoom room) onRoomTap;

  const _ChatListWithTabs({
    required this.meetingRooms,
    required this.personalRooms,
    required this.chatService,
    required this.onUnreadTotalChanged,
    required this.onRoomTap,
  });

  @override
  State<_ChatListWithTabs> createState() => _ChatListWithTabsState();
}

class _ChatListWithTabsState extends State<_ChatListWithTabs> {
  final Map<String, int> _roomUnread = {};
  final Map<String, bool> _roomIsMeeting = {};
  int _meetingUnread = 0;
  int _personalUnread = 0;

  void _onRoomUnreadChanged(String roomId, int unread, bool isMeeting) {
    if (_roomUnread[roomId] == unread) return;
    _roomUnread[roomId] = unread;
    _roomIsMeeting[roomId] = isMeeting;
    int meetingTotal = 0;
    int personalTotal = 0;
    for (final e in _roomUnread.entries) {
      if (_roomIsMeeting[e.key] == true) {
        meetingTotal += e.value;
      } else {
        personalTotal += e.value;
      }
    }
    if (meetingTotal != _meetingUnread || personalTotal != _personalUnread) {
      setState(() {
        _meetingUnread = meetingTotal;
        _personalUnread = personalTotal;
      });
      widget.onUnreadTotalChanged?.call(meetingTotal + personalTotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              indicatorColor: AppTheme.primaryColor,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('모임'),
                      if (_meetingUnread > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _meetingUnread > 99 ? '99+' : '$_meetingUnread',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('개인'),
                      if (_personalUnread > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _personalUnread > 99 ? '99+' : '$_personalUnread',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ChatListTab(
                  chatRooms: widget.meetingRooms,
                  chatService: widget.chatService,
                  onRoomTap: widget.onRoomTap,
                  onUnreadChanged: (roomId, count) =>
                      _onRoomUnreadChanged(roomId, count, true),
                ),
                _ChatListTab(
                  chatRooms: widget.personalRooms,
                  chatService: widget.chatService,
                  onRoomTap: widget.onRoomTap,
                  onUnreadChanged: (roomId, count) =>
                      _onRoomUnreadChanged(roomId, count, false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListTab extends StatelessWidget {
  final List<ChatRoom> chatRooms;
  final ChatService chatService;
  final void Function(ChatRoom room) onRoomTap;
  final void Function(String roomId, int count) onUnreadChanged;

  const _ChatListTab({
    required this.chatRooms,
    required this.chatService,
    required this.onRoomTap,
    required this.onUnreadChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppTheme.textTertiaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '채팅 목록이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          return _ChatRoomCardWithUnread(
            room: room,
            chatService: chatService,
            onTap: () => onRoomTap(room),
            onUnreadChanged: (count) => onUnreadChanged(room.id, count),
          );
        },
      ),
    );
  }
}

/// 리스트 전체가 아닌 해당 아이템만 리빌드되도록 StreamBuilder를 개별 위젯으로 분리
class _ChatRoomCardWithUnread extends StatefulWidget {
  final ChatRoom room;
  final ChatService chatService;
  final VoidCallback onTap;
  final void Function(int count) onUnreadChanged;

  const _ChatRoomCardWithUnread({
    required this.room,
    required this.chatService,
    required this.onTap,
    required this.onUnreadChanged,
  });

  @override
  State<_ChatRoomCardWithUnread> createState() =>
      _ChatRoomCardWithUnreadState();
}

class _ChatRoomCardWithUnreadState extends State<_ChatRoomCardWithUnread> {
  int? _lastNotifiedUnread;

  void _notifyUnreadChanged(int unread) {
    if (_lastNotifiedUnread == unread) return;
    _lastNotifiedUnread = unread;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onUnreadChanged(unread);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.chatService.getRoomUnreadCountStream(widget.room.id),
      initialData: 0,
      builder: (context, unreadSnapshot) {
        final unread = unreadSnapshot.data ?? 0;
        _notifyUnreadChanged(unread);
        return StreamBuilder<ChatMessage?>(
          stream: widget.chatService.getLastMessageStream(widget.room.id),
          builder: (context, lastMsgSnapshot) {
            return _ChatRoomCard(
              room: widget.room,
              unreadCount: unread,
              lastMessage: lastMsgSnapshot.data,
              onTap: widget.onTap,
            );
          },
        );
      },
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final int unreadCount;
  final ChatMessage? lastMessage;
  final VoidCallback onTap;

  const _ChatRoomCard({
    required this.room,
    required this.onTap,
    this.unreadCount = 0,
    this.lastMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        AppAuthProvider.shared.userProfile?.id;
    final otherMembers = room.memberIds
        .where((id) => id != currentUserId)
        .map((id) => room.memberNames[id] ?? '알 수 없음')
        .toList();

    // 1:1 DM: 제목 = 상대방 이름, 모임 채팅: 제목 = 모임명
    final isDirectMessage = room.meetingId.isEmpty;
    final displayTitle = isDirectMessage && otherMembers.isNotEmpty
        ? otherMembers.join(', ')
        : room.meetingTitle;
    final otherMemberId = isDirectMessage
        ? room.memberIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          )
        : '';
    final otherProfileUrl = isDirectMessage
        ? room.memberProfileUrls == null
            ? null
            : room.memberProfileUrls![otherMemberId]
        : null;
    final thumbnailUrl =
        isDirectMessage ? otherProfileUrl : room.meetingImageUrl;

    // 부제목 = 마지막 대화 내용
    final displaySubtitle = lastMessage?.message ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 모임 대표 아이콘 (썸네일 또는 기본 아이콘)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultChatIcon(),
                      )
                    : _buildDefaultChatIcon(),
              ),
              const SizedBox(width: 16),
              // 채팅방 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displaySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        displaySubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 읽지 않음 + 마지막 업데이트 시간
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(room.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiaryColor,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiaryColor,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultChatIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm', 'ko_KR').format(dateTime);
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('M/d', 'ko_KR').format(dateTime);
    }
  }
}
