# 카카오 로그인 웹 설정 가이드

웹에서 카카오 로그인이 동작하려면 **카카오 개발자 콘솔**에서 웹 플랫폼을 등록해야 합니다.

## 1. 카카오 개발자 콘솔 설정

1. [카카오 개발자 콘솔](https://developers.kakao.com/console/app) 접속
2. 앱 선택 (LetsMeet)
3. **앱 설정** → **플랫폼** → **Web 플랫폼 등록** 클릭
4. **사이트 도메인**에 다음 추가:
   - `https://lets-meet-lime.vercel.app`
   - 로컬 개발: `http://localhost:xxxx` (실행 포트에 맞게)
5. **Redirect URI** (카카오 로그인 → Redirect URI 설정):
   - `https://lets-meet-lime.vercel.app/`
   - 로컬: `http://localhost:xxxx/`
6. 저장

## 2. JavaScript 키 확인

- **앱 설정** → **앱 키** → **JavaScript 키**가 `main.dart`의 `javaScriptAppKey`와 일치하는지 확인
- 현재: `d7c582cd72cf487332fe74fd6cf3b5bc`

## 3. index.html

`web/index.html`에 Kakao JavaScript SDK 스크립트와 `Kakao.init()`이 포함되어 있어야 합니다. (이미 적용됨)

## 오류별 대응

| 오류 | 원인 | 해결 |
|------|------|------|
| `Javascript env validation failed` | 웹 플랫폼 미등록 또는 도메인 미등록 | 플랫폼·도메인·Redirect URI 등록 |
| `invalid_request` | Redirect URI 불일치 | Redirect URI 정확히 입력 |
| `unauthorized-domain` | Firebase 허용 도메인 아님 | Firebase Console → Authentication → Authorized domains 추가 |
