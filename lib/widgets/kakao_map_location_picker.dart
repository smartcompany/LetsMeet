import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

/// 카카오맵을 사용한 위치 선택 위젯
class KakaoMapLocationPicker extends StatefulWidget {
  /// 초기 검색어 (선택사항)
  final String? initialQuery;

  /// 위치 선택 콜백
  final Function(String address, double latitude, double longitude)
  onLocationSelected;

  const KakaoMapLocationPicker({
    super.key,
    this.initialQuery,
    required this.onLocationSelected,
  });

  @override
  State<KakaoMapLocationPicker> createState() => _KakaoMapLocationPickerState();
}

class _KakaoMapLocationPickerState extends State<KakaoMapLocationPicker> {
  KakaoMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isGettingLocation = false;

  // 카카오맵 REST API 키 (카카오 개발자 콘솔에서 발급)
  // TODO: 환경 변수나 설정 파일로 이동 권장
  static const String _kakaoRestApiKey = '54f361f6100300e5449e632fe4f7894e';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 지도 준비 완료 콜백
  void onMapReady(KakaoMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  /// 지도 클릭 이벤트 핸들러
  void _onMapClick(KPoint point, LatLng position) {
    setState(() {
      _selectedLocation = position;
      _selectedAddress = null; // 주소 로딩 중
    });
    _getAddressFromCoordinates(position);
  }

  /// 좌표를 주소로 변환 (카카오맵 REST API)
  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=${position.longitude}&y=${position.latitude}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $_kakaoRestApiKey'},
      );

      debugPrint(
        '🔵 [KakaoMapLocationPicker] 주소 변환 응답 상태: ${response.statusCode}',
      );
      debugPrint('🔵 [KakaoMapLocationPicker] 주소 변환 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['documents'] != null && data['documents'].isNotEmpty) {
          final address = data['documents'][0];
          final roadAddress = address['road_address'];
          final regionAddress = address['address'];

          // 도로명 주소 우선, 없으면 지번 주소 사용
          String? addressName;
          if (roadAddress != null && roadAddress['address_name'] != null) {
            addressName = roadAddress['address_name'] as String;
          } else if (regionAddress != null &&
              regionAddress['address_name'] != null) {
            addressName = regionAddress['address_name'] as String;
          }

          if (mounted) {
            setState(() {
              _selectedAddress = addressName ?? '주소를 찾을 수 없습니다';
            });
          }
        } else {
          debugPrint('⚠️ [KakaoMapLocationPicker] 주소 변환 결과가 비어있음');
          if (mounted) {
            setState(() {
              _selectedAddress = '주소를 찾을 수 없습니다';
            });
          }
        }
      } else {
        debugPrint(
          '❌ [KakaoMapLocationPicker] 주소 변환 실패: ${response.statusCode}',
        );
        debugPrint('❌ [KakaoMapLocationPicker] 응답 본문: ${response.body}');

        // 에러 응답 파싱 시도
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? '주소 변환 실패';
          debugPrint('❌ [KakaoMapLocationPicker] 에러 메시지: $errorMessage');
        } catch (_) {}

        if (mounted) {
          setState(() {
            _selectedAddress = '주소를 가져올 수 없습니다';
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [KakaoMapLocationPicker] 주소 변환 예외 발생: $e');
      debugPrint('❌ [KakaoMapLocationPicker] 스택 트레이스: $stackTrace');
      if (mounted) {
        setState(() {
          _selectedAddress = '주소를 가져오는 중 오류가 발생했습니다';
        });
      }
    }
  }

  /// 검색 실행 (카카오맵 REST API)
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(query)}&size=1',
      );

      debugPrint('🔵 [KakaoMapLocationPicker] 검색 URL: $url');
      debugPrint('🔵 [KakaoMapLocationPicker] 검색어: $query');

      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $_kakaoRestApiKey'},
      );

      debugPrint(
        '🔵 [KakaoMapLocationPicker] 검색 응답 상태: ${response.statusCode}',
      );
      debugPrint('🔵 [KakaoMapLocationPicker] 검색 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['documents'] != null && data['documents'].isNotEmpty) {
          final place = data['documents'][0];
          final lat = double.parse(place['y']);
          final lng = double.parse(place['x']);
          final position = LatLng(lat, lng);

          // 장소명과 주소 정보 조합
          final placeName = place['place_name'] ?? query;
          final roadAddress = place['road_address_name'] ?? '';
          final addressName = place['address_name'] ?? '';

          // 주소 정보가 있으면 장소명과 함께 표시, 없으면 장소명만
          String displayAddress = placeName;
          if (roadAddress.isNotEmpty) {
            displayAddress = '$placeName ($roadAddress)';
          } else if (addressName.isNotEmpty) {
            displayAddress = '$placeName ($addressName)';
          }

          if (_mapController != null) {
            _mapController!.moveCamera(
              CameraUpdate.newCenterPosition(position),
            );

            // 선택된 위치 업데이트
            setState(() {
              _selectedLocation = position;
              _selectedAddress = displayAddress;
            });
          }
        } else {
          debugPrint('⚠️ [KakaoMapLocationPicker] 검색 결과가 없음');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('검색 결과가 없습니다')));
          }
        }
      } else {
        debugPrint('❌ [KakaoMapLocationPicker] 검색 실패: ${response.statusCode}');
        debugPrint('❌ [KakaoMapLocationPicker] 응답 본문: ${response.body}');

        // 에러 응답 파싱 시도
        String errorMessage = '검색 중 오류가 발생했습니다';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$errorMessage (${response.statusCode})')),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [KakaoMapLocationPicker] 검색 예외 발생: $e');
      debugPrint('❌ [KakaoMapLocationPicker] 스택 트레이스: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  /// 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('위치 권한이 필요합니다')));
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요')),
          );
        }
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);

      // 지도 카메라 이동
      if (_mapController != null) {
        _mapController!.moveCamera(CameraUpdate.newCenterPosition(latLng));

        // 선택된 위치 업데이트
        setState(() {
          _selectedLocation = latLng;
        });

        // 주소 가져오기
        await _getAddressFromCoordinates(latLng);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현재 위치를 가져오는 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  /// 위치 선택 완료
  Future<void> _confirmSelection() async {
    if (_mapController != null) {
      try {
        // 현재 지도 중심 좌표를 선택된 위치로 사용
        final cameraPosition = await _mapController!.getCameraPosition();
        final position = _selectedLocation ?? cameraPosition.position;

        widget.onLocationSelected(
          _selectedAddress ?? '${position.latitude}, ${position.longitude}',
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('위치를 가져오는 중 오류가 발생했습니다: $e')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지도를 로드 중입니다. 잠시 후 다시 시도해주세요')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 선택'),
        actions: [
          TextButton(
            onPressed: _selectedAddress != null ? _confirmSelection : null,
            child: Text(
              '완료',
              style: TextStyle(
                color: _selectedAddress != null
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '장소 검색',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _performSearch,
                  ),
              ],
            ),
          ),
          // 선택된 위치 정보
          if (_selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAddress!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('선택'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 카카오맵
          Expanded(
            child: Stack(
              children: [
                KakaoMap(
                  onMapReady: onMapReady,
                  onMapClick: _onMapClick,
                  option: KakaoMapOption(
                    position:
                        _selectedLocation ??
                        const LatLng(37.5665, 126.9780), // 서울시청 기본 위치
                  ),
                ),
                // 현재 위치로 이동 버튼
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _isGettingLocation
                        ? null
                        : _moveToCurrentLocation,
                    backgroundColor: Colors.white,
                    child: _isGettingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          // 하단 선택 버튼
          if (_selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      '이 위치 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '지도를 탭하여 위치를 선택하세요',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
