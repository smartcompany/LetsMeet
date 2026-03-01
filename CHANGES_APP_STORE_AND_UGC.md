# 이번에 추가·수정된 내용 (파일별 정리)

App Store 가이드라인 대응 및 UGC 안전 기능 추가 시 변경된 파일 목록과 요약입니다.

---

## 새로 추가된 파일 (client)

| 파일 | 설명 |
|------|------|
| `lib/utils/ugc_moderation.dart` | UGC 모더레이션: 텍스트 검증(`validateText`), 차단 목록 저장/로드(`getBlockedUserIds`, `addBlockedUser`), 피드/댓글 신고(`reportFeed`, `reportComment`), 사용자 차단(`blockUser`), 신고 사유 선택 바텀시트 |
| `lib/utils/in_app_browser.dart` | 앱 내 브라우저로 URL 열기 (`openUrlInApp`, `openUriInApp` → `LaunchMode.inAppBrowserView`) |
| `lib/screens/community_guidelines_screen.dart` | 커뮤니티 이용 약관 화면. 무관용 정책·신고/차단·24시간 조치 안내, 체크박스 동의 후 "동의하고 계속하기" |
| `lib/screens/delete_account_screen.dart` | 계정 삭제 전용 화면. 삭제 시 복구 불가 안내, 동의 체크박스, `DELETE /users/me` 호출 후 로그아웃 |
| `APP_STORE_DESIGN_GUIDELINE.md` | 가이드라인 4.0(앱 내 로그인·웹), 5.1.1(v)(계정 삭제) 대응 설명 (심사용) |
| `CHANGES_APP_STORE_AND_UGC.md` | 본 문서. 추가/수정 내용 파일별 정리 |

---

## 수정된 파일 (client)

| 파일 | 변경 요약 |
|------|------------|
| `lib/main.dart` | 로그인 후 `ensureCommunityGuidelinesAccepted()` 호출. 미동의 시 로그아웃 |
| `lib/services/api_service.dart` | `reportContent()` (POST /reports), `blockUser(userId)` (POST /users/:id/block), `deleteAccount()` (DELETE /users/me) 추가 |
| `lib/screens/profile_screen.dart` | 메뉴에 "계정 삭제" 추가 → `DeleteAccountScreen`으로 이동 |
| `lib/widgets/feed_card.dart` | 헤더에 `PopupMenuButton` 추가 (신고, 사용자 차단). `onReport`, `onBlockUser` 콜백 추가 |
| `lib/screens/feed_screen.dart` | 피드 로딩 시 차단 유저 필터. `FeedCard`에 `onReport`, `onBlockUser` 연결. 차단 시 리스트에서 즉시 제거 |
| `lib/screens/feed_comments_sheet.dart` | 댓글 로딩 시 차단 유저 필터. 댓글별 신고/차단 메뉴. 댓글 제출 전 `validateText`. 차단 시 해당 유저 댓글 즉시 제거 |
| `lib/screens/feed_create_screen.dart` | 피드 제출 전 `UGCModeration.validateText()` 호출 |
| `lib/screens/my_feeds_screen.dart` | 피드 작성/수정 제출 전 `UGCModeration.validateText()` 호출 |
| `lib/widgets/map_app_selector.dart` | 지도 앱 미설치 시 웹 fallback URL을 `openUriInApp()`으로 열기 (앱 내 브라우저) |

---

## 수정된 파일 (flutter_share_lib)

| 파일 | 변경 요약 |
|------|------------|
| `lib/src/image_picker/media_picker_service.dart` | 위챗 제거, `photo_manager` + `image_picker` 기반 커스텀 그리드 피커. 첫 칸 촬영 타일, 썸네일 `_AssetThumbnail`, 권한 `RequestType.image` + `hasAccess`, 카메라 타일 색상 `surface`/`onSurface` |
| `pubspec.yaml` | `wechat_assets_picker`, `wechat_camera_picker` 제거. `image_picker`, `photo_manager` 추가 |
| `lib/share_lib.dart` | `korean_camera_picker_text_delegate` export 제거 |
| `lib/share_lib_image_picker.dart` | `korean_camera_picker_text_delegate` export 제거 |
| (삭제) `lib/src/image_picker/korean_camera_picker_text_delegate.dart` | 위챗 전용이라 삭제 |
| `lib/src/auth/auth_provider.dart` | `googleServerClientId` 선택 인자 추가, `GoogleSignIn(serverClientId: _googleServerClientId)` 사용 |
| `lib/src/map_service.dart` | Apple 지도: 좌표 없어도 목록에 포함. `_buildAppleMapUrl`에서 장소명만으로 `http://maps.apple.com/?q=...` 지원 |

---

## 참고: 서버에서 구현 필요

- **POST /api/reports** — 신고 저장 (target_type, target_id, target_user_id, reason, detail 등)
- **POST /api/users/:userId/block** — 차단 관계 저장
- **DELETE /api/users/me** — 계정 및 연관 데이터 삭제/익명화
- 피드·댓글 목록 API에서 차단 유저 필터링 (선택, 클라이언트에서 이미 필터링 중)
- 운영자용 신고 목록 조회·처리 (24시간 내 조치)
- **GET /api/settings (또는 기존 설정 API)** — 응답에 금지어 목록 추가. 카카오톡 등에서 쓰는 방식처럼 서버에서 금지어 리스트를 내려주면 클라이언트가 피드/댓글 작성 시 검증에 사용함.
  - 필드명: `bannedWords` 또는 `banned_words`
  - 형식: 문자열 배열. 예: `"bannedWords": ["씨팔", "씨발", "욕설", "비방", "혐오", "fuck", "shit"]`
  - 없거나 빈 배열이면 클라이언트는 금지어 검사만 생략 (빈 값/최소 길이 검사는 유지)

자세한 스펙은 이전에 정리한 "다음에 할 일 (서버/운영 측)" 내용을 참고하면 됩니다.
