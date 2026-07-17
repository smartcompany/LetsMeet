import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' hide Route;
import 'package:share_lib/share_lib_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/meeting_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_tab_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';
import 'utils/app_localization.dart';
import 'utils/screen_stack_observer.dart';
import 'widgets/keyboard_dismiss_overlay.dart';

const _splashAsset = 'assets/splash/splash.png';
const _splashColor = Color(0xFF6B4EAA);
const _splashChannel = MethodChannel('letsmeet/splash');

Future<void> _precacheSplashImage() async {
  try {
    final data = await rootBundle.load(_splashAsset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    await codec.getNextFrame();
  } catch (e) {
    debugPrint('⚠️ 스플래시 이미지 프리로드 실패: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // preserve/deferFirstFrame 사용 안 함:
  // 커스텀 FlutterViewController에서는 LaunchScreen이 이미 사라진 뒤
  // defer만 하면 빈 서피스가 그대로 보임. 대신 즉시 runApp → Flutter 스플래시.

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 첫 프레임을 최대한 빨리 그리기 위해 Firebase 등은 runApp 이후로 이동
  unawaited(_precacheSplashImage());

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initDone = false;
  bool _showSplashOverlay = true;
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('⚠️ Firebase 초기화 오류: $e');
    }

    KakaoSdk.init(
      nativeAppKey: "e3221d057fe64e623f672e3e2b8b12a5",
      javaScriptAppKey: "d7c582cd72cf487332fe74fd6cf3b5bc",
    );

    // 설정(카테고리·광고 등)은 메인 진입 전 반드시 완료
    await SettingsProvider.shared.load();

    unawaited(_initKakaoMap());
    unawaited(PushService.shared.initialize());
    unawaited(MeetingProvider.shared.loadMeetings());

    await initializeDateFormatting('ko_KR', null);

    if (!mounted) return;

    // 메인(홈)을 스플래시 아래에서 빌드 — remove는 홈 appear 콜백에서
    setState(() => _initDone = true);
  }

  Future<void> _initKakaoMap() async {
    try {
      await KakaoMapSdk.instance.initialize('e3221d057fe64e623f672e3e2b8b12a5');
      debugPrint('✅ 카카오맵 SDK 초기화 완료');
    } catch (e) {
      debugPrint('⚠️ 카카오맵 SDK 초기화 오류: $e');
    }
  }

  /// 홈이 첫 프레임까지 그려진 뒤(viewDidAppear에 해당) 호출
  void _onHomeAppeared() {
    if (_splashRemoved || !mounted) return;
    _splashRemoved = true;

    // 네이티브 윈도우 스플래시 오버레이 제거
    if (!kIsWeb) {
      unawaited(
        _splashChannel.invokeMethod<void>('remove').catchError((_) {}),
      );
    }

    setState(() => _showSplashOverlay = false);
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: KeyboardDismissOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: Stack(
        fit: StackFit.expand,
        children: [
          if (_initDone) MainTabScreen(onHomeAppeared: _onHomeAppeared),
          if (_showSplashOverlay) const _SplashHoldScreen(),
        ],
      ),
    );
  }
}

/// 네이티브 Launch Screen과 동일 배경·이미지
class _SplashHoldScreen extends StatelessWidget {
  const _SplashHoldScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _splashColor,
      child: SizedBox.expand(
        child: Center(
          child: Image(
            image: AssetImage(_splashAsset),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
