# App Store Connect 답변 초안 — Guideline 1.2 (UGC)

리젝 사유: **Guideline 1.2 - Safety - User-Generated Content**  
재제출 시 **Resolution Center**에서 "Reply to App Review" 또는 "추가 정보"란에 아래 내용을 붙여 넣어 보내면 됩니다. (영문으로 보내는 것을 권장합니다.)

---

## 영문 답변 (복사용)

```
Thank you for your feedback regarding Guideline 1.2 (User-Generated Content). We have implemented all required precautions and would like to clarify how each requirement is met:

1) Terms (EULA) and no tolerance for objectionable content / abusive users
   - Before using UGC features, users must accept our Community Guidelines (커뮤니티 이용 약관) in-app. The screen clearly states: "We have zero tolerance for objectionable content and abusive users" and that violations may result in content removal and account restriction. Users must check a box agreeing to the EULA and these terms before proceeding.

2) Method for filtering objectionable content
   - We filter content server-side using a banned-words list when users create or edit feeds, comments, and meetings. Posts containing prohibited terms are rejected with a clear error. Client-side validation also enforces minimum length and required fields.

3) Mechanism for users to flag objectionable content
   - From feed posts and comments, users can tap the menu and choose "Report" (신고). They select a reason (spam, hate speech, sexual content, violence, other) and may add details. Reports are sent to our backend (POST /api/reports) and stored for developer review.

4) Mechanism for users to block abusive users; developer notification and instant removal from feed
   - Users can block another user via the same menu ("Block user" / 사용자 차단). Blocking is saved on our server (POST /api/users/:id/block). The server logs each block event so we can review inappropriate behavior. The blocking user’s feed and comments are removed from the blocker’s view immediately (client-side filter and server-side filtering on subsequent loads).

5) Developer action on reports within 24 hours
   - Our Community Guidelines state that we will "review and take action on reports within 24 hours." We have an internal dashboard to list and process reports (including filtering by 24-hour window). We remove violating content and take action against offending accounts as per our policy.

We believe the app now fully addresses Guideline 1.2. We would be happy to provide a test account or a short screen recording showing the flow (terms acceptance, report, block) if that would help review.
```

---

## 한글 참고 (필요 시 요지만 전달)

- **약관·관용 없음**: 앱 내 "커뮤니티 이용 약관"에서 부적절한 콘텐츠·악성 이용자에 대한 **관용 없음**을 명시하고, 동의 체크 후에만 이용 가능하게 했습니다.
- **부적절 콘텐츠 필터**: 피드·댓글·모임 등록·수정 시 서버에서 **금지어 목록**으로 검사해, 포함 시 등록을 막고 안내합니다.
- **신고**: 피드·댓글 메뉴에서 **신고** 선택 시 사유(스팸/욕설/성적/폭력/기타)와 상세 내용을 서버로 전송해 저장·검토합니다.
- **차단**: 메뉴에서 **사용자 차단** 시 서버에 저장되고, 차단 시도가 개발자용 로그에 기록되며, 차단한 사용자의 피드·댓글이 **즉시** 해당 사용자 화면에서 제거됩니다.
- **24시간 내 조치**: 이용 약관에 "신고 접수 후 24시간 내 검토·조치"를 명시했고, 신고 목록을 24시간 기준으로 확인·처리하는 관리자 대시를 운영합니다.

---

## 제출 전 체크

- [ ] 앱에서 로그인 후 프로필 설정 진입 시 **커뮤니티 이용 약관**이 뜨는지 확인
- [ ] 피드/댓글에서 **신고**, **사용자 차단** 메뉴가 보이고 동작하는지 확인
- [ ] 차단 후 해당 유저 피드가 리스트에서 **즉시** 사라지는지 확인
- [ ] 서버/대시에서 신고·차단 로그를 확인할 수 있는지 확인
