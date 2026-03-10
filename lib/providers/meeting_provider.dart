import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting.dart';
import '../models/application.dart';
import '../services/api_service.dart';
import '../utils/category_hierarchy.dart';
import '../utils/region_hierarchy.dart';
import '../app_auth_provider.dart';

class MeetingProvider with ChangeNotifier {
  MeetingProvider._();
  static final MeetingProvider shared = MeetingProvider._();

  List<Meeting> _meetings = [];
  List<Application> _applications = [];
  bool _isLoading = false;

  // 필터 상태
  int? _selectedAgeMin;
  int? _selectedAgeMax;
  String? _selectedLocation;
  String? _selectedCategory;
  MeetingFormat? _selectedFormat;
  bool _showMyMeetingsOnly = false;

  // 검색
  String _searchQuery = '';

  // 찜 (로컬 저장)
  Set<String> _favoriteIds = {};
  bool _showFavoritesOnly = false;

  static const String _favoritesKey = 'meeting_favorite_ids';

  List<Meeting> get meetings => _meetings;
  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  int? get selectedAgeMin => _selectedAgeMin;
  int? get selectedAgeMax => _selectedAgeMax;
  String? get selectedLocation => _selectedLocation;
  String? get selectedCategory => _selectedCategory;
  MeetingFormat? get selectedFormat => _selectedFormat;
  bool get showMyMeetingsOnly => _showMyMeetingsOnly;
  String get searchQuery => _searchQuery;
  bool get showFavoritesOnly => _showFavoritesOnly;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String meetingId) => _favoriteIds.contains(meetingId);

  // 필터링된 모임 리스트
  List<Meeting> get filteredMeetings {
    var filtered = _meetings.where((m) => m.status == MeetingStatus.open);

    if (_selectedAgeMin != null || _selectedAgeMax != null) {
      filtered = filtered.where((m) {
        final min = m.ageRangeMin;
        final max = m.ageRangeMax;
        if (min == null && max == null) return true;
        final filterMin = _selectedAgeMin ?? 0;
        final filterMax = _selectedAgeMax ?? 999;
        if (min != null && max != null) {
          return !(max < filterMin || min > filterMax);
        }
        if (min != null && min > filterMax) return false;
        if (max != null && max < filterMin) return false;
        return true;
      });
    }

    if (_selectedLocation != null) {
      filtered = filtered.where((m) {
        return RegionHierarchy.locationMatches(m.location, _selectedLocation!);
      });
    }

    if (_selectedCategory != null) {
      filtered = filtered
          .where((m) => _categoryMatches(m.category, _selectedCategory!));
    }

    if (_selectedFormat != null) {
      filtered = filtered.where((m) => m.format == _selectedFormat);
    }

    if (_showMyMeetingsOnly) {
      final uid = AppAuthProvider.shared.userProfile?.id;
      if (uid == null) return [];
      filtered = filtered.where((m) {
        final isHost = m.hostId == uid;
        if (isHost) {
          debugPrint(
            '[MyMeetingsFilter] include(host): meetingId=${m.id}, uid=$uid',
          );
          return true;
        }

        final isParticipant =
            m.participants?.any((p) => p.userId == uid) == true;
        if (isParticipant) {
          debugPrint(
            '[MyMeetingsFilter] include(participant): meetingId=${m.id}, uid=$uid',
          );
          return true;
        }

        final app = m.userApplication;
        if (app == null) {
          debugPrint(
            '[MyMeetingsFilter] exclude(no-application): meetingId=${m.id}, uid=$uid',
          );
          return false;
        }

        final status = app['status']?.toString();
        if (status == null || status.isEmpty) {
          debugPrint(
            '[MyMeetingsFilter] include(app-status-empty): meetingId=${m.id}, uid=$uid',
          );
          return true;
        }

        // 대기중·승인됨·거절됨 모두 표시 (신청에 대한 상태 노출)
        final isAllowed =
            status == 'pending' || status == 'approved' || status == 'rejected';
        debugPrint(
          '[MyMeetingsFilter] ${isAllowed ? "include" : "exclude"}(app-status=$status): meetingId=${m.id}, uid=$uid',
        );
        return isAllowed;
      });
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((m) {
        if (m.title.toLowerCase().contains(q)) return true;
        if (m.description?.toLowerCase().contains(q) ?? false) return true;
        if (m.shortDescription?.toLowerCase().contains(q) ?? false) return true;
        if (m.location.toLowerCase().contains(q)) return true;
        if (m.interests.any((i) => i.toLowerCase().contains(q))) return true;
        if (m.category?.toLowerCase().contains(q) ?? false) return true;
        return false;
      });
    }

    if (_showFavoritesOnly) {
      filtered = filtered.where((m) => _favoriteIds.contains(m.id));
    }

    return filtered.toList();
  }

  /// 찜 목록을 로컬(SharedPreferences)에서 불러옵니다. 외부에서 필요 시 호출.
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favoritesKey);
      _favoriteIds = list != null ? list.toSet() : {};
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setShowFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
    notifyListeners();
  }

  Future<void> toggleFavorite(String meetingId) async {
    if (_favoriteIds.contains(meetingId)) {
      _favoriteIds.remove(meetingId);
    } else {
      _favoriteIds.add(meetingId);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Meeting? getMeetingById(String id) {
    try {
      return _meetings.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Application? getApplicationByMeetingId(String meetingId, String userId) {
    try {
      return _applications.firstWhere(
        (a) => a.meetingId == meetingId && a.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  void setAgeRangeFilter(int? min, int? max) {
    _selectedAgeMin = min;
    _selectedAgeMax = max;
    notifyListeners();
  }

  /// 선택 카테고리가 "Main > 전체"이면 메인 카테고리만 매칭, 아니면 정확 매칭
  bool _categoryMatches(String? meetingCategory, String selectedCategory) {
    if (meetingCategory == null || meetingCategory.isEmpty) return false;
    final selected = CategoryHierarchy.parse(selectedCategory);
    if (selected.sub == '전체') {
      final meeting = CategoryHierarchy.parse(meetingCategory);
      return meeting.main == selected.main;
    }
    return meetingCategory == selectedCategory;
  }

  void setLocationFilter(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setFormatFilter(MeetingFormat? format) {
    _selectedFormat = format;
    notifyListeners();
  }

  void setShowMyMeetingsOnly(bool value) {
    _showMyMeetingsOnly = value;
    notifyListeners();
  }

  void clearFilters() {
    _selectedAgeMin = null;
    _selectedAgeMax = null;
    _selectedLocation = null;
    _selectedCategory = null;
    _selectedFormat = null;
    _showMyMeetingsOnly = false;
    notifyListeners();
  }

  Future<void> applyToMeeting(
    String meetingId,
    String userId,
    String answer1,
    String? answer2,
  ) async {
    debugPrint('🔵 [MeetingProvider] 신청 시작');
    debugPrint('🔵 [MeetingProvider] 모임 ID: $meetingId');
    debugPrint('🔵 [MeetingProvider] 사용자 ID: $userId');
    debugPrint(
      '🔵 [MeetingProvider] 답변1: ${answer1.isNotEmpty ? "${answer1.substring(0, answer1.length > 50 ? 50 : answer1.length)}..." : "없음"}',
    );
    debugPrint('🔵 [MeetingProvider] 답변2: ${answer2 ?? "없음"}');

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔵 [MeetingProvider] ApiService 호출 준비');

      debugPrint('🔵 [MeetingProvider] API 호출 시작');
      final application = await ApiService.shared.applyToMeeting(
        meetingId,
        answer1: answer1.isNotEmpty ? answer1 : null,
        answer2: answer2,
      );

      debugPrint('✅ [MeetingProvider] 신청 성공: ${application.id}');
      _applications.add(application);
      await loadMeetings(); // 내 모임 필터에 user_application 반영
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ [MeetingProvider] 신청 에러 발생');
      debugPrint('❌ [MeetingProvider] 에러 타입: ${e.runtimeType}');
      debugPrint('❌ [MeetingProvider] 에러 메시지: $e');
      debugPrint('❌ [MeetingProvider] 스택 트레이스: $stackTrace');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadMeetings() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Firebase 토큰이 있으면 설정 (선택사항) — 현재는 AppAuthProvider에서 최초 한 번만 설정
      // API에서 모임 목록 가져오기 (인증 없이도 가능)
      final meetings = await ApiService.shared.getMeetings();

      _meetings = meetings;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [MeetingProvider] 모임 목록 로드 실패: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
