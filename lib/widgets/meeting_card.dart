import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../providers/meeting_provider.dart';
import '../theme/app_theme.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  /// 내 모임 화면 등에서 신청 상태(대기중/승인됨/거절됨)를 항상 표시할 때 true
  final bool showStatusBadge;
  final bool showHostCreatedBadge;
  final Widget? trailingAction;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.showStatusBadge = false,
    this.showHostCreatedBadge = true,
    this.trailingAction,
  });

  String _formatMeetingDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDay = DateTime(date.year, date.month, date.day);
    final difference = meetingDay.difference(today).inDays;

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '내일';
    } else if (difference == -1) {
      return '어제';
    } else if (difference > 0 && difference <= 7) {
      final weekday = DateFormat('E', 'ko_KR').format(date);
      return '$weekday요일';
    } else {
      return DateFormat('M월 d일', 'ko_KR').format(date);
    }
  }

  String _formatMeetingTime(DateTime date) {
    return DateFormat('a h:mm', 'ko_KR').format(date);
  }

  Color _getInterestColor() {
    final interestColors = {
      '디자인': const Color(0xFF6366F1),
      '개발': const Color(0xFF06B6D4),
      '협업': const Color(0xFF10B981),
      '독서': const Color(0xFF8B5CF6),
      '글쓰기': const Color(0xFFEC4899),
      '문화': const Color(0xFFF59E0B),
      '요리': const Color(0xFFEF4444),
      '음식': const Color(0xFFF97316),
      '환경': const Color(0xFF14B8A6),
      '라이프스타일': const Color(0xFF3B82F6),
      '지속가능성': const Color(0xFF22C55E),
    };

    final firstInterest =
        meeting.interests.isNotEmpty ? meeting.interests.first : '';
    return interestColors[firstInterest] ?? const Color(0xFF6366F1);
  }

  IconData _getInterestIcon() {
    final interestIcons = {
      '디자인': Icons.palette_outlined,
      '개발': Icons.code_outlined,
      '협업': Icons.people_outline,
      '독서': Icons.menu_book_outlined,
      '글쓰기': Icons.edit_note_outlined,
      '문화': Icons.theater_comedy_outlined,
      '요리': Icons.restaurant_outlined,
      '음식': Icons.local_dining_outlined,
      '환경': Icons.eco_outlined,
      '라이프스타일': Icons.spa_outlined,
      '지속가능성': Icons.recycling_outlined,
    };

    final firstInterest =
        meeting.interests.isNotEmpty ? meeting.interests.first : '';
    return interestIcons[firstInterest] ?? Icons.topic_outlined;
  }

  _MyMeetingStatus? _getMyMeetingStatus({
    required bool showMyMeetingsOnly,
    required String? currentUserId,
  }) {
    final shouldShow = showStatusBadge || showMyMeetingsOnly;
    if (!shouldShow || currentUserId == null) return null;
    if (meeting.hostId == currentUserId) {
      if (!showHostCreatedBadge) return null;
      return const _MyMeetingStatus(
        label: '내가 만든 모임',
        color: AppTheme.primaryColor,
      );
    }

    final app = meeting.userApplication;
    final status = app?['status']?.toString();
    if (status == 'approved') {
      return const _MyMeetingStatus(
        label: '참가중',
        color: Color(0xFF16A34A),
      );
    }
    if (status == 'pending' || status == null || status.isEmpty) {
      return const _MyMeetingStatus(
        label: '신청중',
        color: Color(0xFF0284C7),
      );
    }
    if (status == 'rejected') {
      return const _MyMeetingStatus(
        label: '거절됨',
        color: Color(0xFFEF4444),
      );
    }

    if (meeting.participants?.any((p) => p.userId == currentUserId) == true) {
      return const _MyMeetingStatus(
        label: '참가중',
        color: Color(0xFF16A34A),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MeetingProvider.shared,
      builder: (context, _) {
        final meetingProvider = MeetingProvider.shared;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final myStatus = _getMyMeetingStatus(
      showMyMeetingsOnly: meetingProvider.showMyMeetingsOnly,
      currentUserId: currentUserId,
    );
    final interestColor = _getInterestColor();
    final interestIcon = _getInterestIcon();
    final hasImage = meeting.imageUrls != null && meeting.imageUrls!.isNotEmpty;
    const radius = 16.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 이미지 영역 (배경 느낌)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 등록된 사진 또는 그라데이션 플레이스홀더
                      if (hasImage)
                        Image.network(
                          meeting.imageUrls!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(
                            interestColor: interestColor,
                            interestIcon: interestIcon,
                          ),
                        )
                      else
                        _buildImagePlaceholder(
                          interestColor: interestColor,
                          interestIcon: interestIcon,
                        ),
                      // 사진 위 배지 (자기계발/취미, 오프라인)
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 카테고리/취미 배지
                            if (meeting.category != null &&
                                meeting.category!.isNotEmpty)
                              _ImageOverlayBadge(
                                text: meeting.category!,
                                backgroundColor: Colors.black.withOpacity(0.6),
                              )
                            else if (meeting.interests.isNotEmpty)
                              _ImageOverlayBadge(
                                text: meeting.interests.first,
                                backgroundColor: Colors.black.withOpacity(0.6),
                              ),
                            // 온라인/오프라인 배지
                            _ImageOverlayBadge(
                              text: meeting.format == MeetingFormat.online
                                  ? '온라인'
                                  : '오프라인',
                              backgroundColor: meeting.format ==
                                      MeetingFormat.online
                                  ? const Color(0xFF0284C7).withOpacity(0.9)
                                  : const Color(0xFF16A34A).withOpacity(0.9),
                            ),
                          ],
                        ),
                      ),
                      // 찜 버튼
                      if (onToggleFavorite != null)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Material(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onTap: onToggleFavorite,
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 하단 콘텐츠 영역
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        meeting.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // 한 줄 설명
                      if (meeting.shortDescription != null &&
                          meeting.shortDescription!.isNotEmpty) ...[
                        Text(
                          meeting.shortDescription!,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondaryColor.withOpacity(0.9),
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 날짜 · 시간
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatMeetingDate(meeting.meetingDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' · ${_formatMeetingTime(meeting.meetingDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 장소
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              meeting.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 인원
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${meeting.currentParticipantCount}/${meeting.maxParticipants}명',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (trailingAction != null) ...[
                            const Spacer(),
                            trailingAction!,
                          ] else if (myStatus != null) ...[
                            const Spacer(),
                            _StatusBadge(
                              label: myStatus.label,
                              color: myStatus.color,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildImagePlaceholder({
    required Color interestColor,
    required IconData interestIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [interestColor, interestColor.withOpacity(0.7)],
        ),
      ),
      child: Icon(interestIcon, color: Colors.white.withOpacity(0.9), size: 48),
    );
  }
}

class _ImageOverlayBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;

  const _ImageOverlayBadge({required this.text, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MyMeetingStatus {
  final String label;
  final Color color;

  const _MyMeetingStatus({
    required this.label,
    required this.color,
  });
}
