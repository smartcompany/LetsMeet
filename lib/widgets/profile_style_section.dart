import 'package:flutter/material.dart';
import '../models/user.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// 프로필 스타일 섹션
/// 제목 + 설정 버튼 + 선택된 텍스트 목록
class ProfileStyleSection extends StatelessWidget {
  final String sectionTitle;
  final String? lifeSceneText;
  final String? selfStatementText;
  final String? interactionStyleText;
  final VoidCallback? onSettingsTap;
  final bool showSettingsButton;

  const ProfileStyleSection({
    super.key,
    required this.sectionTitle,
    this.lifeSceneText,
    this.selfStatementText,
    this.interactionStyleText,
    this.onSettingsTap,
    this.showSettingsButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final texts = <String>[];
    if (lifeSceneText != null && lifeSceneText!.isNotEmpty) texts.add(lifeSceneText!);
    if (selfStatementText != null && selfStatementText!.isNotEmpty) {
      texts.add(selfStatementText!);
    }
    if (interactionStyleText != null && interactionStyleText!.isNotEmpty) {
      texts.add(interactionStyleText!);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              if (showSettingsButton)
                TextButton(
                  onPressed: onSettingsTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('변경'),
                ),
            ],
          ),
          if (texts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...texts.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 설정 버튼 탭 시 스타일 선택 시트 표시 (한 화면에서 모두 선택)
  static void showStylePickerSheet(
    BuildContext context, {
    User? user,
    String? lifeSceneId,
    String? selfStatementId,
    String? interactionStyleId,
    required ProfileStyleOptions opts,
    required Future<void> Function({
      String? lifeSceneId,
      String? selfStatementId,
      String? interactionStyleId,
    }) onUpdate,
    VoidCallback? onUpdated,
  }) {
    final initialLifeSceneId = lifeSceneId ?? user?.lifeSceneId;
    final initialSelfStatementId = selfStatementId ?? user?.selfStatementId;
    final initialInteractionStyleId = interactionStyleId ?? user?.interactionStyleId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _StylePickerSheetContent(
        opts: opts,
        initialLifeSceneId: initialLifeSceneId,
        initialSelfStatementId: initialSelfStatementId,
        initialInteractionStyleId: initialInteractionStyleId,
        onUpdate: onUpdate,
        onUpdated: onUpdated,
      ),
    );
  }
}

class _StylePickerSheetContent extends StatefulWidget {
  final ProfileStyleOptions opts;
  final String? initialLifeSceneId;
  final String? initialSelfStatementId;
  final String? initialInteractionStyleId;
  final Future<void> Function({
    String? lifeSceneId,
    String? selfStatementId,
    String? interactionStyleId,
  }) onUpdate;
  final VoidCallback? onUpdated;

  const _StylePickerSheetContent({
    required this.opts,
    required this.initialLifeSceneId,
    required this.initialSelfStatementId,
    required this.initialInteractionStyleId,
    required this.onUpdate,
    this.onUpdated,
  });

  @override
  State<_StylePickerSheetContent> createState() => _StylePickerSheetContentState();
}

class _StylePickerSheetContentState extends State<_StylePickerSheetContent> {
  late String? _lifeSceneId;
  late String? _selfStatementId;
  late String? _interactionStyleId;

  @override
  void initState() {
    super.initState();
    _lifeSceneId = widget.initialLifeSceneId;
    _selfStatementId = widget.initialSelfStatementId;
    _interactionStyleId = widget.initialInteractionStyleId;
  }

  Future<void> _apply({
    String? lifeSceneId,
    String? selfStatementId,
    String? interactionStyleId,
  }) async {
    await widget.onUpdate(
      lifeSceneId: lifeSceneId ?? _lifeSceneId,
      selfStatementId: selfStatementId ?? _selfStatementId,
      interactionStyleId: interactionStyleId ?? _interactionStyleId,
    );
    widget.onUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '스타일 수정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('좋아하는 시간'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.opts.lifeScenes.map((opt) {
                        final isSelected = _lifeSceneId == opt.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _lifeSceneId = opt.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('중요한 포인트'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.opts.selfStatements.map((opt) {
                        final isSelected = _selfStatementId == opt.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selfStatementId = isSelected ? null : opt.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('같이 있으면'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.opts.interactionStyles.map((opt) {
                        final isSelected = _interactionStyleId == opt.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _interactionStyleId = opt.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _apply();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}
