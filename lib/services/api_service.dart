import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../models/meeting.dart';
import '../models/application.dart';

class ApiService implements AuthServiceInterface {
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

  @override
  Future<dynamic> updateUser({
    String? nickname,
    String? profileImageUrl,
    List<String>? interests,
    String? kakaoId, // 카카오 로그인인 경우
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({
        if (nickname != null) 'nickname': nickname,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        if (interests != null) 'interests': interests,
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

  // Meeting APIs
  Future<List<Meeting>> getMeetings({List<String>? interests}) async {
    final queryParams = interests != null && interests.isNotEmpty
        ? '?interests=${interests.join(',')}'
        : '';
    final response = await http.get(
      Uri.parse('$baseUrl/meetings$queryParams'),
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

  Future<Meeting> createMeeting({
    required String title,
    required DateTime meetingDate,
    required String location,
    String? locationDetail,
    required int maxParticipants,
    required List<String> interests,
    String? description,
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
        'interests': interests,
        if (description != null) 'description': description,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create meeting');
    }
    return Meeting.fromJson(jsonDecode(response.body));
  }

  // Application APIs
  Future<Application> applyToMeeting(String meetingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meetings/$meetingId/applications'),
      headers: _headers,
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to apply to meeting');
    }
    return Application.fromJson(jsonDecode(response.body));
  }

  Future<List<Application>> getApplications(String meetingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/meetings/$meetingId/applications'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get applications');
    }
    final data = jsonDecode(response.body);
    return (data as List).map((e) => Application.fromJson(e)).toList();
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
}
