import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../models/meeting.dart';
import '../models/application.dart';

class ApiService implements AuthServiceInterface {
  // iOS 시뮬레이터에서는 localhost 대신 127.0.0.1 사용
  // Android 에뮬레이터에서는 10.0.2.2 사용
  static String get baseUrl {
    if (Platform.isIOS) {
      return 'http://127.0.0.1:3000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
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
  // 카카오 로그인 후 Firebase 커스텀 토큰 받기
  Future<String> loginWithKakaoFirebase(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kakao/firebase'),
        headers: _headers,
        body: jsonEncode({'access_token': accessToken}),
      );
      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to login with Kakao');
        } catch (_) {
          throw Exception('Failed to login with Kakao: ${response.statusCode}');
        }
      }
      final data = jsonDecode(response.body);
      return data['custom_token'] as String;
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
      throw Exception('Failed to get user');
    }
    return User.fromJson(jsonDecode(response.body));
  }

  Future<User> updateUser({
    String? nickname,
    String? profileImageUrl,
    List<String>? interests,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({
        if (nickname != null) 'nickname': nickname,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        if (interests != null) 'interests': interests,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
    return User.fromJson(jsonDecode(response.body));
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
