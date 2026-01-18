import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/meeting.dart';
import '../models/application.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth APIs
  Future<void> sendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: _headers,
        body: jsonEncode({'phone_number': phoneNumber}),
      );
      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to send OTP');
        } catch (_) {
          throw Exception('Failed to send OTP: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('네트워크 오류가 발생했습니다. 서버가 실행 중인지 확인해주세요.');
    }
  }

  Future<String> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({'phone_number': phoneNumber, 'otp': otp}),
      );
      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to verify OTP');
        } catch (_) {
          throw Exception('Failed to verify OTP: ${response.statusCode}');
        }
      }
      final data = jsonDecode(response.body);
      _token = data['token'];
      return _token!;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('네트워크 오류가 발생했습니다. 서버가 실행 중인지 확인해주세요.');
    }
  }

  // Social login APIs
  Future<String> loginWithKakao(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kakao'),
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
      _token = data['token'];
      return _token!;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('카카오 로그인에 실패했습니다.');
    }
  }

  Future<String> loginWithApple(String idToken, String? email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/apple'),
        headers: _headers,
        body: jsonEncode({
          'id_token': idToken,
          if (email != null) 'email': email,
        }),
      );
      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to login with Apple');
        } catch (_) {
          throw Exception('Failed to login with Apple: ${response.statusCode}');
        }
      }
      final data = jsonDecode(response.body);
      _token = data['token'];
      return _token!;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Apple 로그인에 실패했습니다.');
    }
  }

  Future<String> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: _headers,
        body: jsonEncode({'id_token': idToken}),
      );
      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to login with Google');
        } catch (_) {
          throw Exception('Failed to login with Google: ${response.statusCode}');
        }
      }
      final data = jsonDecode(response.body);
      _token = data['token'];
      return _token!;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google 로그인에 실패했습니다.');
    }
  }

  // User APIs
  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
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
