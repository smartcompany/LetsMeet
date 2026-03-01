# App Store Guideline 4.0 & 5.1.1(v) 대응

## Guideline 4.0 - Design (Sign-in within the app)

### 적용 사항

- **로그인·회원가입**: 모든 로그인과 회원가입은 **앱 내**에서 이루어집니다.
  - **이메일**: 앱 내 이메일/비밀번호 입력 화면에서 로그인·회원가입
  - **카카오**: 카카오톡 앱이 있으면 카카오톡으로, 없으면 SDK 제공 **앱 내** 웹 로그인(플랫폼 기본 동작) 사용
  - **구글**: Google Sign-In 플러그인을 통한 **앱 내** 로그인
  - **애플**: Sign in with Apple을 통한 **앱 내** 로그인

- **웹 링크**: 앱에서 여는 모든 일반 웹 URL(약관, 지도 웹 fallback 등)은 **앱 내 브라우저**로 엽니다.
  - iOS: `LaunchMode.inAppBrowserView` 사용 → **SFSafariViewController** 사용
  - 구현: `lib/utils/in_app_browser.dart`의 `openUrlInApp` / `openUriInApp` 사용
  - 사용처: 지도 앱 미설치 시 웹 지도 링크 등

이를 통해 “사용자가 기본 웹 브라우저로 이동해 로그인/회원가입한다”는 문제를 줄이고, 가능한 한 앱 내에서 인증·웹 콘텐츠를 제공합니다.

---

## Guideline 5.1.1(v) - Account deletion

### 적용 사항

- **계정 삭제 경로**: **프로필 탭 → 계정 삭제** 메뉴
- **동작**:
  1. “계정 삭제” 화면에서 삭제 시 복구 불가 안내 및 삭제되는 데이터 목록 표시
  2. “위 내용을 확인했으며, 계정 삭제에 동의합니다.” 체크박스 필수
  3. “계정 삭제” 버튼으로 서버에 계정 삭제 요청 (`DELETE /api/users/me`)
  4. 성공 시 Firebase 로그아웃 후 앱 첫 화면(로그인 필요 상태)으로 이동

- **구현 위치**
  - UI: `lib/screens/delete_account_screen.dart`, 프로필 메뉴: `lib/screens/profile_screen.dart`
  - API: `lib/services/api_service.dart` → `deleteAccount()`

계정 생성(회원가입)을 지원하므로, 동일 앱에서 계정 삭제도 제공합니다.
