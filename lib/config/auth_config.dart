import 'package:share_lib/share_lib_auth.dart';
import '../theme/app_theme.dart';
import '../screens/profile_setup_screen.dart';
import '../models/user.dart';

/// Android Google 로그인 idToken 검증용 Web OAuth 클라이언트 ID (google-services.json oauth_client client_type 3)
const String kGoogleServerClientId =
    '225419812075-n7imgrhem59uo9bdtpfkr9v92jb0ro3o.apps.googleusercontent.com';

/// 인증 모듈 설정
final authConfig = AuthConfig(
  // 테마 색상
  primaryColor: AppTheme.primaryColor,
  textPrimaryColor: AppTheme.textPrimaryColor,
  textSecondaryColor: AppTheme.textSecondaryColor,
  textTertiaryColor: AppTheme.textTertiaryColor,
  dividerColor: AppTheme.dividerColor,
  backgroundColor: AppTheme.backgroundColor,

  // 소셜 로그인 활성화
  enableAppleLogin: true,
  enableGoogleLogin: true,
  enableKakaoLogin: true,
  // 프로필 설정 확인 함수
  shouldShowProfileSetup: (user) {
    final myUser = user as User;
    return myUser.fullName.isEmpty ||
        myUser.lifeSceneId == null ||
        myUser.interactionStyleId == null;
  },

  // 프로필 설정 화면 빌더
  profileSetupScreenBuilder: (context) => const ProfileSetupScreen(),
);
