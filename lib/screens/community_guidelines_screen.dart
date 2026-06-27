import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../utils/screen_stack_observer.dart';

const _guidelinesAcceptedKey = 'community_guidelines_accepted_v1';

/// 커뮤니티 가이드라인 / 약관 동의 화면.
class CommunityGuidelinesScreen extends StatefulWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  State<CommunityGuidelinesScreen> createState() =>
      _CommunityGuidelinesScreenState();
}

class _CommunityGuidelinesScreenState extends State<CommunityGuidelinesScreen> {
  bool _agreedPrivacy = false;
  bool _agreedCommunity = false;

  bool get _canContinue => _agreedPrivacy && _agreedCommunity;

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guidelinesAcceptedKey, true);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티 이용 약관'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '개인정보 처리 및 커뮤니티 이용 안내',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '아래 내용을 확인하고 동의해야 서비스를 이용할 수 있습니다.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. 개인정보 처리 안내',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Bullet('서비스 운영을 위해 필요한 최소한의 정보만 처리합니다.'),
                      _Bullet('수집 항목: 로그인 식별자, 프로필 정보(닉네임/이미지), 서비스 이용기록'),
                      _Bullet('민감정보는 수집하지 않으며, 선택 정보는 입력하지 않아도 됩니다.'),
                      _Bullet('관련 법령 또는 정책에 따라 필요한 기간 동안만 보관 후 삭제합니다.'),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedPrivacy,
                            onChanged: (v) =>
                                setState(() => _agreedPrivacy = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                '개인정보 처리방침 및 데이터 처리 목적·범위를 확인했으며 이에 동의합니다.',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '2. 커뮤니티(UGC) 이용 가이드라인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '부적절한 콘텐츠 및 악성 이용자에 대해 관용이 없음을 원칙으로 합니다. '
                        '이용약관(EULA) 및 커뮤니티 가이드라인 위반 시 콘텐츠 삭제 및 계정 제한이 있을 수 있습니다.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '허용되지 않는 콘텐츠',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Bullet('음란물, 노골적인 성적 표현'),
                      _Bullet('폭력적이거나 위협적인 표현'),
                      _Bullet('욕설, 비방, 차별·혐오 표현'),
                      _Bullet('사기, 스팸, 광고 및 기타 불법 행위'),
                      const SizedBox(height: 16),
                      const Text(
                        '신고 및 차단',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Bullet('피드와 댓글에서 부적절한 내용을 신고할 수 있습니다.'),
                      _Bullet(
                          '다른 사용자를 차단하면 해당 사용자의 콘텐츠가 피드에서 즉시 제거되며, 차단 정보는 운영팀 검토에 활용됩니다.'),
                      const SizedBox(height: 16),
                      const Text(
                        '운영자의 조치',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Bullet('신고 접수 후 24시간 내 검토·조치합니다.'),
                      _Bullet(
                          '가이드라인을 심각하게 위반하는 경우 콘텐츠 삭제 및 계정 이용 제한이 이루어질 수 있습니다.'),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedCommunity,
                            onChanged: (v) =>
                                setState(() => _agreedCommunity = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                '커뮤니티(UGC) 운영 정책, 신고·제재 정책, 이용약관(EULA)에 동의합니다.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue ? _accept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('동의하고 계속하기'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('동의하지 않음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// prefs 기준으로 이미 동의했는지 여부. (약관 보여줄지 말지는 이 값만 보면 됨)
Future<bool> isCommunityGuidelinesAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_guidelinesAcceptedKey) ?? false;
}

/// 로그아웃 시 호출. 다음 로그인 때 가이드라인 동의 화면이 다시 표시되도록 초기화한다.
Future<void> clearCommunityGuidelinesAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_guidelinesAcceptedKey);
}

/// 커뮤니티 가이드라인에 동의했는지 확인하고, 필요 시 동의 화면을 보여준다.
Future<bool> ensureCommunityGuidelinesAccepted(BuildContext context) async {
  final accepted = await isCommunityGuidelinesAccepted();
  if (accepted) return true;
  if (ScreenStackObserver.instance.isOnStack(communityGuidelinesRouteName)) {
    return true; // 이미 스택에 있으면 중복 push 안 함
  }
  if (!context.mounted) return false;
  final result = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: (_) => const CommunityGuidelinesScreen(),
      fullscreenDialog: true,
      settings: const RouteSettings(name: communityGuidelinesRouteName),
    ),
  );
  return result == true;
}

/// 테스트용: 저장된 약관 동의 상태를 초기화한다. (디버그 빌드에서만 사용 권장)
/// 호출 후 로그아웃 → 다시 로그인하면 약관 동의 화면이 표시된다.
Future<void> resetCommunityGuidelinesAcceptedForTesting() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_guidelinesAcceptedKey);
}
