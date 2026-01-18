import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../theme/app_theme.dart';

class FilterBar extends StatelessWidget {
  final String? selectedLocation;
  final String? selectedInterest;
  final MeetingFormat? selectedFormat;
  final List<String> availableLocations;
  final List<String> availableInterests;
  final Function(String?) onLocationChanged;
  final Function(String?) onInterestChanged;
  final Function(MeetingFormat?) onFormatChanged;
  final VoidCallback onClear;

  const FilterBar({
    super.key,
    required this.selectedLocation,
    required this.selectedInterest,
    required this.selectedFormat,
    required this.availableLocations,
    required this.availableInterests,
    required this.onLocationChanged,
    required this.onInterestChanged,
    required this.onFormatChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedLocation != null ||
        selectedInterest != null ||
        selectedFormat != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 지역 필터
            _FilterChip(
              label: '지역',
              icon: Icons.location_on_outlined,
              value: selectedLocation,
              options: availableLocations,
              onChanged: onLocationChanged,
            ),
            const SizedBox(width: 10),
            
            // 관심사 필터
            _FilterChip(
              label: '관심사',
              icon: Icons.label_outline,
              value: selectedInterest,
              options: availableInterests,
              onChanged: onInterestChanged,
            ),
            const SizedBox(width: 10),
            
            // 온라인/오프라인 필터
            _FormatFilterChip(
              selected: selectedFormat,
              onChanged: onFormatChanged,
            ),
            
            // 필터 초기화 버튼
            if (hasActiveFilters) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.dividerColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '초기화',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final Function(String?) onChanged;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value != null;
    
    return PopupMenuButton<String?>(
      initialValue: value,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.dividerColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              value ?? label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textPrimaryColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isSelected
                  ? Colors.white.withOpacity(0.9)
                  : AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              const Icon(Icons.clear_rounded, size: 16),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
        ...options.map(
          (option) => PopupMenuItem<String?>(
            value: option,
            child: Text(option),
          ),
        ),
      ],
      onSelected: onChanged,
    );
  }
}

class _FormatFilterChip extends StatelessWidget {
  final MeetingFormat? selected;
  final Function(MeetingFormat?) onChanged;

  const _FormatFilterChip({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected != null;
    
    return PopupMenuButton<MeetingFormat?>(
      initialValue: selected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.dividerColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected == MeetingFormat.online
                  ? Icons.videocam_outlined
                  : selected == MeetingFormat.offline
                      ? Icons.location_on_outlined
                      : Icons.tune_rounded,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              selected == MeetingFormat.online
                  ? '온라인'
                  : selected == MeetingFormat.offline
                      ? '오프라인'
                      : '방식',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textPrimaryColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isSelected
                  ? Colors.white.withOpacity(0.9)
                  : AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<MeetingFormat?>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.clear_rounded, size: 16),
              SizedBox(width: 8),
              Text('방식'),
            ],
          ),
        ),
        const PopupMenuItem<MeetingFormat?>(
          value: MeetingFormat.online,
          child: Row(
            children: [
              Icon(Icons.videocam, size: 16, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('온라인'),
            ],
          ),
        ),
        const PopupMenuItem<MeetingFormat?>(
          value: MeetingFormat.offline,
          child: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('오프라인'),
            ],
          ),
        ),
      ],
      onSelected: onChanged,
    );
  }
}
