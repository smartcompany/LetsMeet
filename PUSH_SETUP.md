# LetsMeet 푸시 알림 설정 가이드

Firebase Cloud Messaging(FCM)을 이용한 iOS, Android, Web 푸시 알림 설정 가이드입니다.

---

## 1. 사전 요구사항

- Firebase 프로젝트가 이미 설정되어 있음 (letsmeet-8def5)
- `GoogleService-Info.plist` (iOS), `google-services.json` (Android) 존재
- FlutterFire CLI로 `firebase_options.dart` 생성됨

---

## 2. Firebase Console 설정

### 2-1. Cloud Messaging 활성화

1. [Firebase Console](https://console.firebase.google.com) → 프로젝트 **letsmeet-8def5** 선택
2. **Build** → **Cloud Messaging** 메뉴 확인 (기본 활성화됨)

### 2-2. 웹 푸시용 VAPID 키 (웹만 해당)

1. **Project settings** (톱니바퀴) → **Cloud Messaging** 탭
2. **Web configuration** → **Web Push certificates**
3. **Generate key pair** 클릭 → **Key pair** 값 복사 (나중에 웹에서 사용)

---

## 3. Flutter 코드 (이미 적용됨)

- `firebase_messaging` 패키지 추가
- `PushService` (`lib/services/push_service.dart`) - 권한 요청, 토큰 획득, 서버 저장
- `main.dart` - 백그라운드 핸들러 등록, 로그인 시 푸시 초기화
- `PUT /api/users/me/fcm-token` - FCM 토큰 저장 API

---

## 4. iOS 설정

### 4-1. Xcode Capability 추가

1. `ios/Runner.xcworkspace`를 Xcode로 열기
2. **Runner** 타겟 선택 → **Signing & Capabilities** 탭
3. **+ Capability** 클릭 → **Push Notifications** 추가
4. **+ Capability** → **Background Modes** 추가 후 **Remote notifications** 체크

### 4-2. APNs 인증 키 (Apple Developer 필요)

1. [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles**
2. **Keys** → **+** (새 키 생성)
3. **Key Name**: `LetsMeet Push` 등
4. **Apple Push Notifications service (APNs)** 체크 → **Continue** → **Register**
5. `.p8` 파일 다운로드 후 **안전하게 보관** (다시 받을 수 없음)
6. **Key ID**, **Team ID**, **Bundle ID** 메모

### 4-3. Firebase에 APNs 키 등록

1. Firebase Console → **Project settings** → **Cloud Messaging** 탭
2. **Apple app configuration** 섹션
3. **APNs Authentication Key** 업로드:
   - `.p8` 파일 선택
   - **Key ID**, **Team ID**, **Bundle ID** 입력 (예: `com.smartcompany.letsMeet`)

### 4-4. AppDelegate 수정 (선택)

`firebase_messaging` 플러그인이 자동으로 등록하므로, 별도 `AppDelegate` 수정은 없어도 됩니다.  
단, **UNUserNotificationCenter** 델리게이트를 직접 쓰려면 `AppDelegate.swift`에 추가:

```swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // UNUserNotificationCenter 델리게이트는 firebase_messaging이 처리
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 5. Android 설정

### 5-1. Firebase 플러그인 확인

`android/build.gradle.kts` (프로젝트 루트)에 다음이 있는지 확인. 없으면 추가:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false  // 추가
}
```

`android/app/build.gradle.kts` 하단에:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // 추가
}
```

> Flutter Firebase 설정에 따라 이미 포함되어 있을 수 있습니다. `flutterfire configure` 실행 시 자동 적용됩니다.

### 5-2. minSdkVersion

`android/app/build.gradle.kts`에서 `minSdk`가 **21 이상**인지 확인 (FCM 권장).

### 5-3. google-services.json

`android/app/google-services.json` 파일이 있어야 합니다.  
Firebase Console → **Project settings** → **Your apps** → Android 앱 → `google-services.json` 다운로드 후 `android/app/`에 배치.

### 5-4. 알림 채널 (선택)

Android 8.0+ 기본 알림 채널은 `firebase_messaging`에서 처리됩니다.  
커스텀 채널이 필요하면 `AndroidManifest.xml`에:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="letsmeet_channel" />
```

---

## 6. 웹 설정

### 6-1. Firebase Web SDK 스크립트

`web/index.html`의 `</body>` 직전에 추가:

```html
  <!-- Firebase SDK (Messaging) -->
  <script src="https://www.gstatic.com/firebasejs/11.0.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/11.0.0/firebase-messaging-compat.js"></script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

### 6-2. firebase-messaging-sw.js 생성

`web/` 폴더에 `firebase-messaging-sw.js` 파일 생성:

```javascript
importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-messaging-compat.js');


const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);
  const notificationTitle = payload.notification?.title || 'LetsMeet';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
```

> `apiKey`, `messagingSenderId`, `appId` 등은 `lib/firebase_options.dart` 웹 섹션 또는 Firebase Console → Project settings → Your apps → Web 앱에서 확인하세요.

### 6-3. VAPID 키 설정

Firebase Console → **Project settings** → **Cloud Messaging** → **Web Push certificates**에서 생성한 Key pair를 `firebase-messaging-sw.js`에 전달해야 합니다.  
Flutter의 `FirebaseMessaging.instance.getToken(vapidKey: '...')` 호출 시 같은 VAPID 키를 사용합니다.

### 6-4. manifest.json - gcm_sender_id

`web/manifest.json`에 FCM sender ID 추가:

```json
{
  "name": "letsmeet",
  "gcm_sender_id": "103953800507",
  ...
}
```

> `103953800507`은 Firebase 기본 값입니다. `firebase_options.dart`의 `messagingSenderId`와 맞춥니다.

### 6-5. HTTPS 필수

웹 푸시는 **HTTPS**에서만 동작합니다. 로컬 테스트는 `localhost`로 가능합니다.

---

## 7. Flutter 코드 예시

### 7-1. 초기화 및 권한 요청

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _setupPushNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // 권한 요청 (iOS)
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.denied) return;

  // FCM 토큰 획득
  final token = await messaging.getToken(
    vapidKey: 'YOUR_VAPID_KEY', // 웹만 해당
  );
  if (token != null) {
    debugPrint('FCM Token: $token');
    // 서버에 토큰 전달 (DB 저장 등)
  }

  // 포그라운드 메시지 핸들러
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground: ${message.notification?.title}');
  });

  // 백그라운드/종료 상태 메시지 (main 함수 최상단에 등록)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

---

## 8. 서버에서 푸시 전송

### FCM HTTP v1 API

1. Firebase Console → **Project settings** → **Service accounts** → **Generate new private key**
2. 발급된 JSON 키로 OAuth2 액세스 토큰 획득
3. `https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send` 로 POST 요청

### 예시 (Node.js)

```javascript
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

await admin.messaging().send({
  token: deviceToken,
  notification: { title: '제목', body: '본문' },
  data: { screen: 'chat', roomId: '123' },
});
```

---

## 9. 체크리스트

| 항목 | iOS | Android | Web |
|------|-----|---------|-----|
| firebase_messaging 패키지 | ✅ | ✅ | ✅ |
| Push Notifications capability | ✅ | - | - |
| APNs 키 등록 (Firebase) | ✅ | - | - |
| google-services.json | - | ✅ | - |
| firebase-messaging-sw.js | - | - | ✅ |
| manifest gcm_sender_id | - | - | ✅ |
| VAPID 키 (getToken) | - | - | ✅ |
| HTTPS | - | - | ✅ |

---

## 10. 참고 링크

- [Firebase Cloud Messaging 문서](https://firebase.google.com/docs/cloud-messaging)
- [Flutter firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [APNs 설정 가이드](https://firebase.google.com/docs/cloud-messaging/ios/certs)
- [웹 푸시 설정](https://firebase.google.com/docs/cloud-messaging/js/client)
