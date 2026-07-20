# App Store Connect — 메타데이터 업로드 (이음터)

문구 파일을 수정한 뒤 스크립트로 App Store Connect에 반영합니다.

## 파일 (업로드되는 필드)

### `listings.mjs`

로케일별 스토어 문구. `description` / `promotionalText`는 백틱(\`...\`) 멀티라인 문자열로 쓰면 개행이 그대로 보입니다.

```js
export default {
  ko: {
    name: "이음터",
    subtitle: "실제 만남을 위한 모임, 이음터",
    promotionalText: "홍보용 텍스트 (최대 170자)",
    description: `
설명 (최대 4000자)

문단을 실제 줄바꿈으로 작성합니다.
`,
    keywords: "모임,소모임,만남 (최대 100자, 쉼표 구분, 공백 없음)",
  },
};
```

| 키 | App Store |
|---------|-----------|
| `name` | 앱 정보 현지화 — 이름 |
| `subtitle` | 앱 정보 현지화 — 부제 |
| `description` | 버전 — 설명 |
| `keywords` | 버전 — 키워드 |
| `promotionalText` | 버전 — 홍보용 텍스트 |

> 표준 JSON은 따옴표 안 실제 개행을 지원하지 않아 `.mjs` + 템플릿 리터럴을 씁니다. `--listings`로 기존 `.json`도 가능합니다.

### `whats-new.json`

```json
{
  "ko": "• What's New 한국어"
}
```

| JSON 값 | App Store |
|---------|-----------|
| 로케일 문자열 | 버전 — 새로운 기능 (What's New) |

## 1회 설정

```bash
cd client/tools/asc-metadata
cp .env.example .env
# ASC_ISSUER_ID=... 만 입력 (Tabata와 동일한 Auth Key 사용 가능)
```

AuthKey 기본:

`/Users/smart/Projects/auth/fastlaneAuthKeys/AuthKey_7FN57R567Z.p8`

앱 정보:

- Bundle ID: `com.smartcompany.letsMeet`
- App Store ID: `6757979087`

## 사용

```bash
cd client/tools/asc-metadata

./update-metadata.sh --dry-run
./update-metadata.sh

./update-whats-new.sh
./update-metadata.sh --only promotionalText
./update-metadata.sh --only name,subtitle
./update-metadata.sh --only keywords
./update-metadata.sh --version 1.0.0
```

## 문구 수정 흐름

1. `listings.mjs` / `whats-new.json` 수정
2. `./update-metadata.sh --dry-run` 으로 미리보기
3. `./update-metadata.sh` 로 업로드

루트의 `앱스토어_앱설명.md`는 초안용 문서입니다. 실제 업로드 소스는 이 폴더의 `listings.mjs`입니다.

## 주의

- 설명/키워드/What's New는 버전이 **편집 가능**할 때 갱신됩니다.
- 홍보용 텍스트(`promotionalText`)는 라이브 중에도 되는 경우가 많습니다.
- 부제(`subtitle`)는 새 버전 제출 시 함께 반영되는 경우가 있습니다.
- Connect에 해당 로케일(`ko`)이 없으면 스킵됩니다.
- Node 18+ 필요.
- 백틱 문자열 안에 `` ` `` 또는 `${` 가 있으면 이스케이프하세요.
