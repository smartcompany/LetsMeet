# 카카오맵 Android 401 Unauthorized 해결

## 원인
`MapAuthException(401): Unauthorized` 는 다음 경우에 발생합니다.
- **카카오 개발자 콘솔**에 Android 앱(패키지명 + 키 해시)이 등록되지 않음
- **카카오맵** 제품 사용 설정이 꺼져 있음 (2024년 12월부터 신규 앱은 필수 활성화)

## 해결 방법

### 1. 카카오 개발자 콘솔 접속
- [내 애플리케이션](https://developers.kakao.com/console/app) 에서 해당 앱 선택 (Native App Key: `e3221d057fe64e623f672e3e2b8b12a5` 사용 중인 앱)

### 2. 카카오맵 사용 설정 켜기
- **앱 설정** → **제품 설정** (또는 **앱 키** 아래 **카카오맵**)
- **카카오맵** 항목에서 **사용 설정**을 **ON**으로 변경 후 저장

### 3. Android 플랫폼 등록
- **앱 설정** → **플랫폼** → **Android** 추가(또는 수정)
- **패키지명**: `com.smartcompany.letsMeet`
- **키 해시**는 아래 두 개 모두 등록 (카카오 콘솔에서 키 해시 여러 개 입력 가능):

| 용도 | 키 해시 |
|------|---------|
| **디버그** (로컬/에뮬레이터) | `fvl1nZ74UL3yFhtXAwDDlorgAno=` |
| **릴리즈** (알파/프로덕션) | `P8yErA/iM8MYimCbKtJSZEL+iV0=` |

저장 후 **앱 완전 종료 → 재실행** 후 지도 화면을 다시 열면 됩니다.

## 참고
- Android SDK는 **Native App Key**만 사용합니다. REST API 키는 지도 SDK 인증에 쓰이지 않습니다.
- [카카오맵 공통 가이드](https://developers.kakao.com/docs/latest/en/kakaomap/common)  
- [Android SDK 가이드](https://apis.map.kakao.com/android_v2/docs/)
