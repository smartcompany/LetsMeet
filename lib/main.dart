import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:share_lib/share_lib_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/meeting_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_tab_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/push_service.dart';
import 'models/user.dart';
import 'utils/deep_link_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 푸시 알림 백그라운드 핸들러 (최상단에 등록)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

  // 카카오맵 SDK 초기화 (카카오 로그인과 동일한 네이티브 앱 키 사용)
  try {
    await KakaoMapSdk.instance.initialize('e3221d057fe64e623f672e3e2b8b12a5');
    debugPrint('✅ 카카오맵 SDK 초기화 완료');
  } catch (e) {
    debugPrint('⚠️ 카카오맵 SDK 초기화 오류: $e');
  }

  // 한국어 로케일 데이터 초기화
  await initializeDateFormatting('ko_KR', null);

  // 설정 API 로드 (카테고리, 광고 등) - 앱 시작 시
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  runApp(MyApp(settingsProvider: settingsProvider));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settingsProvider});
  final SettingsProvider settingsProvider;

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider<User>(authService: apiService),
        ),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(
          create: (ctx) =>
              NotificationProvider(apiService: ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
  bool _pushInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.init(navigatorKey);
    });
  }

  void _initPushIfLoggedIn(AuthProvider<User> authProvider) {
    if (authProvider.user == null || _pushInitialized) return;
    _pushInitialized = true;
    final api = context.read<ApiService>();
    PushService(apiService: api).initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider<User>>(
      builder: (context, authProvider, _) {
        // 로그인 시 푸시 알림 초기화 (한 번만)
        if (authProvider.user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initPushIfLoggedIn(authProvider);
          });
        }
        return const MainTabScreen();
      },
    );
  }
}
