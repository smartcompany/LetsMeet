import 'package:flutter/material.dart';
import '../providers/meeting_provider.dart';
import '../theme/app_theme.dart';

class HomeMeetingSortBar extends StatelessWidget {
  final HomeMeetingSort selected;
  final ValueChanged<HomeMeetingSort> onChanged;

  const HomeMeetingSortBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _SortTab(
            label: '오늘 인기',
            icon: Icons.local_fire_department_rounded,
            selected: selected == HomeMeetingSort.popular,
            onTap: () => onChanged(HomeMeetingSort.popular),
          ),
          const SizedBox(width: 20),
          _SortTab(
            label: '신규 모임',
            icon: Icons.auto_awesome_rounded,
            selected: selected == HomeMeetingSort.newest,
            onTap: () => onChanged(HomeMeetingSort.newest),
          ),
          const SizedBox(width: 20),
          _SortTab(
            label: '오늘 시작',
            icon: Icons.schedule_rounded,
            selected: selected == HomeMeetingSort.startingToday,
            onTap: () => onChanged(HomeMeetingSort.startingToday),
          ),
        ],
      ),
    );
  }
}

class _SortTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryColor : AppTheme.textTertiaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
