# share_lib Google 로그인 idToken 수정 (googleServerClientId)

## 원인
- Android에서 `GoogleSignIn()`에 **serverClientId**(Web OAuth 클라이언트 ID)를 넘기지 않으면 **idToken**이 null로 반환됨.
- 그 결과 `googleTokenError`(Google 로그인 토큰을 가져올 수 없습니다) 발생.

## 적용한 수정 (pub-cache 기준)

아래 변경은 **로컬 pub-cache의 share_lib**에 적용해 두었습니다.  
`flutter pub get`으로 다른 버전을 받으면 덮어쓰이므로, **flutter_share_lib 저장소**에 동일하게 반영하는 것을 권장합니다.

### 1. `lib/src/auth/auth_config.dart`
- `final String? googleServerClientId` 필드 추가.
- 생성자 및 `copyWith`에 `googleServerClientId` 추가.

### 2. `lib/src/auth/auth_provider.dart`
- 생성자에 `String? googleServerClientId` 인자 추가, `_googleServerClientId`로 저장.
- `GoogleSignIn` 생성 시 `serverClientId: _googleServerClientId` 전달.

```dart
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: _googleServerClientId,
);
```

### 3. LetsMeet 쪽
- `lib/config/auth_config.dart`: `googleServerClientId: '225419812075-n7imgrhem59uo9bdtpfkr9v92jb0ro3o.apps.googleusercontent.com'` 설정.
- `lib/main.dart`: `AuthProvider` 생성 시 `googleServerClientId: authConfig.googleServerClientId` 전달.

## flutter_share_lib에 반영 후
- LetsMeet `pubspec.yaml`에서 share_lib를 최신 커밋으로 올리거나,  
  로컬 개발 시 `client/pubspec_overrides.yaml`에 `path: ../../flutter_share_lib` 사용 (LetsMeet와 형제 폴더인 `~/Projects/flutter_share_lib`).
