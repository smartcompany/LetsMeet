import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 피드 본문. 일반 텍스트·해시태그 모두 16, 해시태그는 강조색.
class FeedContentText extends StatelessWidget {
  final String content;

  const FeedContentText({super.key, required this.content});

  static final _hashtagPattern = RegExp(r'#[\w가-힣_]+');

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: AppTheme.textPrimaryColor,
    );
    final hashtagStyle = baseStyle.copyWith(
      color: AppTheme.primaryColor,
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    var start = 0;
    for (final match in _hashtagPattern.allMatches(content)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: content.substring(start, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(text: match.group(0), style: hashtagStyle));
      start = match.end;
    }
    if (start < content.length) {
      spans.add(TextSpan(text: content.substring(start), style: baseStyle));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: content, style: baseStyle));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
