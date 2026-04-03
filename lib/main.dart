import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' hide Route;
import 'package:share_lib/share_lib_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/main_tab_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';
import 'utils/deep_link_handler.dart';
import 'utils/app_localization.dart';
import 'utils/screen_stack_observer.dart';
import 'app_auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // iOS/Android: 세로만 (Info.plist UISupportedInterfaceOrientations 와 동일 정책)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Firebase 초기화 (완료될 때까지 기다린 뒤 runApp 실행)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('⚠️ Firebase 초기화 오류: $e');
  }

  // 나머지 초기화(Firebase, Kakao SDK, 설정 로드 등)는
  // MyApp 내부에서 비동기로 수행하면서, 처음에는 전역 로딩 화면을 보여준다.
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    // 카카오 SDK 초기화
    KakaoSdk.init(
      nativeAppKey: "e3221d057fe64e623f672e3e2b8b12a5",
      javaScriptAppKey: "d7c582cd72cf487332fe74fd6cf3b5bc",
    );

    // 카카오맵 SDK 초기화 (카카오 로그인과 동일한 네이티브 앱 키 사용)
    try {
      await KakaoMapSdk.instance.initialize('e3221d057fe64e623f672e3e2b8b12a5');
      debugPrint('✅ 카카오맵 SDK 초기화 완료');
    } catch (e) {
      debugPrint('⚠️ 카카오맵 SDK 초기화 오류: $e');
    }

    // 한국어 로케일 데이터 초기화
    await initializeDateFormatting('ko_KR', null);

    // 설정 API 로드 (카테고리, 광고 등)
    await SettingsProvider.shared.load();

    await PushService.shared.initialize();

    if (!mounted) return;
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [ScreenStackObserver.instance],
      title: AppLocalization.appName(),
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        ...AuthLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AuthLocalizations.supportedLocales,
      home: Stack(
        children: [
          const MainTabScreen(),
          if (!_initialized)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
