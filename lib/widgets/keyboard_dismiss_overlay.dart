import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 키보드가 올라올 때 상단에 키보드 내리기 액세서리 바를 표시합니다.
class KeyboardDismissOverlay extends StatefulWidget {
  const KeyboardDismissOverlay({super.key, required this.child});

  final Widget child;

  static const barHeight = 44.0;

  @override
  State<KeyboardDismissOverlay> createState() => _KeyboardDismissOverlayState();
}

class _KeyboardDismissOverlayState extends State<KeyboardDismissOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_scheduleRebuild);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_scheduleRebuild);
    super.dispose();
  }

  void _scheduleRebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return false;

    final focusContext = focus.context;
    if (focusContext == null) return false;

    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final showBar = keyboardInset > 0 && _isTextInputFocused();
    final screenWidth = mediaQuery.size.width;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaQuery(
            data: mediaQuery.copyWith(
              viewInsets: mediaQuery.viewInsets.copyWith(
                bottom: showBar
                    ? keyboardInset + KeyboardDismissOverlay.barHeight
                    : keyboardInset,
              ),
            ),
            child: widget.child,
          ),
          if (showBar)
            Positioned(
              left: 0,
              width: screenWidth,
              bottom: keyboardInset,
              child: _KeyboardDismissBar(onDismiss: _dismissKeyboard),
            ),
        ],
      ),
    );
  }
}

class _KeyboardDismissBar extends StatelessWidget {
  const _KeyboardDismissBar({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: AppTheme.surfaceColor,
      child: Container(
        width: double.infinity,
        height: KeyboardDismissOverlay.barHeight,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.dividerColor),
            bottom: BorderSide(color: AppTheme.dividerColor),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 4),
        child: InkWell(
          onTap: onDismiss,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.keyboard_hide_outlined,
              size: 28,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
