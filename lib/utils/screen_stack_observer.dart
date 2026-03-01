import 'package:flutter/material.dart';

/// 네비게이션에 push된 화면을 클래스명(라우트명)으로 추적.
/// push 전에 [isOnStack]으로 이미 있는지 확인하고, push 시 [RouteSettings.name]에 클래스명 지정.
class ScreenStackObserver extends NavigatorObserver {
  ScreenStackObserver._();
  static final ScreenStackObserver instance = ScreenStackObserver._();

  final Set<String> _routesOnStack = {};

  /// [routeName]에 해당하는 화면이 현재 스택에 있는지.
  bool isOnStack(String routeName) => _routesOnStack.contains(routeName);

  /// 로그아웃 등으로 해당 라우트를 스택에 없는 것으로 간주할 때 호출.
  void clearRoute(String routeName) {
    _routesOnStack.remove(routeName);
  }

  /// 로그아웃 시 다음 로그인에서 다시 띄울 수 있도록 등록된 화면들 초기화.
  void clearWhenLoggedOut() {
    _routesOnStack.removeAll(registeredRouteNames);
  }

  static const Set<String> registeredRouteNames = {
    profileSetupRouteName,
    communityGuidelinesRouteName,
  };

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && registeredRouteNames.contains(name)) {
      _routesOnStack.add(name);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) _routesOnStack.remove(name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) _routesOnStack.remove(name);
  }
}

/// push 시 [RouteSettings.name]에 넣을 값들 (클래스명 기준).
const String profileSetupRouteName = 'ProfileSetupScreen';
const String communityGuidelinesRouteName = 'CommunityGuidelinesScreen';
