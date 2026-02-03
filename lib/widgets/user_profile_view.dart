import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart' as share_lib;
import '../models/user.dart' as app_models;
import '../screens/meeting_chat_screen.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'profile_card.dart';

/// 다른 사용자의 프로필을 보여주는 공통 위젯
class UserProfileView extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? profileImageUrl;
  final app_models.User? previewUser;

  const UserProfileView({
    super.key,
    required this.userId,
    this.displayName,
    this.profileImageUrl,
    this.previewUser,
  });

  /// 작성 중인 프로필 미리보기 (저장 전 데이터로 표시)
  static void showPreview(
    BuildContext context, {
    required String fullName,
    String? profileImageUrl,
    String? backgroundImageUrl,
    String? bio,
    String? gender,
    DateTime? createdAt,
    int trustScore = 70,
    List<String> interests = const [],
  }) {
    final user = app_models.User(
      id: 'preview',
      fullName: fullName,
      profileImageUrl: profileImageUrl,
      backgroundImageUrl: backgroundImageUrl,
      bio: bio,
      gender: gender,
      trustScore: trustScore,
      trustLevel: _calcTrustLevel(trustScore),
      interests: interests,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserProfileView(userId: 'preview', previewUser: user),
      ),
    );
  }

  static app_models.TrustLevel _calcTrustLevel(int score) {
    if (score >= 90) return app_models.TrustLevel.trust;
    if (score >= 70) return app_models.TrustLevel.stable;
    if (score >= 50) return app_models.TrustLevel.caution;
    return app_models.TrustLevel.restricted;
  }

  static void show(
    BuildContext context, {
    required String userId,
    String? displayName,
    String? profileImageUrl,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileView(
          userId: userId,
          displayName: displayName,
          profileImageUrl: profileImageUrl,
        ),
      ),
    );
  }

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final ApiService _apiService = ApiService();
  final ChatService _chatService = ChatService();
  app_models.User? _user;
  bool _isOpeningChat = false;
  int _hostedMeetingsCount = 0;
  int _participatedMeetingsCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.previewUser != null) {
      _user = widget.previewUser;
      _isLoading = false;
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) _apiService.setToken(token);
    } catch (_) {}

    try {
      final data = await _apiService.getUserProfile(widget.userId);
      if (!mounted) return;

      final trustScore = (data['trust_score'] ?? 0) is int
          ? (data['trust_score'] as int)
          : int.tryParse(data['trust_score']?.toString() ?? '0') ?? 0;
      final createdAt = _parseDateTime(data['created_at']);
      final updatedAt = _parseDateTime(data['updated_at']);

      setState(() {
        _user = app_models.User(
          id:
              data['id'] as String? ??
              data['user_id'] as String? ??
              widget.userId,
          phoneNumber: null,
          fullName: (data['full_name'] as String?) ?? widget.displayName ?? '',
          profileImageUrl: data['profile_image_url'] as String?,
          gender: data['gender'] as String?,
          bio: data['bio'] as String?,
          backgroundImageUrl: data['background_image_url'] as String?,
          trustScore: trustScore,
          trustLevel: _calculateTrustLevel(trustScore),
          interests: List<String>.from(data['interests'] ?? []),
          createdAt: createdAt,
          updatedAt: updatedAt,
          isActive: data['is_active'] as bool? ?? true,
        );
        _hostedMeetingsCount = (data['hosted_meetings_count'] as int?) ?? 0;
        _participatedMeetingsCount =
            (data['participated_meetings_count'] as int?) ?? 0;
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static app_models.TrustLevel _calculateTrustLevel(int trustScore) {
    if (trustScore >= 90) return app_models.TrustLevel.trust;
    if (trustScore >= 70) return app_models.TrustLevel.stable;
    if (trustScore >= 50) return app_models.TrustLevel.caution;
    return app_models.TrustLevel.restricted;
  }

  double get _rating => (_user?.trustScore ?? 0) / 20.0; // 0-100 -> 0-5

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.previewUser != null ? '프로필 미리보기' : '프로필',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _user == null
          ? const Center(child: Text('사용자를 찾을 수 없습니다'))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(),
                  if (widget.previewUser == null) ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                  const SizedBox(height: 16),
                  _buildStatisticsGrid(),
                  const SizedBox(height: 24),
                  _buildInterestsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '프로필을 불러올 수 없습니다',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return ProfileCard(
      fullName: _user!.fullName,
      profileImageUrl: _user!.profileImageUrl,
      backgroundImageUrl: _user!.backgroundImageUrl,
      createdAt: _user!.createdAt,
      bio: _user!.bio,
      gender: _user!.gender,
      showTrustBadge: false,
      showInterests: false,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _openDirectChat() async {
    if (_isOpeningChat || _user == null) return;
    final authUser = context
        .read<share_lib.AuthProvider<app_models.User>>()
        .user;
    if (authUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      }
      return;
    }
    if (authUser.id == widget.userId) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('본인에게 메시지를 보낼 수 없습니다')));
      }
      return;
    }

    setState(() => _isOpeningChat = true);
    try {
      final roomId = await _chatService.getOrCreateDirectChatRoom(
        otherUserId: widget.userId,
        otherUserName: _user!.fullName,
        otherProfileImageUrl: _user!.profileImageUrl,
        myUserName: authUser.fullName,
        myProfileImageUrl: authUser.profileImageUrl,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MeetingChatScreen(roomId: roomId, meetingTitle: _user!.fullName),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('채팅방 열기 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isOpeningChat ? null : _openDirectChat,
              icon: _isOpeningChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(_isOpeningChat ? '연결 중...' : '메시지 보내기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('팔로우 기능은 준비 중입니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.favorite_border, size: 18),
              label: const Text('팔로우'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '${_participatedMeetingsCount}',
                    '참여한 모임',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('${_hostedMeetingsCount}', '주최한 모임'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('0', '팔로워')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    _rating.toStringAsFixed(1),
                    '평점',
                    icon: Icons.star,
                    iconColor: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (icon != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    if (_user!.interests.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '관심사',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _user!.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
