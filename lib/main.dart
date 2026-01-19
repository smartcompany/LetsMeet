import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'dart:io' show Platform;
import 'providers/auth_provider.dart';
import 'providers/meeting_provider.dart';
import 'screens/main_tab_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: Platform.isIOS
        ? 'YOUR_IOS_KAKAO_NATIVE_APP_KEY' // TODO: iOS 카카오 앱 키로 변경
        : 'YOUR_ANDROID_KAKAO_NATIVE_APP_KEY', // TODO: Android 카카오 앱 키로 변경
    javaScriptAppKey:
        'YOUR_KAKAO_JAVASCRIPT_APP_KEY', // TODO: 카카오 JavaScript 키로 변경
  );

  // 한국어 로케일 데이터 초기화
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
      ],
      child: MaterialApp(
        title: 'LetsMeet',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 기본적으로 탭 화면을 먼저 보여줌
    // 인증은 필요할 때 (예: 모임 만들기, 모임 신청 시) 화면 전환으로 처리
    // 마이페이지/채팅 탭에서 필요 시 초기화
    return const MainTabScreen();
  }
}
