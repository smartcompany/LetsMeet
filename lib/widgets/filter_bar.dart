import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../theme/app_theme.dart';
import '../utils/region_hierarchy.dart';
import '../utils/category_hierarchy.dart';
import 'age_range_selector.dart';
import 'category_picker_sheet.dart';

const _formatClearSentinel = Object();
const _locationClearSentinel = Object();

class FilterBar extends StatelessWidget {
  final int? selectedAgeMin;
  final int? selectedAgeMax;
  final String? selectedLocation;
  final String? selectedCategory;
  final MeetingFormat? selectedFormat;
  final bool showMyMeetingsOnly;
  final Function(int?, int?) onAgeRangeChanged;
  final Function(String?) onLocationChanged;
  final Function(String?) onCategoryChanged;
  final Function(MeetingFormat?) onFormatChanged;
  final Function(bool) onMyMeetingsChanged;
  final VoidCallback onClear;

  const FilterBar({
    super.key,
    this.selectedAgeMin,
    this.selectedAgeMax,
    required this.selectedLocation,
    required this.selectedCategory,
    required this.selectedFormat,
    required this.showMyMeetingsOnly,
    required this.onAgeRangeChanged,
    required this.onLocationChanged,
    required this.onCategoryChanged,
    required this.onFormatChanged,
    required this.onMyMeetingsChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedAgeMin != null ||
        selectedAgeMax != null ||
        selectedLocation != null ||
        selectedCategory != null ||
        selectedFormat != null ||
        showMyMeetingsOnly;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 내모임 토글
                    _MyMeetingsFilterChip(
                      isSelected: showMyMeetingsOnly,
                      onChanged: onMyMeetingsChanged,
                    ),
                    const SizedBox(width: 10),
                    // 나이 필터
                    _AgeFilterChip(
                      minAge: selectedAgeMin,
                      maxAge: selectedAgeMax,
                      onChanged: onAgeRangeChanged,
                    ),
                    const SizedBox(width: 10),
                    // 지역 필터 (2단계)
                    _LocationFilterChip(
                      selectedLocation: selectedLocation,
                      onChanged: onLocationChanged,
                    ),
                    const SizedBox(width: 10),
                    // 카테고리 필터
                    _CategoryFilterChip(
                      selectedCategory: selectedCategory,
                      onChanged: onCategoryChanged,
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
            ),
          );
        },
      ),
    );
  }
}

class _MyMeetingsFilterChip extends StatelessWidget {
  final bool isSelected;
  final Function(bool) onChanged;

  const _MyMeetingsFilterChip({
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
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
              Icons.star_rounded,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              '내모임',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeFilterChip extends StatelessWidget {
  final int? minAge;
  final int? maxAge;
  final Function(int?, int?) onChanged;

  const _AgeFilterChip({
    required this.minAge,
    required this.maxAge,
    required this.onChanged,
  });

  String _getDisplayText() {
    if (minAge == null && maxAge == null) return '나이';
    if (minAge != null && maxAge != null) {
      return maxAge == 50 ? '$minAge~50+세' : '$minAge~$maxAge세';
    }
    if (minAge != null) return '${minAge}세 이상';
    if (maxAge != null) return '${maxAge}세 이하';
    return '나이';
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = minAge != null || maxAge != null;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: const Text('나이 선택'),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(ctx).size.width > 400 ? 80 : 24,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AgeRangeSelector(
                  minAge: minAge,
                  maxAge: maxAge,
                  onChanged: (min, max) {
                    onChanged(min, max);
                  },
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('완료'),
              ),
            ],
          ),
        );
      },
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
              Icons.cake_outlined,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              _getDisplayText(),
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
    );
  }
}

class _LocationFilterChip extends StatelessWidget {
  final String? selectedLocation;
  final Function(String?) onChanged;

  const _LocationFilterChip({
    required this.selectedLocation,
    required this.onChanged,
  });

  Future<void> _showLocationPicker(BuildContext context) async {
    final result = await showDialog<Object?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: _LocationPickerSheet(
            initialSelected: selectedLocation,
            onSelected: (value) => Navigator.pop(
              ctx,
              value == null ? _locationClearSentinel : value,
            ),
          ),
        ),
      ),
    );
    if (context.mounted && result != null) {
      if (identical(result, _locationClearSentinel)) {
        onChanged(null);
      } else {
        onChanged(result as String);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedLocation != null;

    return GestureDetector(
      onTap: () => _showLocationPicker(context),
      child: _LocationFilterChipChild(
        isSelected: isSelected,
        selectedLocation: selectedLocation,
      ),
    );
  }
}

class _LocationFilterChipChild extends StatelessWidget {
  final bool isSelected;
  final String? selectedLocation;

  const _LocationFilterChipChild({
    required this.isSelected,
    required this.selectedLocation,
  });

  String _getDisplayText() {
    if (selectedLocation == null) return '지역';
    return selectedLocation!
        .replaceAll('특별시', '')
        .replaceAll('광역시', '')
        .replaceAll('특별자치시', '')
        .replaceAll('도', '')
        .replaceAll('특별자치도', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
              Icons.location_on_outlined,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              _getDisplayText(),
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
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final String? initialSelected;
  final void Function(String?) onSelected;

  const _LocationPickerSheet({
    this.initialSelected,
    required this.onSelected,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String? _selectedRegion;
  List<String> _subRegions = [];

  @override
  void initState() {
    super.initState();
  }

  void _onRegionTap(String region) {
    setState(() {
      _selectedRegion = region;
      _subRegions = List.from(RegionHierarchy.data[region] ?? []);
    });
  }

  void _onSubRegionTap(String subRegion) {
    final value = RegionHierarchy.toFilterValue(_selectedRegion!, subRegion);
    widget.onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    final topLevel = RegionHierarchy.topLevelRegions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '지역 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => widget.onSelected(null),
                  child: const Text('초기화'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // 1단계: 시/도
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: topLevel.length,
                    itemBuilder: (context, i) {
                      final region = topLevel[i];
                      final isSelected = _selectedRegion == region;
                      return ListTile(
                        title: Text(
                          region,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : null,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                        ),
                        selected: isSelected,
                        onTap: () => _onRegionTap(region),
                      );
                    },
                  ),
                ),
                // 2단계: 구/군/시
                Expanded(
                  child: _selectedRegion == null
                      ? Center(
                          child: Text(
                            '지역을 선택하세요',
                            style: TextStyle(
                              color: AppTheme.textTertiaryColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _subRegions.length,
                          itemBuilder: (context, i) {
                            final sub = _subRegions[i];
                            final filterValue = RegionHierarchy.toFilterValue(
                              _selectedRegion!,
                              sub,
                            );
                            final isSelected =
                                widget.initialSelected == filterValue;
                            return ListTile(
                              title: Text(sub),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () => _onSubRegionTap(sub),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onChanged;

  const _CategoryFilterChip({
    required this.selectedCategory,
    required this.onChanged,
  });

  String _getDisplayText() {
    if (selectedCategory == null) return '카테고리';
    final parsed = CategoryHierarchy.parse(selectedCategory);
    return parsed.sub ?? selectedCategory!;
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    final result = await CategoryPickerSheet.show(
      context,
      initial: selectedCategory,
    );
    if (!context.mounted) return;
    if (result != null) {
      if (identical(result, CategoryPickerSheet.categoryClearSentinel)) {
        onChanged(null);
      } else {
        onChanged(result as String);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedCategory != null;

    return GestureDetector(
      onTap: () => _showCategoryPicker(context),
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
              Icons.category_outlined,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              _getDisplayText(),
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

  Future<void> _showPicker(BuildContext context) async {
    final result = await showDialog<Object?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('방식'),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(ctx).size.width > 400 ? 80 : 24,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_rounded, size: 20),
              title: const Text('방식'),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.pop(ctx, _formatClearSentinel),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.videocam,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              title: const Text('온라인'),
              contentPadding: EdgeInsets.zero,
              trailing: selected == MeetingFormat.online
                  ? Icon(Icons.check, color: AppTheme.primaryColor, size: 20)
                  : null,
              onTap: () => Navigator.pop(ctx, MeetingFormat.online),
            ),
            ListTile(
              leading: Icon(
                Icons.location_on,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              title: const Text('오프라인'),
              contentPadding: EdgeInsets.zero,
              trailing: selected == MeetingFormat.offline
                  ? Icon(Icons.check, color: AppTheme.primaryColor, size: 20)
                  : null,
              onTap: () => Navigator.pop(ctx, MeetingFormat.offline),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('완료'),
          ),
        ],
      ),
    );
    if (context.mounted && result != null) {
      if (identical(result, _formatClearSentinel)) {
        onChanged(null);
      } else {
        onChanged(result as MeetingFormat);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selected != null;

    return GestureDetector(
      onTap: () => _showPicker(context),
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
    );
  }
}
