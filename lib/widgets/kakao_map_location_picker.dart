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

/// 검색 결과 항목
class _SearchResultItem {
  final String placeName;
  final String address;
  final LatLng position;

  _SearchResultItem({
    required this.placeName,
    required this.address,
    required this.position,
  });

  String get displayText =>
      address.isNotEmpty ? '$placeName ($address)' : placeName;
}

class _KakaoMapLocationPickerState extends State<KakaoMapLocationPicker> {
  KakaoMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isGettingLocation = false;
  List<_SearchResultItem> _searchResults = [];
  LabelController? _searchMarkersLayer;
  LabelController? _selectionPinLayer;
  bool _isSheetExpanded = false;

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
    if (_searchResults.isNotEmpty) {
      _updateSearchMarkersOnMap();
    }
    if (_selectedLocation != null) {
      _updateSelectionPin();
    }
  }

  /// 지도 클릭 이벤트 핸들러
  void _onMapClick(KPoint point, LatLng position) {
    setState(() {
      _selectedLocation = position;
      _selectedAddress = null; // 주소 로딩 중
      _searchResults = []; // 지도 탭 시 검색 결과 리스트 닫기
    });
    _mapController?.moveCamera(CameraUpdate.newCenterPosition(position));
    _clearSearchMarkers();
    _updateSelectionPin();
    _getAddressFromCoordinates(position);
  }

  /// 지도를 해당 위치 중심으로 이동 (바텀 시트 가림 고려해 시각적 중앙에 배치)
  void _moveMapToCenter(LatLng position) {
    if (_mapController == null) return;
    // 계산: 바텀시트 1/3 가림 → 시각적 중앙 = 화면 상단 1/3 지점
    // 현재 중심은 화면 1/2 → 1/6 화면 높이만큼 위로 올려야 함
    // zoom 15, 서울 기준: 화면 높이 600px ≈ 0.02°(2km) → 1/6 = 100px ≈ 0.0033°
    const latOffset = 0.0033;
    final offsetPosition = LatLng(
      position.latitude - latOffset,
      position.longitude,
    );
    _mapController!.moveCamera(
      CameraUpdate.newCenterPosition(offsetPosition),
    );
  }

  /// 검색 결과 마커 제거
  Future<void> _clearSearchMarkers() async {
    if (_mapController == null || _searchMarkersLayer == null) return;
    try {
      await _mapController!.removeLabelLayer(_searchMarkersLayer!);
      if (mounted) {
        setState(() => _searchMarkersLayer = null);
      }
    } catch (e) {
      debugPrint('🔵 [KakaoMapLocationPicker] 마커 제거 오류: $e');
    }
  }

  /// 선택된 위치에 고정 핀 표시 (아이콘 사용, 줌과 무관하게 일정 크기)
  Future<void> _updateSelectionPin() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;

    try {
      if (_selectionPinLayer != null) {
        await controller.removeLabelLayer(_selectionPinLayer!);
        if (mounted) setState(() => _selectionPinLayer = null);
      }
      if (_selectedLocation == null) return;

      final layerId = 'selection_pin_${DateTime.now().millisecondsSinceEpoch}';
      final layer = await controller.addLabelLayer(layerId);
      if (!mounted) return;

      // Material Icons로 선택: Icons.place | Icons.location_on | Icons.add_location | Icons.pin_drop
      const pinIcon = Icons.place;
      const pinSize = Size(32, 32);
      final pinImage = await KImage.fromWidget(
        Icon(pinIcon, color: Colors.red.shade600, size: 32),
        pinSize,
        context: context,
      );
      if (!mounted) return;

      final pinStyle = PoiStyle(
        icon: pinImage,
        anchor: const KPoint(0.5, 1.0), // 핀 끝이 좌표를 가리킴
      );
      final poiId = 'selection_pin_${DateTime.now().millisecondsSinceEpoch}';
      await layer.addPoi(
        _selectedLocation!,
        style: pinStyle,
        id: poiId,
      );
      if (mounted) {
        setState(() => _selectionPinLayer = layer);
      }
    } catch (e) {
      debugPrint('🔵 [KakaoMapLocationPicker] 선택 핀 오류: $e');
    }
  }

  /// 검색 결과를 지도에 마커로 표시 (Flutter Icon 사용)
  Future<void> _updateSearchMarkersOnMap() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;

    await _clearSearchMarkers();
    if (_searchResults.isEmpty) return;

    try {
      final layerId = 'search_markers_${DateTime.now().millisecondsSinceEpoch}';
      final layer = await controller.addLabelLayer(layerId);
      if (!mounted) return;

      const markerIcon = Icons.place_outlined;
      const markerSize = Size(32, 32);
      final markerImage = await KImage.fromWidget(
        Icon(markerIcon, color: Colors.blue.shade600, size: 32),
        markerSize,
        context: context,
      );
      if (!mounted) return;

      final markerStyle = PoiStyle(
        icon: markerImage,
        anchor: const KPoint(0.5, 1.0),
      );

      for (var i = 0; i < _searchResults.length; i++) {
        await layer.addPoi(
          _searchResults[i].position,
          style: markerStyle,
          id: 'search_poi_$i',
        );
      }
      if (mounted) {
        setState(() => _searchMarkersLayer = layer);
      }
    } catch (e) {
      debugPrint('🔵 [KakaoMapLocationPicker] 마커 추가 오류: $e');
    }
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

  /// 검색 실행 (카카오맵 REST API - POI 키워드 검색)
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(query)}&size=15',
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['documents'] != null && data['documents'].isNotEmpty) {
          final documents = data['documents'] as List;
          final results = <_SearchResultItem>[];
          for (final place in documents) {
            final lat = double.parse(place['y'].toString());
            final lng = double.parse(place['x'].toString());
            final placeName = place['place_name'] ?? query;
            final roadAddress = place['road_address_name']?.toString() ?? '';
            final addressName = place['address_name']?.toString() ?? '';
            final address = roadAddress.isNotEmpty ? roadAddress : addressName;
            results.add(_SearchResultItem(
              placeName: placeName,
              address: address,
              position: LatLng(lat, lng),
            ));
          }

          if (mounted) {
            setState(() {
              _searchResults = results;
              // 첫 번째 결과로 지도 이동 및 선택
              final first = results.first;
              _selectedLocation = first.position;
              _selectedAddress = first.displayText;
            });
            _updateSearchMarkersOnMap();
            _updateSelectionPin();
          }

          if (results.isNotEmpty) {
            _moveMapToCenter(results.first.position);
          }
        } else {
          debugPrint('⚠️ [KakaoMapLocationPicker] 검색 결과가 없음');
          if (mounted) {
            setState(() => _searchResults = []);
            _clearSearchMarkers();
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

  /// 검색 결과 항목 선택 (지도 이동만)
  void _selectSearchResult(_SearchResultItem item) {
    setState(() {
      _selectedLocation = item.position;
      _selectedAddress = item.displayText;
    });
    _moveMapToCenter(item.position);
    _updateSelectionPin();
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
        _updateSelectionPin();

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
                      hintText: '장소 검색 (예: 압구정 와인바)',
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
          // 검색 결과가 없을 때(지도 탭·현재 위치)만 상단 선택 바 표시
          if (_searchResults.isEmpty && _selectedAddress != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAddress!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _confirmSelection,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('선택'),
                  ),
                ],
              ),
            ),
          // 카카오맵 + 바텀 시트
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 지도 영역 높이 기준으로 바텀 시트 높이 계산
                final mapHeight = constraints.maxHeight;
                final expandedHeight = mapHeight; // 펼침: 지도 전체 덮음
                final collapsedHeight = mapHeight * 0.5; // 접힘: 지도의 40%
                final sheetHeight =
                    _isSheetExpanded ? expandedHeight : collapsedHeight;
                return Stack(
                  children: [
                    KakaoMap(
                      onMapReady: onMapReady,
                      onMapClick: _onMapClick,
                      option: KakaoMapOption(
                        position: _selectedLocation ??
                            const LatLng(37.5665, 126.9780),
                      ),
                    ),
                    if (_searchResults.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          height: sheetHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 8, 12),
                                child: Row(
                                  children: [
                                    Text(
                                      '검색 결과 (${_searchResults.length}개)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(
                                        _isSheetExpanded
                                            ? Icons.expand_more
                                            : Icons.expand_less,
                                        color: Colors.grey.shade700,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isSheetExpanded = !_isSheetExpanded;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = _searchResults[index];
                                    final isSelected =
                                        _selectedAddress == item.displayText;
                                    return ListTile(
                                      leading: Icon(
                                        Icons.place,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 24,
                                      ),
                                      title: Text(
                                        item.placeName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color:
                                              isSelected ? Colors.blue : null,
                                        ),
                                      ),
                                      subtitle: item.address.isNotEmpty
                                          ? Text(
                                              item.address,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? Colors.blue.shade700
                                                    : Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                      trailing: isSelected
                                          ? TextButton(
                                              onPressed: _confirmSelection,
                                              style: TextButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF4285F4),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8,
                                                ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text('선택'),
                                            )
                                          : null,
                                      dense: true,
                                      onTap: () => _selectSearchResult(item),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed:
                            _isGettingLocation ? null : _moveToCurrentLocation,
                        backgroundColor: Colors.white,
                        child: _isGettingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, color: Colors.blue),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
