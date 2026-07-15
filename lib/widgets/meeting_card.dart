import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../providers/meeting_provider.dart';
import '../theme/app_theme.dart';

enum MeetingCardVariant {
  standard,
  hero,
  compact,
}

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final MeetingCardVariant variant;

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
    this.variant = MeetingCardVariant.standard,
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

  double get _participantRatio {
    if (meeting.maxParticipants <= 0) return 0;
    return (meeting.currentParticipantCount / meeting.maxParticipants)
        .clamp(0.0, 1.0);
  }

  int get _participantPercent => (_participantRatio * 100).round();

  String get _locationLabel {
    final detail = meeting.locationDetail?.trim();
    if (detail != null && detail.isNotEmpty) return detail;
    return meeting.location;
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

        switch (variant) {
          case MeetingCardVariant.hero:
            return _buildHeroCard(
              interestColor: interestColor,
              interestIcon: interestIcon,
              myStatus: myStatus,
            );
          case MeetingCardVariant.compact:
            return _buildCompactCard(
              interestColor: interestColor,
              interestIcon: interestIcon,
              myStatus: myStatus,
            );
          case MeetingCardVariant.standard:
            return _buildStandardCard(
              interestColor: interestColor,
              interestIcon: interestIcon,
              myStatus: myStatus,
            );
        }
      },
    );
  }

  Widget _buildCardShell({
    required Widget child,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 20),
    double radius = 16,
  }) {
    return Container(
      margin: margin,
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
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required Color interestColor,
    required IconData interestIcon,
    required _MyMeetingStatus? myStatus,
  }) {
    final hasImage = meeting.imageUrls != null && meeting.imageUrls!.isNotEmpty;

    return _buildCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMeetingImage(
                  hasImage: hasImage,
                  interestColor: interestColor,
                  interestIcon: interestIcon,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _buildOverlayBadges(),
                ),
                if (onToggleFavorite != null)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onToggleFavorite: onToggleFavorite!,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meeting.shortDescription != null &&
                    meeting.shortDescription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    meeting.shortDescription!,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondaryColor.withOpacity(0.95),
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                _DateTimeRow(date: meeting.meetingDate),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  text: _locationLabel,
                ),
                const SizedBox(height: 14),
                if (myStatus != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusBadge(
                      label: myStatus.label,
                      color: myStatus.color,
                    ),
                  )
                else
                  _JoinFooter(
                    current: meeting.currentParticipantCount,
                    max: meeting.maxParticipants,
                    ratio: _participantRatio,
                    percent: _participantPercent,
                    onJoin: onTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard({
    required Color interestColor,
    required IconData interestIcon,
    required _MyMeetingStatus? myStatus,
  }) {
    final hasImage = meeting.imageUrls != null && meeting.imageUrls!.isNotEmpty;

    return _buildCardShell(
      margin: const EdgeInsets.only(bottom: 14),
      radius: 14,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: _buildMeetingImage(
                      hasImage: hasImage,
                      interestColor: interestColor,
                      interestIcon: interestIcon,
                      iconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: onToggleFavorite != null ? 28 : 0,
                        ),
                        child: Text(
                          meeting.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (meeting.shortDescription != null &&
                          meeting.shortDescription!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          meeting.shortDescription!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _DateTimeRow(date: meeting.meetingDate, compact: true),
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        text: meeting.location,
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                      if (myStatus != null)
                        _StatusBadge(
                          label: myStatus.label,
                          color: myStatus.color,
                        )
                      else
                        _JoinFooter(
                          current: meeting.currentParticipantCount,
                          max: meeting.maxParticipants,
                          ratio: _participantRatio,
                          percent: _participantPercent,
                          onJoin: onTap,
                          compact: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onToggleFavorite != null)
            Positioned(
              top: 8,
              right: 8,
              child: _FavoriteButton(
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite!,
                compact: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStandardCard({
    required Color interestColor,
    required IconData interestIcon,
    required _MyMeetingStatus? myStatus,
  }) {
    final hasImage = meeting.imageUrls != null && meeting.imageUrls!.isNotEmpty;

    return _buildCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMeetingImage(
                  hasImage: hasImage,
                  interestColor: interestColor,
                  interestIcon: interestIcon,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _buildOverlayBadges(),
                ),
                if (onToggleFavorite != null)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onToggleFavorite: onToggleFavorite!,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${_formatMeetingDate(meeting.meetingDate)} · ${_formatMeetingTime(meeting.meetingDate)}',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  text: _locationLabel,
                ),
                const SizedBox(height: 10),
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
                      style: const TextStyle(
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
    );
  }

  Widget _buildMeetingImage({
    required bool hasImage,
    required Color interestColor,
    required IconData interestIcon,
    double iconSize = 48,
  }) {
    if (hasImage) {
      return Image.network(
        meeting.imageUrls!.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(
          interestColor: interestColor,
          interestIcon: interestIcon,
          iconSize: iconSize,
        ),
      );
    }
    return _buildImagePlaceholder(
      interestColor: interestColor,
      interestIcon: interestIcon,
      iconSize: iconSize,
    );
  }

  Widget _buildOverlayBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (meeting.category != null && meeting.category!.isNotEmpty)
          _ImageOverlayBadge(
            text: meeting.category!,
            backgroundColor: Colors.black.withOpacity(0.6),
          )
        else if (meeting.interests.isNotEmpty)
          _ImageOverlayBadge(
            text: meeting.interests.first,
            backgroundColor: Colors.black.withOpacity(0.6),
          ),
        _ImageOverlayBadge(
          text: meeting.format == MeetingFormat.online ? '온라인' : '오프라인',
          backgroundColor: meeting.format == MeetingFormat.online
              ? const Color(0xFF0284C7).withOpacity(0.9)
              : const Color(0xFF16A34A).withOpacity(0.9),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder({
    required Color interestColor,
    required IconData interestIcon,
    double iconSize = 48,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [interestColor, interestColor.withOpacity(0.7)],
        ),
      ),
      child: Icon(
        interestIcon,
        color: Colors.white.withOpacity(0.9),
        size: iconSize,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool compact;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 14 : 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final DateTime date;
  final bool compact;

  const _DateTimeRow({
    required this.date,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('M월 d일 (E)', 'ko_KR').format(date);
    final timeText = DateFormat('a h:mm', 'ko_KR').format(date);
    final iconSize = compact ? 14.0 : 16.0;
    final fontSize = compact ? 12.0 : 14.0;

    return Row(
      children: [
        Icon(Icons.calendar_today_rounded,
            size: iconSize, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: fontSize,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.access_time_rounded,
            size: iconSize, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: TextStyle(
            fontSize: fontSize,
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 왼쪽: 인원 + 진행률 + %, 오른쪽: 참가하기 버튼 (아웃라인)
class _JoinFooter extends StatelessWidget {
  final int current;
  final int max;
  final double ratio;
  final int percent;
  final VoidCallback onJoin;
  final bool compact;

  const _JoinFooter({
    required this.current,
    required this.max,
    required this.ratio,
    required this.percent,
    required this.onJoin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 12.0 : 13.0;
    final iconSize = compact ? 14.0 : 15.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.people_outline_rounded,
          size: iconSize,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          '$current / $max명 참여',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: compact ? 5 : 6,
              backgroundColor: AppTheme.dividerColor,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: onJoin,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: const BorderSide(color: AppTheme.primaryColor),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 7 : 8,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            '참가하기',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool compact;

  const _FavoriteButton({
    required this.isFavorite,
    required this.onToggleFavorite,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: compact
          ? Colors.white.withOpacity(0.92)
          : Colors.black.withOpacity(0.4),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onToggleFavorite,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : 8),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite
                ? Colors.red
                : (compact ? AppTheme.textSecondaryColor : Colors.white),
            size: compact ? 20 : 24,
          ),
        ),
      ),
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
