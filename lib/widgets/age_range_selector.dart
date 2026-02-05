import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 모임 만들기/필터에서 사용하는 연령 범위 선택 위젯
class AgeRangeSelector extends StatefulWidget {
  final int? minAge;
  final int? maxAge;
  final Function(int?, int?) onChanged;

  const AgeRangeSelector({
    super.key,
    required this.minAge,
    required this.maxAge,
    required this.onChanged,
  });

  static const List<int> ageOptions = [20, 25, 30, 35, 40, 45, 50];

  @override
  State<AgeRangeSelector> createState() => _AgeRangeSelectorState();
}

class _AgeRangeSelectorState extends State<AgeRangeSelector> {
  late double _minValue;
  late double _maxValue;

  @override
  void initState() {
    super.initState();
    _updateValues();
  }

  void _updateValues() {
    _minValue = widget.minAge != null
        ? AgeRangeSelector.ageOptions
                .indexOf(widget.minAge!)
                .toDouble()
                .clamp(0, AgeRangeSelector.ageOptions.length - 1)
        : 0.0;
    _maxValue = widget.maxAge != null
        ? AgeRangeSelector.ageOptions
                .indexOf(widget.maxAge!)
                .toDouble()
                .clamp(0, AgeRangeSelector.ageOptions.length - 1)
        : (AgeRangeSelector.ageOptions.length - 1).toDouble();
  }

  @override
  void didUpdateWidget(AgeRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minAge != oldWidget.minAge ||
        widget.maxAge != oldWidget.maxAge) {
      _updateValues();
    }
  }

  String _getAgeLabel(int index) {
    if (index == AgeRangeSelector.ageOptions.length - 1) {
      return '50+';
    }
    return '${AgeRangeSelector.ageOptions[index]}';
  }

  String getRangeText() {
    if (_minValue == 0 &&
        _maxValue == AgeRangeSelector.ageOptions.length - 1) {
      return '누구나';
    }
    final minAge = AgeRangeSelector.ageOptions[_minValue.toInt()];
    final maxAge = AgeRangeSelector.ageOptions[_maxValue.toInt()];
    if (maxAge == 50) {
      return '$minAge세 ~ 50+세';
    }
    return '$minAge세 ~ $maxAge세';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '연령 범위',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getRangeText(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(AgeRangeSelector.ageOptions.length, (index) {
              return Expanded(
                child: Text(
                  _getAgeLabel(index),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        index >= _minValue.toInt() && index <= _maxValue.toInt()
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_minValue, _maxValue),
            min: 0,
            max: (AgeRangeSelector.ageOptions.length - 1).toDouble(),
            divisions: AgeRangeSelector.ageOptions.length - 1,
            labels: RangeLabels(
              _getAgeLabel(_minValue.toInt()),
              _getAgeLabel(_maxValue.toInt()),
            ),
            onChanged: (values) {
              setState(() {
                _minValue = values.start;
                _maxValue = values.end;
              });
              final minAge = AgeRangeSelector.ageOptions[_minValue.toInt()];
              final maxAge = AgeRangeSelector.ageOptions[_maxValue.toInt()];
              widget.onChanged(minAge, maxAge == 50 ? null : maxAge);
            },
          ),
        ],
      ),
    );
  }
}
