import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/category_hierarchy.dart';
import '../providers/settings_provider.dart';

/// 모임 카테고리 선택 팝업 (대분류 -> 소분류 2단계)
class CategoryPickerSheet extends StatefulWidget {
  final String? initialCategory;
  final void Function(String?) onSelected;

  const CategoryPickerSheet({
    super.key,
    this.initialCategory,
    required this.onSelected,
  });

  /// 초기화 선택 시 반환되는 값 (호출처에서 null로 처리)
  static const categoryClearSentinel = Object();

  /// 팝업으로 카테고리 선택 표시
  /// 반환: 선택된 카테고리 문자열, 초기화시 categoryClearSentinel, 취소시 null
  static Future<Object?> show(BuildContext context, {String? initial}) async {
    return showDialog<Object?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: CategoryPickerSheet(
            initialCategory: initial,
            onSelected: (value) => Navigator.pop(
              ctx,
              value ?? categoryClearSentinel,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String? _selectedMain;
  List<String> _subCategories = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = SettingsProvider.shared.meetingCategory;
    if (data == null) return;
    final parsed = CategoryHierarchy.parse(widget.initialCategory);
    if (parsed.main != null && data.containsKey(parsed.main)) {
      if (_selectedMain != parsed.main) {
        _selectedMain = parsed.main;
        _subCategories = List.from(data[_selectedMain!] ?? []);
      }
    }
  }

  void _onMainTap(BuildContext context, String mainCat) {
    final data = SettingsProvider.shared.meetingCategory;
    if (data == null) return;
    setState(() {
      _selectedMain = mainCat;
      _subCategories = List.from(data[mainCat] ?? []);
    });
  }

  void _onSubTap(String subCat) {
    final value = CategoryHierarchy.toFullCategory(_selectedMain!, subCat);
    widget.onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsProvider.shared,
      builder: (context, _) {
        final data = SettingsProvider.shared.meetingCategory;
    if (data == null || data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '카테고리를 불러올 수 없습니다',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    final mainCats = data.keys.toList();

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
                  '모임 카테고리',
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
                Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: mainCats.length,
                    itemBuilder: (context, i) {
                      final main = mainCats[i];
                      final isSelected = _selectedMain == main;
                      return ListTile(
                        title: Text(
                          main,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : null,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                        ),
                        selected: isSelected,
                        onTap: () => _onMainTap(context, main),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _selectedMain == null
                      ? Center(
                          child: Text(
                            '대분류를 선택하세요',
                            style: TextStyle(
                              color: AppTheme.textTertiaryColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _subCategories.length,
                          itemBuilder: (context, i) {
                            final sub = _subCategories[i];
                            final fullCat =
                                CategoryHierarchy.toFullCategory(
                                  _selectedMain!,
                                  sub,
                                );
                            final isSelected =
                                widget.initialCategory == fullCat;
                            return ListTile(
                              title: Text(sub),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () => _onSubTap(sub),
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
      },
    );
  }
}

