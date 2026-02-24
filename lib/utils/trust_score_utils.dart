/// 평점(trust_score) 표시 유틸
/// 백엔드는 0~100 점수로 관리, 사용자 화면에는 5점 만점으로 통일 (문토 등 참고)
class TrustScoreUtils {
  static const int _maxBackend = 100;
  static const double _maxDisplay = 5.0;

  /// 0~100 → 0~5 변환 (표시용)
  static double toDisplayRating(int trustScore) =>
      (trustScore / _maxBackend * _maxDisplay).clamp(0.0, _maxDisplay);

  /// 표시용 문자열 (예: "3.5")
  static String toDisplayString(int trustScore) =>
      toDisplayRating(trustScore).toStringAsFixed(1);

  /// API 등에서 오는 dynamic 값 파싱
  static int parse(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '70') ?? 70;
  }
}
