import 'package:share_lib/share_lib_auth.dart';
import '../theme/app_theme.dart';
import '../screens/profile_setup_screen.dart';
import '../models/user.dart';

/// 인증 모듈 설정
final authConfig = AuthConfig(
  // 테마 색상
  primaryColor: AppTheme.primaryColor,
  textPrimaryColor: AppTheme.textPrimaryColor,
  textSecondaryColor: AppTheme.textSecondaryColor,
  textTertiaryColor: AppTheme.textTertiaryColor,
  dividerColor: AppTheme.dividerColor,
  backgroundColor: AppTheme.backgroundColor,

  // 프로필 설정 확인 함수
  shouldShowProfileSetup: (user) {
    final myUser = user as User;
    return myUser.nickname.isEmpty || myUser.interests.isEmpty;
  },

  // 프로필 설정 화면 빌더
  profileSetupScreenBuilder: (context) => const ProfileSetupScreen(),
);
