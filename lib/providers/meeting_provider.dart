import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting.dart';
import '../models/application.dart';
import '../services/api_service.dart';

class MeetingProvider with ChangeNotifier {
  List<Meeting> _meetings = [];
  List<Application> _applications = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // 필터 상태
  String? _selectedLocation;
  String? _selectedInterest;
  MeetingFormat? _selectedFormat;

  List<Meeting> get meetings => _meetings;
  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get selectedLocation => _selectedLocation;
  String? get selectedInterest => _selectedInterest;
  MeetingFormat? get selectedFormat => _selectedFormat;

  // 필터링된 모임 리스트
  List<Meeting> get filteredMeetings {
    var filtered = _meetings.where((m) => m.status == MeetingStatus.open);

    if (_selectedLocation != null) {
      filtered = filtered.where((m) => m.location == _selectedLocation);
    }

    if (_selectedInterest != null) {
      filtered = filtered.where((m) => m.interests.contains(_selectedInterest));
    }

    if (_selectedFormat != null) {
      filtered = filtered.where((m) => m.format == _selectedFormat);
    }

    return filtered.toList();
  }

  MeetingProvider() {
    // 인증 없이도 모임 목록 로드 가능
    loadMeetings();
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

  void setLocationFilter(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setInterestFilter(String? interest) {
    _selectedInterest = interest;
    notifyListeners();
  }

  void setFormatFilter(MeetingFormat? format) {
    _selectedFormat = format;
    notifyListeners();
  }

  void clearFilters() {
    _selectedLocation = null;
    _selectedInterest = null;
    _selectedFormat = null;
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
      debugPrint('🔵 [MeetingProvider] ApiService 생성');
      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('🔵 [MeetingProvider] Firebase 토큰 가져오기');
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          debugPrint('✅ [MeetingProvider] 토큰 설정 완료');
          apiService.setToken(token);
        } else {
          debugPrint('❌ [MeetingProvider] 토큰이 null');
        }
      } else {
        debugPrint('❌ [MeetingProvider] Firebase 사용자 없음');
      }

      debugPrint('🔵 [MeetingProvider] API 호출 시작');
      final application = await apiService.applyToMeeting(
        meetingId,
        answer1: answer1.isNotEmpty ? answer1 : null,
        answer2: answer2,
      );

      debugPrint('✅ [MeetingProvider] 신청 성공: ${application.id}');
      _applications.add(application);
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
      // Firebase 토큰이 있으면 설정 (선택사항)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          _apiService.setToken(token);
        }
      }

      // API에서 모임 목록 가져오기 (인증 없이도 가능)
      final meetings = await _apiService.getMeetings();

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
