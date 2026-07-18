import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:share_lib/share_lib.dart';
import '../services/api_service.dart'; // baseUrl용

/// http 패키지는 Content-Type에 charset이 없으면 latin1로 디코딩함.
/// 서버 JSON은 UTF-8이므로 bodyBytes를 UTF-8로 읽는다.
dynamic _decodeJsonResponse(http.Response response) {
  return jsonDecode(utf8.decode(response.bodyBytes));
}

/// 프로필 스타일 옵션 (서버 settings.json)
class ProfileStyleOptions {
  final String description;
  final List<ProfileStyleOption> lifeScenes;
  final List<ProfileStyleOption> selfStatements;
  final List<ProfileStyleOption> interactionStyles;

  ProfileStyleOptions({
    this.description = '나를 설명하면 이런 편이에요',
    required this.lifeScenes,
    required this.selfStatements,
    required this.interactionStyles,
  });

  factory ProfileStyleOptions.fromJson(Map<String, dynamic> json) {
    return ProfileStyleOptions(
      description: json['description'] as String? ?? '나를 설명하면 이런 편이에요',
      lifeScenes: _parseList(json['life_scenes']),
      selfStatements: _parseList(json['self_statements']),
      interactionStyles: _parseList(json['interaction_styles']),
    );
  }

  static List<ProfileStyleOption> _parseList(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
        .whereType<Map<String, dynamic>>()
        .map((e) => ProfileStyleOption.fromJson(e))
        .toList();
  }
}

class ProfileStyleOption {
  final String id;
  final String text;

  ProfileStyleOption({
    required this.id,
    required this.text,
  });

  factory ProfileStyleOption.fromJson(Map<String, dynamic> json) {
    return ProfileStyleOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

/// 앱 설정 (서버 드리븐)
/// - meetingCategory: 모임 카테고리 계층
/// - 광고: AdService에 전달 (ios_ad, android_ad, ref, down_load_url 등)
class SettingsProvider extends ChangeNotifier {
  SettingsProvider._();
  static final SettingsProvider shared = SettingsProvider._();

  /// 서버에서 받은 meetingCategory (대분류 -> 소분류 목록)
  Map<String, List<String>>? _meetingCategory;
  Map<String, List<String>>? get meetingCategory => _meetingCategory;

  /// 프로필 스타일 옵션 (좋아하는 시간, 중요한 포인트, 같이 있으면)
  ProfileStyleOptions? _profileStyleOptions;
  ProfileStyleOptions? get profileStyleOptions => _profileStyleOptions;

  /// 금지어 목록 (현재는 사용 안 함. 피드/댓글 금지어는 서버 API에서 검사)
  List<String> get bannedWords => [];

  bool _loaded = false;
  bool get loaded => _loaded;

  String? _loadError;
  String? get loadError => _loadError;

  /// settings base URL (api 경로 제외)
  static String get _settingsBaseUrl {
    final base = ApiService.baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  /// 앱 시작 시 설정 로드
  /// - meetingCategory 파싱
  /// - AdService baseUrl 설정 및 loadSettings 호출
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;

    try {
      final uri = Uri.parse('$_settingsBaseUrl/api/settings');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        _loadError = '설정 로드 실패: ${response.statusCode}';
        notifyListeners();
        return;
      }

      final data = _decodeJsonResponse(response) as Map<String, dynamic>;

      // meetingCategory 파싱
      // 형식: { "key": { "main": "대분류 표시명", "sub": ["소분류", ...] } }
      final raw = data['meetingCategory'];
      if (raw is Map) {
        _meetingCategory = {};
        for (final e in raw.entries) {
          final val = e.value;
          if (val is Map) {
            final main = val['main']?.toString();
            final subRaw = val['sub'];
            if (main != null && main.isNotEmpty && subRaw is List) {
              _meetingCategory![main] = subRaw
                  .map((v) => v?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          }
        }
      }

      // profileStyleOptions 파싱
      final styleRaw = data['profileStyleOptions'];
      if (styleRaw is Map) {
        _profileStyleOptions = ProfileStyleOptions.fromJson(
          styleRaw as Map<String, dynamic>,
        );
      }

      // 설정 로드 완료 (meetingCategory, profileStyleOptions) - 웹/모바일 공통
      _loaded = true;
      _loadError = null;
      notifyListeners();

      // AdService 광고 로드 (웹에서는 loadSettings() 내부에서 스킵, 예외 없음)
      AdService.shared.setBaseUrl(_settingsBaseUrl);
      await AdService.shared.loadSettings();
    } catch (e, st) {
      debugPrint('❌ [SettingsProvider] load error: $e');
      debugPrint('$st');
      _loadError = e.toString();
      notifyListeners();
    }
  }
}
