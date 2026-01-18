import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        _apiService.setToken(token);
        try {
          _user = await _apiService.getCurrentUser();
          notifyListeners();
        } catch (e) {
          // Token expired or invalid, or server not available
          debugPrint('Failed to get current user: $e');
          await prefs.remove('auth_token');
          _apiService.setToken('');
        }
      }
    } catch (e) {
      // Handle any initialization errors gracefully
      debugPrint('AuthProvider initialization error: $e');
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.sendOtp(phoneNumber);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _apiService.verifyOtp(phoneNumber, otp);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _user = await _apiService.getCurrentUser();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? nickname,
    List<String>? interests,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = await _apiService.updateUser(
        nickname: nickname,
        interests: interests,
      );
      _user = updatedUser;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Social login methods
  Future<void> loginWithKakao() async {
    _isLoading = true;
    notifyListeners();
    try {
      OAuthToken? oauthToken;

      // 카카오톡 로그인 시도
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          oauthToken = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          // 카카오톡 로그인 실패 시 카카오계정 로그인 시도
          if (error is PlatformException && error.code == 'CANCELLED') {
            _isLoading = false;
            notifyListeners();
            return;
          }
          oauthToken = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        oauthToken = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final accessToken = oauthToken.accessToken;

      // 서버에 인증 토큰 전송
      final token = await _apiService.loginWithKakao(accessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _user = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final email = credential.email;
      final token = await _apiService.loginWithApple(
        credential.identityToken!,
        email,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _user = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return; // 사용자가 취소한 경우
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return; // 사용자가 취소한 경우
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google 로그인 토큰을 가져올 수 없습니다.');
      }

      final token = await _apiService.loginWithGoogle(idToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _user = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // 소셜 로그인 로그아웃 처리
    try {
      if (await kakao.AuthApi.instance.hasToken()) {
        await kakao.UserApi.instance.unlink();
      }
    } catch (_) {
      // 카카오 로그인이 아닌 경우 무시
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {
      // Google 로그인이 아닌 경우 무시
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _user = null;
    _apiService.setToken('');
    notifyListeners();
  }
}
