import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart' as share_lib;
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../config/auth_config.dart';
import '../services/chat_service.dart';
import 'meeting_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  final void Function(int totalUnread)? onUnreadCountChanged;

  const ChatScreen({super.key, this.onUnreadCountChanged});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Consumer<share_lib.AuthProvider<User>>(
      builder: (context, authProvider, child) {
        if (!authProvider.isInitialized && !authProvider.isInitializing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<share_lib.AuthProvider<User>>().initialize();
          });
        }

        // 로그인 안 되어 있으면 안내 메시지
        if (!authProvider.isAuthenticated) {
          return share_lib.LoginRequiredScreen(
            config: authConfig,
            authScreenBuilder: (context) =>
                share_lib.AuthScreen<User>(config: authConfig),
          );
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          return const Center(child: Text('로그인이 필요합니다'));
        }

        return StreamBuilder<List<ChatRoom>>(
          stream: _chatService.getUserChatRoomsStream(),
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

            return _ChatListWithUnread(
              chatRooms: chatRooms,
              chatService: _chatService,
              onUnreadTotalChanged: widget.onUnreadCountChanged,
              onRoomTap: (room) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MeetingChatScreen(
                      roomId: room.id,
                      meetingTitle: room.meetingTitle,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ChatListWithUnread extends StatefulWidget {
  final List<ChatRoom> chatRooms;
  final ChatService chatService;
  final void Function(int)? onUnreadTotalChanged;
  final void Function(ChatRoom room) onRoomTap;

  const _ChatListWithUnread({
    required this.chatRooms,
    required this.chatService,
    required this.onUnreadTotalChanged,
    required this.onRoomTap,
  });

  @override
  State<_ChatListWithUnread> createState() => _ChatListWithUnreadState();
}

class _ChatListWithUnreadState extends State<_ChatListWithUnread> {
  final Map<String, int> _roomUnread = {};
  int _totalUnread = 0;

  void _onRoomUnreadChanged(String roomId, int unread) {
    if (_roomUnread[roomId] == unread) return;
    _roomUnread[roomId] = unread;
    final total = _roomUnread.values.fold(0, (a, b) => a + b);
    if (total != _totalUnread) {
      _totalUnread = total;
      widget.onUnreadTotalChanged?.call(total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.chatRooms.length,
        itemBuilder: (context, index) {
          final room = widget.chatRooms[index];
          return _ChatRoomCardWithUnread(
            room: room,
            chatService: widget.chatService,
            onTap: () => widget.onRoomTap(room),
            onUnreadChanged: (count) => _onRoomUnreadChanged(room.id, count),
          );
        },
      ),
    );
  }
}

/// 리스트 전체가 아닌 해당 아이템만 리빌드되도록 StreamBuilder를 개별 위젯으로 분리
class _ChatRoomCardWithUnread extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: chatService.getRoomUnreadCountStream(room.id),
      initialData: 0,
      builder: (context, unreadSnapshot) {
        final unread = unreadSnapshot.data ?? 0;
        onUnreadChanged(unread);
        return StreamBuilder<ChatMessage?>(
          stream: chatService.getLastMessageStream(room.id),
          builder: (context, lastMsgSnapshot) {
            return _ChatRoomCard(
              room: room,
              unreadCount: unread,
              lastMessage: lastMsgSnapshot.data,
              onTap: onTap,
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final otherMembers = room.memberIds
        .where((id) => id != currentUser?.uid)
        .map((id) => room.memberNames[id] ?? '알 수 없음')
        .toList();

    // 1:1 DM: 제목 = 상대방 이름, 모임 채팅: 제목 = 모임명
    final isDirectMessage = room.meetingId.isEmpty;
    final displayTitle =
        isDirectMessage && otherMembers.isNotEmpty
            ? otherMembers.join(', ')
            : room.meetingTitle;

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
                child:
                    room.meetingImageUrl != null &&
                        room.meetingImageUrl!.isNotEmpty
                    ? Image.network(
                        room.meetingImageUrl!,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
