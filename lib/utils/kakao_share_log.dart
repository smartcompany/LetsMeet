import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 카카오 shareDefault 결과 URI 디버그.
/// template_id 5793(TextTemplate)은 플랫폼별 URL 슬롯이 여러 개라,
/// 첫 번째 URL만 찍으면 Product Link 기본 도메인(lime)이 실제 버튼 링크처럼 보일 수 있음.
void logKakaoShareDefaultUri(Uri uri, {Uri? requestedLinkUrl}) {
  final buffer = StringBuffer('[KakaoShare] shareDefault 완료\n');
  buffer.writeln('  template_id: ${uri.queryParameters['template_id'] ?? '-'}');
  buffer.writeln(
    '  requestedLinkUrl: ${requestedLinkUrl?.toString() ?? '(없음)'}',
  );

  final templateArgsRaw = uri.queryParameters['template_args'];
  if (templateArgsRaw == null || templateArgsRaw.isEmpty) {
    debugPrint(buffer.toString());
    return;
  }

  try {
    final decoded = jsonDecode(templateArgsRaw) as Map<String, dynamic>;
    final urlSlots = <String, String>{};
    String? buttonTitle;

    for (final entry in decoded.entries) {
      final key = entry.key;
      final value = entry.value?.toString() ?? '';
      if (value.isEmpty) continue;

      if ((key.contains('URL') || key.contains('url')) &&
          value.startsWith('http')) {
        urlSlots[key] = value;
      } else if (key == r'${FIRST_BUTTON_TITLE}') {
        buttonTitle = value;
      }
    }

    if (urlSlots.isEmpty) {
      buffer.writeln('  templateUrlSlots: (없음)');
    } else {
      buffer.writeln('  templateUrlSlots:');
      for (final entry in urlSlots.entries) {
        buffer.writeln('    ${entry.key}: ${entry.value}');
      }
    }

    if (buttonTitle != null) {
      buffer.writeln('  buttonTitle: $buttonTitle');
    }

    buffer.writeln(
      '  note: 버튼 클릭 링크는 requestedLinkUrl 기준. '
      'templateUrlSlots의 lime 도메인은 Product Link 기본 웹 도메인일 수 있음.',
    );
  } catch (error) {
    buffer.writeln('  template_args decode 실패: $error');
  }

  debugPrint(buffer.toString());
}
