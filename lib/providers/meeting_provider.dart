import 'package:flutter/foundation.dart';
import '../models/meeting.dart';
import '../models/application.dart';

class MeetingProvider with ChangeNotifier {
  List<Meeting> _meetings = [];
  List<Application> _applications = [];
  bool _isLoading = false;
  
  // 필터 상태
  String? _selectedLocation;
  String? _selectedInterest;
  MeetingFormat? _selectedFormat;

  List<Meeting> get meetings => _meetings;
  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get selectedLocation => _selectedLocation;
  String? get selectedInterest => _selectedInterest;
  MeetingFormat? get selectedFormat => _selectedFormat;

  // 필터링된 모임 리스트
  List<Meeting> get filteredMeetings {
    var filtered = _meetings.where((m) => m.status == MeetingStatus.open);
    
    if (_selectedLocation != null) {
      filtered = filtered.where((m) => m.location == _selectedLocation);
    }
    
    if (_selectedInterest != null) {
      filtered = filtered.where((m) => m.interests.contains(_selectedInterest));
    }
    
    if (_selectedFormat != null) {
      filtered = filtered.where((m) => m.format == _selectedFormat);
    }
    
    return filtered.toList();
  }

  MeetingProvider() {
    _loadDummyData();
  }

  void _loadDummyData() {
    _meetings = [
      Meeting(
        id: '1',
        hostId: 'host1',
        hostNickname: '민수',
        title: '디자인과 기술의 경계에서',
        shortDescription: 'UX/UI 디자이너와 개발자들이 모여 서로의 세계를 이야기합니다.',
        hostNote: '최근 사이드 프로젝트를 하면서 디자인과 개발 사이의 소통에 대해 생각이 많아졌어요. 함께 이야기 나눌 분들을 찾고 있습니다.',
        description: '''디자인과 개발은 서로 다른 언어를 사용하는 것처럼 보이지만, 결국 같은 목표를 향해 나아갑니다. 이 모임에서는:

• 디자이너가 개발을, 개발자가 디자인을 이해하는 법
• 협업 과정에서 겪는 어려움과 해결 방법
• 실제 프로젝트에서의 경험 공유

에 대해 이야기하고자 합니다.''',
        meetingDate: DateTime.now().add(const Duration(days: 7)),
        location: '서울',
        locationDetail: '강남구 논현동 카페',
        maxParticipants: 6,
        interests: ['디자인', '개발', '협업'],
        format: MeetingFormat.offline,
        topicsCovered: [
          '디자인과 개발의 협업 방식',
          '프로젝트에서의 역할 분담',
          '커뮤니케이션 방법론'
        ],
        topicsNotCovered: [
          '구체적인 기술 스택 선택',
          '디자인 툴 사용법',
          '코딩 강의'
        ],
        conversationFlow: '자기소개 → 각자의 경험 공유 → Q&A → 네트워킹',
        applicationQuestions: [
          '이 주제에 관심을 갖게 된 이유는?',
          '이 모임에서 기대하는 점은? (선택)'
        ],
        status: MeetingStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Meeting(
        id: '2',
        hostId: 'host2',
        hostNickname: '지영',
        title: '독서와 글쓰기로 만나는 사람들',
        shortDescription: '월 1권 책을 읽고, 그에 대한 생각을 글로 나누는 모임입니다.',
        hostNote: '책을 읽고 싶은데 혼자서는 자꾸 미뤄지더라고요. 함께하면 읽을 동기가 생길 것 같아서 모임을 열었습니다.',
        description: '''독서 습관을 만들고 싶은데 자꾸 미뤄지시나요? 함께 읽고 이야기하면 더 재미있고 지속 가능합니다.

이 모임에서는:
• 매월 1권의 책을 선정
• 독서 후 간단한 후기 작성
• 모임에서 느낀 점과 생각 공유

에 초점을 맞춥니다. 문학, 에세이, 자기계발 등 다양한 장르를 다룹니다.''',
        meetingDate: DateTime.now().add(const Duration(days: 14)),
        location: '서울',
        locationDetail: '온라인 (줌)',
        meetingLink: 'https://zoom.us/j/example',
        maxParticipants: 8,
        interests: ['독서', '글쓰기', '문화'],
        format: MeetingFormat.online,
        topicsCovered: [
          '독서 습관 만들기',
          '독후감 작성법',
          '다양한 장르의 책 이야기'
        ],
        topicsNotCovered: [
          '특정 작가나 작품 비평',
          '출판 관련 실무',
          '작문 강의'
        ],
        conversationFlow: '책 소개 → 개인별 후기 공유 → 주제별 토론 → 다음 책 선정',
        applicationQuestions: [
          '이 주제에 관심을 갖게 된 이유는?',
          '이 모임에서 기대하는 점은? (선택)'
        ],
        status: MeetingStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Meeting(
        id: '3',
        hostId: 'host3',
        hostNickname: '준호',
        title: '요리의 과학과 예술',
        shortDescription: '요리를 단순히 만드는 것이 아니라 이해하는 것에 대해 이야기합니다.',
        hostNote: '요리를 취미로 시작했는데, 왜 그렇게 되는지 궁금해하기 시작했어요. 함께 탐구해볼 분들을 찾습니다.',
        description: '''요리는 과학이기도 하고 예술이기도 합니다. 이 모임에서는:

• 조리법의 원리 이해
• 맛의 조합과 균형
• 다양한 문화의 요리 경험

에 대해 이야기하고, 때로는 함께 요리해보기도 합니다.''',
        meetingDate: DateTime.now().add(const Duration(days: 10)),
        location: '부산',
        locationDetail: '해운대구 요리 스튜디오',
        maxParticipants: 5,
        interests: ['요리', '음식', '문화'],
        format: MeetingFormat.offline,
        topicsCovered: [
          '조리 원리',
          '재료의 특징',
          '다양한 요리 문화'
        ],
        topicsNotCovered: [
          '레시피 강의',
          '요리 기술 연마',
          '외식업 창업'
        ],
        conversationFlow: '주제 소개 → 이론 설명 → 실습 (선택) → 경험 공유',
        applicationQuestions: [
          '이 주제에 관심을 갖게 된 이유는?',
          '이 모임에서 기대하는 점은? (선택)'
        ],
        status: MeetingStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Meeting(
        id: '4',
        hostId: 'host4',
        hostNickname: '혜진',
        title: '지속가능한 생활 실험',
        shortDescription: '환경을 생각하는 작은 실천들을 나누고 함께 시도해보는 모임입니다.',
        hostNote: '개인의 작은 실천이 모이면 큰 변화가 될 수 있다고 믿습니다. 함께 실험해볼 분들을 기다립니다.',
        description: '''환경 문제가 심각해지는 요즘, 개인적으로 할 수 있는 것들을 찾아 실천하고 있습니다.

이 모임에서는:
• 제로웨이스트 생활 팁
• 업사이클링 아이디어
• 지속가능한 소비 패턴

에 대해 이야기하고, 실제로 함께 시도해봅니다.''',
        meetingDate: DateTime.now().add(const Duration(days: 21)),
        location: '서울',
        locationDetail: '마포구 공유 작업실',
        maxParticipants: 7,
        interests: ['환경', '라이프스타일', '지속가능성'],
        format: MeetingFormat.offline,
        topicsCovered: [
          '개인 실천 방법',
          '실용적인 팁',
          '생활 속 변화'
        ],
        topicsNotCovered: [
          '환경 정책',
          '대규모 운동',
          '정치적 논의'
        ],
        conversationFlow: '실천 경험 공유 → 아이디어 나누기 → 다음 모임 실험 주제 정하기',
        applicationQuestions: [
          '이 주제에 관심을 갖게 된 이유는?',
          '이 모임에서 기대하는 점은? (선택)'
        ],
        status: MeetingStatus.open,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
    notifyListeners();
  }

  Meeting? getMeetingById(String id) {
    try {
      return _meetings.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Application? getApplicationByMeetingId(String meetingId, String userId) {
    try {
      return _applications.firstWhere(
        (a) => a.meetingId == meetingId && a.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  void setLocationFilter(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setInterestFilter(String? interest) {
    _selectedInterest = interest;
    notifyListeners();
  }

  void setFormatFilter(MeetingFormat? format) {
    _selectedFormat = format;
    notifyListeners();
  }

  void clearFilters() {
    _selectedLocation = null;
    _selectedInterest = null;
    _selectedFormat = null;
    notifyListeners();
  }

  Future<void> applyToMeeting(
    String meetingId,
    String userId,
    String answer1,
    String? answer2,
  ) async {
    _isLoading = true;
    notifyListeners();

    // 시뮬레이션: 실제로는 API 호출
    await Future.delayed(const Duration(seconds: 1));

    final application = Application(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      meetingId: meetingId,
      userId: userId,
      answer1: answer1,
      answer2: answer2,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
    );

    _applications.add(application);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMeetings() async {
    _isLoading = true;
    notifyListeners();

    // 시뮬레이션: 실제로는 API 호출
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
  }
}
