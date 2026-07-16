import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letsmeet/screens/create_meeting_screen.dart';

void main() {
  testWidgets('AI 요청 팝업: 키보드가 올라와도 입력창이 화면 안에 보인다',
      (tester) async {
    // iPhone 급 논리 해상도
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (_) =>
                      const AiIntroductionRequestDialog(initialText: ''),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    // 키보드가 올라온 상태를 시뮬레이션 (높이 336px)
    const keyboardHeight = 336.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
    await tester.pumpAndSettle();

    final screenHeight = tester.view.physicalSize.height;
    final visibleBottom = screenHeight - keyboardHeight;
    final textFieldRect = tester.getRect(find.byType(TextField));

    // 입력창이 키보드 위 보이는 영역 안에 있어야 한다
    expect(textFieldRect.top, greaterThanOrEqualTo(0),
        reason: '입력창이 화면 위로 밀려나면 안 됨');
    expect(textFieldRect.bottom, lessThanOrEqualTo(visibleBottom),
        reason: '입력창이 키보드에 가려지면 안 됨');

    // 입력창이 찌그러져 사실상 안 보이는 상태(높이 0 근처)가 아니어야 한다
    expect(textFieldRect.height, greaterThan(40),
        reason: '입력창 높이가 정상적으로 확보되어야 함');

    // 버튼도 보이는 영역 안에 있어야 한다
    final buttonRect = tester.getRect(find.text('광고 보고 AI에게 요청'));
    expect(buttonRect.bottom, lessThanOrEqualTo(visibleBottom));
  });
}
