import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:share_lib/share_lib_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/meeting_provider.dart';
import 'screens/main_tab_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (이미 초기화된 경우 스킵)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('⚠️ Firebase 초기화 오류: $e');
  }

  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: "e3221d057fe64e623f672e3e2b8b12a5",
    javaScriptAppKey: "d7c582cd72cf487332fe74fd6cf3b5bc",
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
        ChangeNotifierProvider(
          create: (_) => AuthProvider<User>(authService: ApiService()),
        ),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
      ],
      child: MaterialApp(
        title: 'LetsMeet',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          ...AuthLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AuthLocalizations.supportedLocales,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return const MainTabScreen();
  }
}
