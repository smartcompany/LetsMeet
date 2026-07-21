# 카카오 웹 / 공유 설정 가이드

LetsMeet는 **웹 앱**과 **앱 다운로드 링크** 도메인이 다릅니다.

| 용도 | 도메인 |
|------|--------|
| 웹 앱 실행 · 카카오 로그인 Redirect | `https://lets-meet-lime.vercel.app` |
| 앱 다운로드/공유 (`/applink`, `/meeting/...`) | `https://lets-meet-server.vercel.app` |

---

## 1. 카카오 로그인 (플랫폼 > Web)

1. [카카오 개발자 콘솔](https://developers.kakao.com/console/app) → LetsMeet 앱
2. **앱 설정** → **플랫폼** → **Web**
3. **사이트 도메인**
   - `https://lets-meet-lime.vercel.app`
   - `https://lets-meet-server.vercel.app` (공유 링크용, 함께 등록 권장)
   - 로컬: `http://localhost:xxxx`
4. **Redirect URI** (카카오 로그인)
   - `https://lets-meet-lime.vercel.app/`
   - 로컬: `http://localhost:xxxx/`

> Redirect URI는 **lime**만 쓰면 됩니다. 웹앱이 lime에서 돌아가기 때문입니다.

---

## 2. 카카오톡 공유 링크 (앱 > Product Link) — 중요

**플랫폼 > Web** 과 **Product Link > Web domain** 은 **별개**입니다.  
공유 버튼 링크가 `lime`으로 바뀌거나 `vercel.ap`처럼 깨지면 여기를 확인하세요.

1. **앱** → **Product Link** (또는 제품 링크)
2. **Web domain**에 **둘 다** 등록
   - `https://lets-meet-lime.vercel.app`
   - `https://lets-meet-server.vercel.app`
3. **기본 웹 도메인**을 다운로드/공유용으로 쓸 도메인으로 설정
   - 앱 공유: `https://lets-meet-server.vercel.app` (+ 경로 `/applink`)
   - 오타 주의: `vercel.ap` ❌ → `vercel.app` ✅
4. Android/iOS 앱 링크(스킴, 패키지, 스토어 URL)도 Product Link에 맞게 등록

카카오 TextTemplate(`shareDefault`, template_id 5793)은 [Product Link에 등록된 도메인](https://developers.kakao.com/docs/en/message-template/default) 기준으로 링크를 조합합니다.  
SDK에 `https://lets-meet-server.vercel.app/applink`를 넘겨도, Product Link 기본 도메인이 `lime`이면 템플릿 로그/일부 슬롯에는 `lime` URL이 보일 수 있습니다.

---

## 3. 앱 설정 `down_load_url`

서버 `settings.json`:

```json
"down_load_url": "https://lets-meet-server.vercel.app/applink"
```

앱 공유는 이 값을 우선 사용합니다.

---

## 4. JavaScript 키

- **앱 설정** → **앱 키** → **JavaScript 키** = `main.dart`의 `javaScriptAppKey`
- 현재: `d7c582cd72cf487332fe74fd6cf3b5bc`

---

## 5. 로그 해석

```
🔍 [카카오톡 공유] linkUrl=https://lets-meet-server.vercel.app/applink
```
→ **앱이 SDK에 넣은 값** (정상)

```
[KakaoShare] requestedLinkUrl: https://lets-meet-server.vercel.app/applink
[KakaoShare] templateUrlSlots:
  ${MOBILE_WEB_URL}: https://lets-meet-lime.vercel.app/...
```
→ **카카오가 Product Link 기준으로 만든 슬롯**.  
`requestedLinkUrl`과 다르면 Product Link 기본 웹 도메인/등록 도메인 문제입니다.

---

## 오류별 대응

| 오류 | 원인 | 해결 |
|------|------|------|
| `Javascript env validation failed` | Web 플랫폼/도메인 미등록 | 플랫폼·Redirect URI 등록 |
| 공유 링크가 lime으로 감 | Product Link 기본 도메인 | Product Link Web domain + 기본 도메인 수정 |
| `vercel.ap` (app 빠짐) | Product Link 도메인 오타 | `vercel.app`으로 수정 |
| `unauthorized-domain` (Firebase) | Firebase 허용 도메인 | Authentication → Authorized domains |
