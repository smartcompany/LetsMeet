# share_lib AdService 웹 대응 패치

`loadSettings()`가 웹에서 `io.Platform.isIOS` 등을 사용해 예외가 발생하는 문제를 수정합니다.
웹인 경우 **광고 관련 값 설정을 하지 않고** 정상 종료하도록 처리했습니다.

## flutter_share_lib 저장소에 적용할 변경

`lib/src/ad_service.dart` 파일을 수정하세요.

### 1. import 추가
```dart
import 'package:flutter/foundation.dart' show kIsWeb;
```

### 2. loadSettings() 시작부에 웹 체크 추가
`_settingsEndpoint` null 체크 직후, `try {` 블록 전에 추가:

```dart
    // 웹에서는 Platform(dart:io) 미지원, 모바일 광고 미지원 → 광고 설정 스킵
    if (kIsWeb) {
      debugPrint('ℹ️ [AdService] 웹 플랫폼: 광고 설정 스킵 (Platform 미지원)');
      return false;
    }
```

## 임시 사용 (pub cache 수정)

현재 pub cache에 위 수정이 반영된 상태입니다. `flutter pub get`을 다시 실행하면 덮어씌워질 수 있으므로,
**flutter_share_lib 저장소에 커밋 후 푸시**하고, LetsMeet에서 해당 커밋을 참조하도록 하세요.

## dependency_overrides로 로컬 테스트

로컬에서 flutter_share_lib를 수정하면서 테스트할 때:

```yaml
dependency_overrides:
  share_lib:
    path: ../flutter_share_lib  # 실제 경로에 맞게 수정
```
