/// 한국 행정구역 계층 (시/도 -> 구/군/시)
/// 필터에서 1단계: 서울, 경기, 강원 등
/// 2단계: 서울 전체, 강남구, 강서구 등
class RegionHierarchy {
  /// 시/도 이름 -> 하위 구/군/시 목록
  /// "XXX 전체"는 해당 시/도 전체를 의미
  static const Map<String, List<String>> data = {
    '서울': [
      '서울 전체',
      '강남구',
      '강동구',
      '강북구',
      '강서구',
      '관악구',
      '광진구',
      '구로구',
      '금천구',
      '노원구',
      '도봉구',
      '동대문구',
      '동작구',
      '마포구',
      '서대문구',
      '서초구',
      '성동구',
      '성북구',
      '송파구',
      '양천구',
      '영등포구',
      '용산구',
      '은평구',
      '종로구',
      '중구',
      '중랑구',
    ],
    '부산': [
      '부산 전체',
      '강서구',
      '금정구',
      '기장군',
      '남구',
      '동구',
      '동래구',
      '부산진구',
      '북구',
      '사상구',
      '사하구',
      '서구',
      '수영구',
      '연제구',
      '영도구',
      '중구',
      '해운대구',
    ],
    '대구': [
      '대구 전체',
      '남구',
      '달서구',
      '달성군',
      '동구',
      '북구',
      '서구',
      '수성구',
      '중구',
    ],
    '인천': [
      '인천 전체',
      '강화군',
      '계양구',
      '미추홀구',
      '남동구',
      '동구',
      '부평구',
      '서구',
      '연수구',
      '옹진군',
      '중구',
    ],
    '광주': [
      '광주 전체',
      '광산구',
      '남구',
      '동구',
      '북구',
      '서구',
    ],
    '대전': [
      '대전 전체',
      '대덕구',
      '동구',
      '서구',
      '유성구',
      '중구',
    ],
    '울산': [
      '울산 전체',
      '남구',
      '동구',
      '북구',
      '중구',
      '울주군',
    ],
    '세종': ['세종 전체'],
    '경기': [
      '경기 전체',
      '가평군',
      '고양시',
      '과천시',
      '광명시',
      '광주시',
      '구리시',
      '군포시',
      '김포시',
      '남양주시',
      '동두천시',
      '부천시',
      '성남시',
      '수원시',
      '시흥시',
      '안산시',
      '안성시',
      '안양시',
      '양주시',
      '양평군',
      '여주시',
      '연천군',
      '오산시',
      '용인시',
      '의왕시',
      '의정부시',
      '이천시',
      '파주시',
      '평택시',
      '포천시',
      '하남시',
      '화성시',
    ],
    '강원': [
      '강원 전체',
      '강릉시',
      '고성군',
      '동해시',
      '삼척시',
      '속초시',
      '양구군',
      '양양군',
      '영월군',
      '원주시',
      '인제군',
      '정선군',
      '철원군',
      '춘천시',
      '태백시',
      '평창군',
      '홍천군',
      '화천군',
      '횡성군',
    ],
    '충북': [
      '충북 전체',
      '괴산군',
      '단양군',
      '보은군',
      '영동군',
      '옥천군',
      '음성군',
      '제천시',
      '증평군',
      '진천군',
      '청주시',
      '충주시',
    ],
    '충남': [
      '충남 전체',
      '계룡시',
      '공주시',
      '금산군',
      '논산시',
      '당진시',
      '보령시',
      '부여군',
      '서산시',
      '서천군',
      '아산시',
      '예산군',
      '천안시',
      '청양군',
      '태안군',
      '홍성군',
    ],
    '전북': [
      '전북 전체',
      '고창군',
      '군산시',
      '김제시',
      '남원시',
      '무주군',
      '부안군',
      '순창군',
      '완주군',
      '익산시',
      '임실군',
      '장수군',
      '전주시',
      '정읍시',
      '진안군',
    ],
    '전남': [
      '전남 전체',
      '강진군',
      '고흥군',
      '곡성군',
      '광양시',
      '구례군',
      '나주시',
      '담양군',
      '목포시',
      '무안군',
      '보성군',
      '순천시',
      '신안군',
      '여수시',
      '영광군',
      '영암군',
      '완도군',
      '장성군',
      '장흥군',
      '진도군',
      '함평군',
      '해남군',
      '화순군',
    ],
    '경북': [
      '경북 전체',
      '경산시',
      '경주시',
      '고령군',
      '구미시',
      '군위군',
      '김천시',
      '문경시',
      '봉화군',
      '상주시',
      '성주군',
      '안동시',
      '영덕군',
      '영양군',
      '영주시',
      '영천시',
      '예천군',
      '울릉군',
      '울진군',
      '의성군',
      '청도군',
      '청송군',
      '칠곡군',
      '포항시',
    ],
    '경남': [
      '경남 전체',
      '거제시',
      '거창군',
      '고성군',
      '김해시',
      '남해군',
      '밀양시',
      '사천시',
      '산청군',
      '양산시',
      '의령군',
      '진주시',
      '창녕군',
      '창원시',
      '통영시',
      '하동군',
      '함안군',
      '함양군',
      '합천군',
    ],
    '제주': [
      '제주 전체',
      '서귀포시',
      '제주시',
    ],
  };

  /// 1단계 시/도 목록
  static List<String> get topLevelRegions => data.keys.toList()..sort();

  /// 선택한 시/도 + 하위 지역으로 필터 매칭용 문자열 생성
  /// [region] 예: "서울", [subRegion] 예: "강남구" 또는 "서울 전체"
  static String toFilterValue(String region, String subRegion) {
    if (subRegion == '$region 전체' || subRegion.endsWith('전체')) {
      return _regionToLocationPrefix(region);
    }
    return '${_regionToLocationPrefix(region)} $subRegion'.trim();
  }

  static const Map<String, String> _regionPrefixMap = {
    '서울': '서울특별시',
    '부산': '부산광역시',
    '대구': '대구광역시',
    '인천': '인천광역시',
    '광주': '광주광역시',
    '대전': '대전광역시',
    '울산': '울산광역시',
    '세종': '세종특별자치시',
    '경기': '경기도',
    '강원': '강원특별자치도',
    '충북': '충청북도',
    '충남': '충청남도',
    '전북': '전북특별자치도',
    '전남': '전라남도',
    '경북': '경상북도',
    '경남': '경상남도',
    '제주': '제주특별자치도',
  };

  static String _regionToLocationPrefix(String region) =>
      _regionPrefixMap[region] ?? region;

  /// meeting.location이 선택된 필터 값과 매칭되는지 확인
  /// meetingLocation은 카카오맵 등 다양한 형식일 수 있으므로 정규화 후 비교
  static bool locationMatches(String? meetingLocation, String filterValue) {
    if (meetingLocation == null || meetingLocation.isEmpty) return false;
    final loc = normalizeForFilter(meetingLocation.trim());
    if (filterValue.endsWith('전체') || filterValue.contains(' 전체')) {
      final prefix = filterValue.replaceAll(' 전체', '').trim();
      return loc.contains(prefix) || loc.startsWith(prefix);
    }
    return loc.contains(filterValue) || loc.startsWith(filterValue);
  }

  /// region + subRegion -> API/저장용 전체 지역 문자열
  static String toFullLocationString(String region, String subRegion) {
    final prefix = _regionToLocationPrefix(region);
    if (subRegion == '$region 전체' || subRegion.endsWith('전체')) {
      return prefix;
    }
    return '$prefix $subRegion'.trim();
  }

  /// 카카오맵 등에서 받은 주소를 필터 매칭용으로 정규화
  /// "서울 강남구 압구정로 165" -> "서울특별시 강남구 압구정로 165"
  /// "홍대보니따 (서울 마포구 동교로 191)" -> "홍대보니따 (서울특별시 마포구 동교로 191)"
  static String normalizeForFilter(String address) {
    if (address.isEmpty) return address;
    String result = address;
    for (final entry in _regionPrefixMap.entries) {
      final short = entry.key;
      final full = entry.value;
      // 문자열 맨 앞이거나, 공백/괄호 뒤에 있는 지역 약칭을 정규화
      final pattern = RegExp(
        '(^|[\\s(])(${RegExp.escape(short)})(?=[\\s,]|\\d|\$)',
      );
      result = result.replaceAllMapped(
        pattern,
        (m) => '${m.group(1)!}$full',
      );
    }
    return result;
  }
}
