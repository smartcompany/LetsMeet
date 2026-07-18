import 'package:flutter/material.dart';

/// 스타일 문구를 시뮬레이터/실기기 모두에서 안정적으로 표시합니다.
///
/// iOS 시뮬레이터(특히 신규 런타임)에서는 Apple Color Emoji 글리프가
/// 비어 �로 나오고, 이모지+한글이 한 Text에 있으면 줄 전체가 깨질 수 있습니다.
/// 선두 이모지는 컬러 Material 아이콘으로, 한글은 별도 Text로 그립니다.
class ProfileStyleText extends StatelessWidget {
  const ProfileStyleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  static const Map<String, (IconData, Color)> _iconStyles = {
    '☕': (Icons.local_cafe_rounded, Color(0xFF8D6E63)),
    '🌿': (Icons.eco_rounded, Color(0xFF43A047)),
    '🏃': (Icons.directions_run_rounded, Color(0xFFFB8C00)),
    '✈️': (Icons.flight_rounded, Color(0xFF1E88E5)),
    '🏠': (Icons.home_rounded, Color(0xFF5C6BC0)),
    '🎉': (Icons.celebration_rounded, Color(0xFFE53935)),
    '🧳': (Icons.luggage_rounded, Color(0xFF6D4C41)),
    '💬': (Icons.chat_bubble_rounded, Color(0xFF42A5F5)),
    '😌': (Icons.sentiment_satisfied_alt_rounded, Color(0xFFFFB300)),
    '🔥': (Icons.local_fire_department_rounded, Color(0xFFFF5722)),
    '🕊': (Icons.air_rounded, Color(0xFF78909C)),
    '🎯': (Icons.gps_fixed_rounded, Color(0xFFE53935)),
    '🤍': (Icons.favorite_rounded, Color(0xFFEC407A)),
    '⚡': (Icons.bolt_rounded, Color(0xFFFDD835)),
    '🙋': (Icons.waving_hand_rounded, Color(0xFFFFA726)),
    '👂': (Icons.hearing_rounded, Color(0xFF8D6E63)),
    '📅': (Icons.calendar_month_rounded, Color(0xFF5C6BC0)),
    '🐢': (Icons.pets_rounded, Color(0xFF66BB6A)),
    '📵': (Icons.phonelink_erase_rounded, Color(0xFF757575)),
    '😄': (Icons.mood_rounded, Color(0xFFFFCA28)),
  };

  static (IconData, Color, String)? _parse(String value) {
    final separator = value.indexOf(' ');
    if (separator <= 0) return null;
    final prefix = value.substring(0, separator);
    final label = value.substring(separator + 1);
    final style = _iconStyles[prefix];
    if (style == null) return null;
    return (style.$1, style.$2, label);
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parse(text);
    if (parsed == null) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final (icon, color, label) = parsed;
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final fontSize = effectiveStyle.fontSize ?? 14;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: textAlign == TextAlign.center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: fontSize + 4, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: effectiveStyle,
            textAlign: textAlign,
          ),
        ),
      ],
    );
  }
}
