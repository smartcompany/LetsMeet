import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _thousandsFormat = NumberFormat('#,###', 'ko_KR');

/// 숫자 입력에 천 단위 콤마(,)를 붙입니다.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _thousandsFormat.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int parseThousands(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  return int.tryParse(value.replaceAll(',', '')) ?? 0;
}

String formatThousands(int value) {
  return _thousandsFormat.format(value);
}
