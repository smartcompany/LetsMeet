import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../models/meeting.dart';
import '../models/application.dart';
import '../models/feed.dart';
import '../models/feed_comment.dart';

/// API 검증 에러 (금지어 등). 필드별 에러 표시용.
class ApiValidationException implements Exception {
  final String message;
  final String? field;
  ApiValidationException(this.message, {this.field});
  @override
  String toString() => message;
}

class ApiService implements AuthServiceInterface {
  static ApiService? _instance;

  /// 싱글턴. 앱 전역에서 ApiService.shared 로 접근.
  static ApiService get shared {
    _instance ??= ApiService._();
    return _instance!;
  }

  ApiService._();

  // Production server URL
  static String get baseUrl {
    return 'https://lets-meet-server.vercel.app/api';
  }

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Social login APIs
  // 카카오 로그인 후 UID와 kakao_id 받기
  @override
  Future<Map<String, String>> loginWithKakao(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kakao/firebase'),
        headers: _headers,
        body: jsonEncode({'access_token': accessToken}),
      );
      if (response.statusCode != 200) {
        print('❌ [ApiService] 서버 응답 상태: ${response.statusCode}');
        print('❌ [ApiService] 서버 응답 본문: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['error'] ?? 'Failed to login with Kakao';
          print('❌ [ApiService] 파싱된 에러 메시지: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception &&
              e.toString().contains('Failed to login with Kakao')) {
            rethrow;
          }
          print('❌ [ApiService] JSON 파싱 실패, 원본 응답: ${response.body}');
          throw Exception(
            'Failed to login with Kakao: ${response.statusCode}\nResponse: ${response.body}',
          );
        }
      }
      final data = jsonDecode(response.body);
      final result = {
        'uid': data['uid'] as String,
        'kakao_id': data['kakao_id'] as String,
      };

      // 프로필이 이미 있으면 custom_token도 포함
      if (data['custom_token'] != null) {
        result['custom_token'] = data['custom_token'] as String;
      }

      return result;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('카카오 로그인에 실패했습니다.');
    }
  }

  // User APIs
  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      }
      if (response.statusCode == 404) {
        // 프로필 설정이 완료되지 않은 경우 (FaceReader 방식)
        throw Exception('PROFILE_NOT_SETUP');
      }
      throw Exception('Failed to get user');
    }
    return User.fromJson(jsonDecode(response.body));
  }

  /// 계정 탈퇴 (App Store Guideline 5.1.1(v) - 계정 생성 시 계정 삭제 제공)
  Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      String message = '계정 탈퇴에 실패했습니다.';
      final body = response.body.trim();
      if (body.isNotEmpty) {
        try {
          final data = jsonDecode(body) as Map<String, dynamic>?;
          if (data?['error'] != null) message = data!['error'] as String;
        } catch (_) {}
      }
      throw Exception(message);
    }
  }

  /// 프로필 업데이트 (앱 전용 - AuthServiceInterface에는 없음)
  Future<dynamic> updateProfile({
    String? fullName,
    String? gender,
    String? bio,
    String? profileImageUrl,
    String? backgroundImageUrl,
    String? lifeSceneId,
    String? selfStatementId,
    String? interactionStyleId,
    String? kakaoId, // 카카오 로그인인 경우
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({
        if (fullName != null) 'full_name': fullName,
        if (gender != null) 'gender': gender,
        if (bio != null) 'bio': bio,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        if (backgroundImageUrl != null)
          'background_image_url': backgroundImageUrl,
        if (lifeSceneId != null) 'life_scene_id': lifeSceneId,
        if (selfStatementId != null) 'self_statement_id': selfStatementId,
        if (interactionStyleId != null)
          'interaction_style_id': interactionStyleId,
        if (kakaoId != null) 'kakao_id': kakaoId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
    final data = jsonDecode(response.body);

    // 카카오 로그인이고 새 사용자인 경우 custom_token이 포함된 Map 반환
    // 그 외의 경우 User 객체 반환
    if (data['custom_token'] != null) {
      return data; // Map 반환 (custom_token 포함)
    }

    return User.fromJson(data);
  }

  /// 다른 사용자 공개 프로필 조회 (채팅 등에서 사용)
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final body = response.body;
      Object? err;
      if (body.isNotEmpty) {
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>?;
          err = decoded?['error'];
        } catch (_) {}
      }
      final suffix = err != null ? ': $err' : '';
      throw Exception('HTTP ${response.statusCode}$suffix (userId=$userId)');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 호스트인 모임별 pending 신청 수 조회
  Future<Map<String, int>> getPendingApplicationCounts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/pending-application-counts'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      return {};
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// 채팅 새 메시지 푸시 알림 요청 (수신자에게 푸시 전송)
  Future<void> notifyChatMessage({
    required List<String> recipientUserIds,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (recipientUserIds.isEmpty) return;
    final response = await http.post(
      Uri.parse('$baseUrl/chat/notify'),
      headers: _headers,
      body: jsonEncode({
        'recipient_user_ids': recipientUserIds,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      }),
    );
    if (response.statusCode != 200) {
      debugPrint('[ApiService] Chat notify failed: ${response.statusCode}');
    }
  }

  /// AI 모임 소개 문구 다듬기 (광고 시청 후 호출)
  /// [content] 모임 소개 입력창에 사용자가 작성한 내용
  Future<String> generateMeetingIntroduction({required String content}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/meeting-introduction'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? '모임 소개 생성에 실패했습니다.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['introduction'] as String;
  }

  /// 사용자 설정 조회 (채팅 푸시 on/off 등)
  Future<Map<String, dynamic>> getMySettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/settings'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      return {'chat_push_enabled': true};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 채팅 푸시 알림 설정 업데이트
  Future<void> updateChatPushEnabled(bool enabled) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/settings'),
      headers: _headers,
      body: jsonEncode({'chat_push_enabled': enabled}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update chat push setting');
    }
  }

  /// FCM 토큰 저장 (푸시 알림용)
  Future<void> saveFcmToken(String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/fcm-token'),
      headers: _headers,
      body: jsonEncode({'fcm_token': token}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save FCM token');
    }
  }

  /// 프로필 이미지 업로드 (Supabase Storage 경유)
  Future<String> uploadProfileImage(File file) async {
    final uri = Uri.parse('$baseUrl/users/me/profile-image');
    final request = http.MultipartRequest('POST', uri);

    // JSON Content-Type은 MultipartRequest가 알아서 설정하므로 추가하지 않음
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception('Failed to upload profile image');
    }

    final data = jsonDecode(responseBody);
    return data['url'] as String;
  }

  /// 배경 이미지 업로드 (Supabase Storage 경유)
  Future<String> uploadBackgroundImage(File file) async {
    final uri = Uri.parse('$baseUrl/users/me/background-image');
    debugPrint('🟡 [ApiService] 배경 업로드 요청: $uri');
    debugPrint('🟡 [ApiService] 파일: ${file.path}, size=${file.lengthSync()} bytes');
    debugPrint('🟡 [ApiService] 토큰: ${_token != null ? "있음" : "없음"}');

    final request = http.MultipartRequest('POST', uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    debugPrint('🟡 [ApiService] 배경 업로드 응답: status=${streamedResponse.statusCode}, body=$responseBody');

    if (streamedResponse.statusCode != 200) {
      debugPrint('❌ [ApiService] 배경 업로드 실패: status=${streamedResponse.statusCode}');
      throw Exception(
        '배경 업로드 실패 (${streamedResponse.statusCode}): $responseBody',
      );
    }

    final data = jsonDecode(responseBody);
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      debugPrint('❌ [ApiService] 응답에 url 없음: $data');
      throw Exception('응답에 url이 없습니다: $data');
    }
    return url;
  }

  // Meeting APIs
  Future<List<Meeting>> getMeetings({
    List<String>? interests,
    String? hostId,
    String? applicantId,
    bool includeCompleted = false,
  }) async {
    final queryParams = <String>[];
    if (interests != null && interests.isNotEmpty) {
      queryParams.add('interests=${interests.join(',')}');
    }
    if (hostId != null) {
      queryParams.add('host_id=$hostId');
    }
    if (applicantId != null) {
      queryParams.add('applicant_id=$applicantId');
    }
    if (includeCompleted) {
      queryParams.add('include_completed=true');
    }

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.join('&')}'
        : '';
    final response = await http.get(
      Uri.parse('$baseUrl/meetings$queryString'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get meetings');
    }
    final data = jsonDecode(response.body);
    return (data as List).map((e) => Meeting.fromJson(e)).toList();
  }

  Future<Meeting> getMeeting(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/meetings/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get meeting');
    }
    return Meeting.fromJson(jsonDecode(response.body));
  }

  Future<String> uploadMeetingImage(XFile xFile) async {
    final uri = Uri.parse('$baseUrl/meetings/upload');
    final request = http.MultipartRequest('POST', uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    final bytes = await xFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: xFile.name,
    ));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      final errorBody = jsonDecode(responseBody);
      throw Exception(errorBody['error'] ?? 'Failed to upload meeting image');
    }

    final data = jsonDecode(responseBody);
    return data['url'] as String;
  }

  Future<Meeting> createMeeting({
    required String title,
    required DateTime meetingDate,
    required String location,
    String? locationDetail,
    required int maxParticipants,
    int? minParticipants,
    required List<String> interests,
    String? description,
    required String category,
    int? participationFee,
    String? genderRestriction,
    int? ageRangeMin,
    int? ageRangeMax,
    required String approvalType,
    List<String>? imageUrls,
    List<String>? applicationQuestions,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meetings'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'meeting_date': meetingDate.toIso8601String(),
        'location': location,
        if (locationDetail != null) 'location_detail': locationDetail,
        'max_participants': maxParticipants,
        if (minParticipants != null) 'min_participants': minParticipants,
        'interests': interests,
        if (description != null) 'description': description,
        'category': category,
        if (participationFee != null) 'participation_fee': participationFee,
        if (genderRestriction != null) 'gender_restriction': genderRestriction,
        if (ageRangeMin != null) 'age_range_min': ageRangeMin,
        if (ageRangeMax != null) 'age_range_max': ageRangeMax,
        'approval_type': approvalType,
        if (imageUrls != null && imageUrls.isNotEmpty) 'image_urls': imageUrls,
        if (applicationQuestions != null && applicationQuestions.isNotEmpty)
          'application_questions': applicationQuestions,
      }),
    );
    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = errorBody?['error']?.toString() ?? 'Failed to create meeting';
      final field = errorBody?['field']?.toString();
      if (response.statusCode == 400 && field != null) {
        throw ApiValidationException(msg, field: field);
      }
      throw Exception(msg);
    }
    return Meeting.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteMeeting(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/meetings/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to delete meeting');
    }
  }

  Future<Meeting> updateMeeting(
    String id, {
    String? title,
    DateTime? meetingDate,
    String? location,
    String? locationDetail,
    int? maxParticipants,
    int? minParticipants,
    List<String>? interests,
    String? description,
    String? category,
    int? participationFee,
    String? genderRestriction,
    int? ageRangeMin,
    int? ageRangeMax,
    String? approvalType,
    List<String>? imageUrls,
    List<String>? applicationQuestions,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/meetings/$id'),
      headers: _headers,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (meetingDate != null) 'meeting_date': meetingDate.toIso8601String(),
        if (location != null) 'location': location,
        if (locationDetail != null) 'location_detail': locationDetail,
        if (maxParticipants != null) 'max_participants': maxParticipants,
        if (minParticipants != null) 'min_participants': minParticipants,
        if (interests != null) 'interests': interests,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (participationFee != null) 'participation_fee': participationFee,
        if (genderRestriction != null) 'gender_restriction': genderRestriction,
        if (ageRangeMin != null) 'age_range_min': ageRangeMin,
        if (ageRangeMax != null) 'age_range_max': ageRangeMax,
        if (approvalType != null) 'approval_type': approvalType,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (applicationQuestions != null) 'application_questions': applicationQuestions,
      }),
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = errorBody?['error']?.toString() ?? 'Failed to update meeting';
      final field = errorBody?['field']?.toString();
      if (response.statusCode == 400 && field != null) {
        throw ApiValidationException(msg, field: field);
      }
      throw Exception(msg);
    }
    return Meeting.fromJson(jsonDecode(response.body));
  }

  /// 모임 평가 완료 여부
  Future<bool> getMeetingEvaluationStatus(String meetingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/meetings/$meetingId/evaluation-status'),
      headers: _headers,
    );
    if (response.statusCode != 200) return true;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['submitted'] as bool?) ?? true;
  }

  /// 평가 대기 목록 (참가했고 완료되었으나 미평가 모임)
  Future<List<Map<String, dynamic>>> getPendingEvaluations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/pending-evaluations'),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// 모임 평가 제출
  Future<void> submitMeetingEvaluation(
    String meetingId, {
    int? meetingRating,
    Map<String, int>? participantScores,
  }) async {
    final body = <String, dynamic>{};
    if (meetingRating != null) body['meeting_rating'] = meetingRating;
    if (participantScores != null && participantScores.isNotEmpty) {
      body['participant_scores'] = participantScores;
    }
    final url = '$baseUrl/meetings/$meetingId/evaluations';
    debugPrint('🔵 [ApiService] 평가 제출: meetingId=$meetingId, url=$url, body=$body');
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    debugPrint('🔵 [ApiService] 평가 제출 응답: status=${response.statusCode}, body=${response.body}');
    if (response.statusCode != 200) {
      final err = (jsonDecode(response.body) as Map<String, dynamic>?)?['error'];
      throw Exception(err ?? 'Failed to submit evaluation');
    }
  }

  // Application APIs
  Future<Application> applyToMeeting(
    String meetingId, {
    String? answer1,
    String? answer2,
  }) async {
    debugPrint('🔵 [ApiService] 신청 API 호출 시작');
    debugPrint(
      '🔵 [ApiService] URL: $baseUrl/meetings/$meetingId/applications',
    );
    debugPrint(
      '🔵 [ApiService] 답변1: ${answer1 != null ? "${answer1.substring(0, answer1.length > 50 ? 50 : answer1.length)}..." : "없음"}',
    );
    debugPrint('🔵 [ApiService] 답변2: ${answer2 ?? "없음"}');

    final requestBody = {
      if (answer1 != null && answer1.isNotEmpty) 'answer1': answer1,
      if (answer2 != null && answer2.isNotEmpty) 'answer2': answer2,
    };
    debugPrint('🔵 [ApiService] 요청 본문: $requestBody');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meetings/$meetingId/applications'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      debugPrint('🔵 [ApiService] 응답 상태 코드: ${response.statusCode}');
      debugPrint('🔵 [ApiService] 응답 본문: ${response.body}');

      if (response.statusCode != 201) {
        final errorBody = jsonDecode(response.body);
        debugPrint('❌ [ApiService] 신청 실패');
        debugPrint(
          '❌ [ApiService] 에러: ${errorBody['error'] ?? 'Unknown error'}',
        );
        throw Exception(errorBody['error'] ?? 'Failed to apply to meeting');
      }

      final responseData = jsonDecode(response.body);
      debugPrint('✅ [ApiService] 신청 성공');
      debugPrint('✅ [ApiService] 응답 데이터: $responseData');
      return Application.fromJson(responseData);
    } catch (e, stackTrace) {
      debugPrint('❌ [ApiService] 신청 API 호출 에러');
      debugPrint('❌ [ApiService] 에러 타입: ${e.runtimeType}');
      debugPrint('❌ [ApiService] 에러 메시지: $e');
      debugPrint('❌ [ApiService] 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getApplications(String meetingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/meetings/$meetingId/applications'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get applications');
    }
    final data = jsonDecode(response.body);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Application> approveApplication(String applicationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/applications/$applicationId/approve'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve application');
    }
    return Application.fromJson(jsonDecode(response.body));
  }

  Future<Application> rejectApplication(String applicationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/applications/$applicationId/reject'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject application');
    }
    return Application.fromJson(jsonDecode(response.body));
  }

  // Feed APIs
  Future<List<Feed>> getFeeds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/feeds'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get feeds');
    }
    final data = jsonDecode(response.body);
    return (data as List).map((e) => Feed.fromJson(e)).toList();
  }

  Future<List<Feed>> getMyFeeds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/feeds/me'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get my feeds');
    }
    final data = jsonDecode(response.body);
    return (data as List).map((e) => Feed.fromJson(e)).toList();
  }

  Future<List<Feed>> getFeedsByUser(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/feeds/user/$userId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get user feeds');
    }
    final data = jsonDecode(response.body);
    return (data as List).map((e) => Feed.fromJson(e)).toList();
  }

  Future<Feed> createFeed({
    required String content,
    List<String>? imageUrls,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feeds'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        if (imageUrls != null) 'image_urls': imageUrls,
      }),
    );
    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = errorBody?['error']?.toString() ?? 'Failed to create feed';
      final field = errorBody?['field']?.toString();
      if (response.statusCode == 400 && field != null) {
        throw ApiValidationException(msg, field: field);
      }
      throw Exception(msg);
    }
    return Feed.fromJson(jsonDecode(response.body));
  }

  Future<Feed> updateFeed(
    String id, {
    required String content,
    List<String>? imageUrls,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/feeds/$id'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        if (imageUrls != null) 'image_urls': imageUrls,
      }),
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = errorBody?['error']?.toString() ?? 'Failed to update feed';
      final field = errorBody?['field']?.toString();
      if (response.statusCode == 400 && field != null) {
        throw ApiValidationException(msg, field: field);
      }
      throw Exception(msg);
    }
    return Feed.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteFeed(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/feeds/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to delete feed');
    }
  }

  Future<void> toggleFeedLike(String feedId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feeds/$feedId/like'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to toggle like');
    }
  }

  Future<List<FeedComment>> getFeedComments(String feedId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/feeds/$feedId/comments'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get comments');
    }
    final data = jsonDecode(response.body);
    return (data as List).map((e) => FeedComment.fromJson(e)).toList();
  }

  Future<FeedComment> createFeedComment(String feedId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feeds/$feedId/comments'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = errorBody?['error']?.toString() ?? 'Failed to create comment';
      final field = errorBody?['field']?.toString();
      if (response.statusCode == 400 && field != null) {
        throw ApiValidationException(msg, field: field);
      }
      throw Exception(msg);
    }
    return FeedComment.fromJson(jsonDecode(response.body));
  }

  Future<String> uploadFeedImage(File file) async {
    final uri = Uri.parse('$baseUrl/feeds/upload');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    if (streamedResponse.statusCode != 200) {
      try {
        final errorData = jsonDecode(responseBody);
        throw Exception(errorData['error'] ?? 'Failed to upload feed image');
      } catch (e) {
        throw Exception(
          'Failed to upload feed image: ${streamedResponse.statusCode}',
        );
      }
    }
    final data = jsonDecode(responseBody);
    return data['url'] as String;
  }

  /// 유저 생성 콘텐츠 신고
  Future<void> reportContent({
    required String targetType, // 'feed', 'comment' 등
    required String targetId,
    required String targetUserId,
    required String reason,
    String? detail,
    Map<String, dynamic>? extra,
  }) async {
    final body = <String, dynamic>{
      'target_type': targetType,
      'target_id': targetId,
      'target_user_id': targetUserId,
      'reason': reason,
      if (detail != null) 'detail': detail,
      if (extra != null) 'extra': extra,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/reports'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to report content');
    }
  }

  /// 사용자 차단 (DB에 저장)
  Future<void> blockUser(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/block'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to block user');
    }
  }

  /// 사용자 차단 해제
  Future<void> unblockUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/block'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to unblock user');
    }
  }

  /// 차단한 사용자 ID 목록 (DB 기준)
  Future<List<String>> getBlockedUserIds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/blocked-ids'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      return [];
    }
    final body = jsonDecode(response.body);
    final list = body['blocked_user_ids'];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// 차단한 사용자 목록 (이름·프로필 이미지 포함)
  Future<List<BlockedUserInfo>> getBlockedUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/blocked-ids'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      return [];
    }
    final body = jsonDecode(response.body);
    final list = body['blocked_users'];
    if (list is! List) return [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return BlockedUserInfo(
        userId: m['user_id']?.toString() ?? '',
        fullName: m['full_name']?.toString(),
        profileImageUrl: m['profile_image_url']?.toString(),
      );
    }).toList();
  }
}

class BlockedUserInfo {
  final String userId;
  final String? fullName;
  final String? profileImageUrl;
  BlockedUserInfo({
    required this.userId,
    this.fullName,
    this.profileImageUrl,
  });
}
