/// 모임 카테고리 유틸 (카테고리 데이터는 서버 settings API에서 로드)
class CategoryHierarchy {
  /// 대분류 + 소분류 -> 저장용 전체 카테고리 문자열
  /// 예: "운동/액티비티 > 러닝"
  static String toFullCategory(String mainCategory, String subCategory) {
    return '$mainCategory > $subCategory';
  }

  /// 저장된 카테고리 문자열에서 대분류/소분류 파싱
  /// "대분류 > 소분류" 형식이면 파싱, 아니면 mainCategory=null, subCategory=원본
  static ({String? main, String? sub}) parse(String? category) {
    if (category == null || category.isEmpty) return (main: null, sub: null);
    final idx = category.indexOf(' > ');
    if (idx >= 0) {
      return (
        main: category.substring(0, idx),
        sub: category.substring(idx + 3),
      );
    }
    return (main: null, sub: category);
  }
}
