import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 홈 등에서 쓰는 이음터 브랜드 타이틀
class BrandTitle extends StatelessWidget {
  final double fontSize;

  const BrandTitle({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final markSize = fontSize * 0.78;

    return SizedBox(
      height: fontSize,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: markSize,
            height: markSize,
            child: CustomPaint(
              painter: _ConnectionMarkPainter(),
            ),
          ),
          SizedBox(width: fontSize * 0.28),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
                height: 1.0,
                leadingDistribution: TextLeadingDistribution.even,
              ),
              children: const [
                TextSpan(
                  text: '이음',
                  style: TextStyle(color: AppTheme.textPrimaryColor),
                ),
                TextSpan(
                  text: '터',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ],
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// 두 원이 맞닿아 ‘이음(연결)’을 표현하는 마크
class _ConnectionMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeW = size.width * 0.13;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.primaryColor;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primaryColor.withValues(alpha: 0.14);

    // stroke가 잘리지 않도록 반지름에 여유
    final r = (size.width / 2 - strokeW) * 0.52;
    final cy = size.height / 2;
    final left = Offset(size.width * 0.32, cy);
    final right = Offset(size.width * 0.68, cy);

    canvas.drawCircle(left, r, fill);
    canvas.drawCircle(right, r, fill);
    canvas.drawCircle(left, r, stroke);
    canvas.drawCircle(right, r, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
