# Google 로그인 ApiException 10 해결 (SHA-1 등록)

## 원인
- **ApiException: 10** = `DEVELOPER_ERROR` → 앱 서명(SHA-1)이 Firebase/Google Cloud에 없음.
- **디버그 / 알파(내부테스트) / 프로덕션** 각각 사용하는 키가 다르면, **그 키의 SHA-1을 모두** Firebase에 등록해야 함.

---

## 1. 디버그 빌드 (로컬·에뮬레이터)

| | 콜론 있음 | Firebase에 넣을 값 (콜론 없음) |
|--|--|--|
| **SHA-1** | 7E:F9:75:9D:9E:F8:50:BD:F2:16:1B:57:03:00:C3:96:8A:E0:02:7A | `7EF9759D9EF850BDF2161B570300C3968AE0027A` |
| **SHA-256** | D9:15:FD:1C:A4:51:0E:C6:CF:01:EE:A7:04:6F:88:BC:09:... | `D915FD1CA4510EC6CF01EEA7046F88BC09FE74C685A584740435C3E8C866D195` |

---

## 2. 릴리즈 빌드 (알파·프로덕션)

**키스토어:** `android/key.properties` → `storeFile=/Users/smart/Projects/auth/androidKey/my-release-key.jks`

| | 콜론 있음 | Firebase에 넣을 값 (콜론 없음) |
|--|--|--|
| **SHA-1** | 3F:CC:84:AC:0F:E2:33:C3:18:8A:60:9B:2A:D2:52:64:42:FE:89:5D | `3FCC84AC0FE233C3188A609B2AD2526442FE895D` |
| **SHA-256** | 82:E3:AA:87:F7:1E:D0:F2:EA:A2:AC:31:F3:AF:6C:7E:1A:... | `82E3AA87F71ED0F2EAA2AC31F3AF6C7E1AA4A1C30FCE5E1B97CB1468F6D23763` |

---

## 등록 방법 (Firebase Console)

1. [Firebase Console](https://console.firebase.google.com/) → 프로젝트 **letsmeet-8def5**
2. **프로젝트 설정**(⚙️) → **일반** 탭
3. **내 앱** → Android 앱 **com.smartcompany.letsMeet** 선택
4. **인증서** 섹션에서 **지문 추가**
5. 위 표의 **Firebase에 넣을 값**만 복사해서 붙여넣기 (콜론 없이, 한 줄).
6. **디버그용 SHA-1**, **릴리즈용 SHA-1** 둘 다 추가해 두면 디버그/알파/프로덕션 모두 Google 로그인 동작함.
7. 저장 후 앱 완전 종료 후 재실행해서 로그인 테스트.

---

## 프로젝트 설정 요약

- **릴리즈 키 경로**는 이미 `android/key.properties`에서 아래로 맞춰 둠:
  - `storeFile=/Users/smart/Projects/auth/androidKey/my-release-key.jks`
  - `keyAlias=my-key-alias`
- 비밀번호는 기존 그대로 두었음. 키 비밀번호가 다르면 `key.properties`의 `storePassword`, `keyPassword`만 수정하면 됨.

## 참고
- [Firebase - Add fingerprint](https://firebase.google.com/docs/android/setup#register-app)
- Play App Signing 사용 시: Play Console에서 **앱 무결성** → **앱 서명 키 인증서**에 나온 SHA-1도 Firebase에 추가해야 프로덕션에서 Google 로그인 가능.
