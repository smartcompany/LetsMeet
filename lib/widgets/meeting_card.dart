import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../theme/app_theme.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;

  const MeetingCard({super.key, required this.meeting, required this.onTap});

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

    final firstInterest = meeting.interests.isNotEmpty
        ? meeting.interests.first
        : '';
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

    final firstInterest = meeting.interests.isNotEmpty
        ? meeting.interests.first
        : '';
    return interestIcons[firstInterest] ?? Icons.topic_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final interestColor = _getInterestColor();
    final interestIcon = _getInterestIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  interestColor.withOpacity(0.08),
                  interestColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: interestColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 썸네일/아이콘과 배지
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일 이미지 또는 아이콘
                    if (meeting.imageUrls != null &&
                        meeting.imageUrls!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          meeting.imageUrls!.first,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    interestColor,
                                    interestColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(interestIcon, color: Colors.white, size: 28),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              interestColor,
                              interestColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: interestColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(interestIcon, color: Colors.white, size: 28),
                      ),
                    const Spacer(),
                    // 온라인/오프라인 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: meeting.format == MeetingFormat.online
                            ? const Color(0xFFE0F2FE).withOpacity(0.8)
                            : const Color(0xFFF0FDF4).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: meeting.format == MeetingFormat.online
                              ? const Color(0xFF0284C7).withOpacity(0.3)
                              : const Color(0xFF16A34A).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            meeting.format == MeetingFormat.online
                                ? Icons.videocam
                                : Icons.location_on,
                            size: 14,
                            color: meeting.format == MeetingFormat.online
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meeting.format == MeetingFormat.online
                                ? '온라인'
                                : '오프라인',
                            style: TextStyle(
                              color: meeting.format == MeetingFormat.online
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF16A34A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 주제
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // 한 줄 설명
                if (meeting.shortDescription != null)
                  Text(
                    meeting.shortDescription!,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondaryColor.withOpacity(0.9),
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 20),

                // 카테고리/취미
                if (meeting.category != null && meeting.category!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MetaChip(
                      icon: Icons.category_rounded,
                      text: meeting.category!,
                      color: interestColor,
                    ),
                  ),

                // 날짜와 시간 (하나의 행으로)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatMeetingDate(meeting.meetingDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatMeetingTime(meeting.meetingDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 인원과 장소 (구분된 행)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${meeting.maxParticipants}명',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 8),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 호스트 정보
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              interestColor.withOpacity(0.3),
                              interestColor.withOpacity(0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: interestColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '호스트',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meeting.hostNickname,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
