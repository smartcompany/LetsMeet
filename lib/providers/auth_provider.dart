import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_models;
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  app_models.User? _user;
  bool _isLoading = false;
  bool _isInitializing = false;
  bool _isInitialized = false;

  app_models.User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    // Firebase Auth 상태 변화 감지
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        // Firebase 사용자가 있으면 서버에서 사용자 정보 가져오기
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            _apiService.setToken(idToken);
            _user = await _apiService.getCurrentUser();
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Failed to get user info: $e');
        }
      } else {
        _user = null;
        _apiService.setToken('');
        notifyListeners();
      }
    });
  }

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) {
      return;
    }
    _isInitializing = true;
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            _apiService.setToken(idToken);
            _user = await _apiService.getCurrentUser();
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Failed to get current user: $e');
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('AuthProvider initialization error: $e');
    } finally {
      _isInitializing = false;
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

  // Firebase 이메일/비밀번호 로그인
  Future<void> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          _apiService.setToken(idToken);
          _user = await _apiService.getCurrentUser();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('등록되지 않은 이메일입니다.');
      } else if (e.code == 'wrong-password') {
        throw Exception('비밀번호가 올바르지 않습니다.');
      } else if (e.code == 'invalid-email') {
        throw Exception('이메일 형식이 올바르지 않습니다.');
      } else {
        throw Exception('로그인에 실패했습니다: ${e.message}');
      }
    } catch (e) {
      debugPrint('Email login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Firebase 이메일/비밀번호 회원가입
  Future<void> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          _apiService.setToken(idToken);
          // 회원가입 후 서버에 사용자 정보 생성
          _user = await _apiService.getCurrentUser();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('비밀번호가 너무 약합니다.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('이미 사용 중인 이메일입니다.');
      } else if (e.code == 'invalid-email') {
        throw Exception('이메일 형식이 올바르지 않습니다.');
      } else {
        throw Exception('회원가입에 실패했습니다: ${e.message}');
      }
    } catch (e) {
      debugPrint('Email signup error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 카카오 로그인
  Future<void> loginWithKakao() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('Starting Kakao Sign-In...');

      // 카카오 로그인 실행
      OAuthToken token = await kakao.UserApi.instance.loginWithKakaoTalk();
      debugPrint('Kakao login successful');

      // 카카오 사용자 정보 가져오기
      kakao.User kakaoUser = await kakao.UserApi.instance.me();

      if (kakaoUser.kakaoAccount == null) {
        throw Exception('카카오 계정 정보를 가져올 수 없습니다.');
      }

      // Firebase에 카카오 계정으로 커스텀 토큰 생성 필요
      // 서버에서 카카오 토큰 검증 후 Firebase 커스텀 토큰 발급
      final idToken = await _apiService.loginWithKakaoFirebase(
        token.accessToken,
      );

      // Firebase 커스텀 토큰으로 로그인
      final userCredential = await _firebaseAuth.signInWithCustomToken(idToken);

      if (userCredential.user != null) {
        final firebaseIdToken = await userCredential.user!.getIdToken();
        if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
          _apiService.setToken(firebaseIdToken);
          _user = await _apiService.getCurrentUser();
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Kakao login error: $e');

      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw Exception(
          '카카오 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)',
        );
      }

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apple 로그인
  Future<void> loginWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('Starting Apple Sign-In...');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('Getting Apple ID token...');
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      if (userCredential.user != null) {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          _apiService.setToken(idToken);
          _user = await _apiService.getCurrentUser();
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Apple login error: $e');

      if (e.code == AuthorizationErrorCode.unknown) {
        throw Exception(
          'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.',
        );
      }
      throw Exception('Apple 로그인에 실패했습니다: ${e.message}');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Apple login error: $e');

      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw Exception(
          'Apple 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)',
        );
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google 로그인
  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('Starting Google Sign-In...');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        debugPrint('Google Sign-In canceled by user');
        return; // 사용자가 취소한 경우
      }

      debugPrint('Getting Google authentication...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Google 로그인 토큰을 가져올 수 없습니다.');
      }

      // Firebase에 Google 인증 정보로 로그인
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        final firebaseIdToken = await userCredential.user!.getIdToken();
        if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
          _apiService.setToken(firebaseIdToken);
          _user = await _apiService.getCurrentUser();
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Google login error: $e');

      // 채널 연결 에러 처리
      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw Exception(
          'Google 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)',
        );
      }

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

    // Firebase 로그아웃
    await _firebaseAuth.signOut();

    _user = null;
    _apiService.setToken('');
    notifyListeners();
  }
}
