# App Store 심사 체크리스트 (애플 리젝 대응)

## ✅ 이미 적용된 항목

| 항목 | 상태 | 비고 |
|------|------|------|
| **4.0 앱 내 로그인** | ✅ | 카카오·구글·애플 로그인 모두 앱 내에서 동작 |
| **4.0 지도 – Apple Maps** | ✅ | 모임 상세 장소 → 지도 앱 선택 시 iOS에서 애플 지도 포함(맨 위). MapAppSelector 사용 |
| **5.1.1(v) 계정 삭제** | ✅ | 프로필 → 계정 삭제, 복구 불가 안내·동의 체크박스, DELETE /api/users/me |
| **Sign in with Apple** | ✅ | `enableAppleLogin: true`, Info.plist URL scheme 설정 |
| **웹 링크 앱 내 브라우저** | ✅ | `in_app_browser.dart` → SFSafariViewController |
| **커뮤니티/이용 약관** | ✅ | 로그인 후 프로필 설정 진입 시 약관 동의. EULA·관용 없음·24시간 조치·신고·차단(즉시 피드 제거·개발자 알림) 명시 |
| **권한 안내 문구** | ✅ | Info.plist: 위치, 앨범, 카메라 UsageDescription |
| **암호화 수출** | ✅ | ITSAppUsesNonExemptEncryption = false |
| **광고·추적** | ✅ | IDFA/ATT 미사용, App Privacy에서 추적 안 함으로 명시 완료 |

---

## ⚠️ 제출 전 확인 권장

### 1. 개인정보 처리방침 URL (필수)

- **App Store Connect** → 앱 정보에 **개인정보 처리방침 URL** 등록 필수.
- 가능하면 **앱 내에서도** 접근 가능하게 두는 것이 좋음.
  - 예: 설정/프로필 메뉴에 「개인정보 처리방침」 항목 추가 후 `in_app_browser`로 해당 URL 열기.
- 수집 항목(로그인 정보, 프로필, 모임·채팅 데이터 등), 이용 목적, 보관 기간, 제3자 제공 여부를 안내하는 문서 필요.

### 2. App Privacy (앱 개인정보 처리)

- App Store Connect **App Privacy** 섹션에서 수집 데이터·추적 여부를 정확히 기입.
- Firebase, 카카오/구글/애플 로그인, AdMob(사용 시) 등 서드파티 SDK가 수집하는 데이터도 포함해 기재.

### 3. Sign in with Apple – 계정 삭제 시 토큰 revoke (선택, 권장)

- 계정 삭제 시 Apple 쪽 토큰도 revoke 하면 심사에서 유리할 수 있음.
- [Apple TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple): `/auth/revoke` 호출 또는 사용자에게 appleid.apple.com에서 앱 연동 해제 안내.

### 4. 지원 URL (Support URL)

- App Store Connect에 **지원 URL**(고객문의·FAQ)이 있으면 좋음. 없으면 리젝 사유는 아니지만, 있으면 심사·문의 대응에 유리.

### 5. 데모 계정 (심사용 계정)

- 로그인이 필수인 앱이면, **심사 노트**에 테스트용 계정(이메일/비밀번호 또는 소셜 로그인 방법)을 적어 두면 리젝 가능성이 줄어듦.

---

## 요약

- **반드시:** 개인정보 처리방침 URL(스토어 + 가능하면 앱 내 링크), App Privacy 정확 기입.
- **권장:** 앱 내 개인정보 처리방침 링크, Sign in with Apple revoke(계정 삭제 시), 지원 URL, 심사용 테스트 계정 안내.

위 항목까지 맞춰 두면 일반적인 4.0 / 5.1.1(v) / 개인정보 관련 리젝은 상당 부분 방지할 수 있습니다.
