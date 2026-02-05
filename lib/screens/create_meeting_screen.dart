import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../providers/meeting_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kakao_map_location_picker.dart';
import '../widgets/age_range_selector.dart';
import '../models/meeting.dart';
import 'meeting_detail_screen.dart';

class CreateMeetingScreen extends StatefulWidget {
  final Meeting? meeting;
  const CreateMeetingScreen({super.key, this.meeting});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _participationFeeController = TextEditingController(text: '0');

  // 오류 발생 시 스크롤을 위한 섹션 키들
  final _titleSectionKey = GlobalKey();
  final _categorySectionKey = GlobalKey();
  final _descriptionSectionKey = GlobalKey();
  final _dateTimeSectionKey = GlobalKey();
  final _locationSectionKey = GlobalKey();
  final _approvalSectionKey = GlobalKey();

  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _minParticipants = 2;
  int _maxParticipants = 6;
  int? _ageRangeMin;
  int? _ageRangeMax;
  bool _enableGenderRatio = false;
  double _genderRatio = 0.5; // 0.0 = 여성만, 1.0 = 남성만, 0.5 = 5:5
  String? _approvalType;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = []; // 수정 모드에서 기존 이미지 URL

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _participationFeeController.addListener(_onFieldChanged);

    if (widget.meeting != null) {
      _titleController.text = widget.meeting!.title;
      _descriptionController.text = widget.meeting!.description ?? '';
      _locationController.text = widget.meeting!.location;
      _participationFeeController.text =
          widget.meeting!.participationFee?.toString() ?? '0';
      _selectedCategory = widget.meeting!.category;
      _selectedDate = widget.meeting!.meetingDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.meeting!.meetingDate);
      // _minParticipants 필드가 Meeting 모델에 없는 경우 기본값 사용
      _maxParticipants = widget.meeting!.maxParticipants;
      _ageRangeMin = widget.meeting!.ageRangeMin;
      _ageRangeMax = widget.meeting!.ageRangeMax;

      if (widget.meeting!.imageUrls != null) {
        _existingImageUrls.addAll(widget.meeting!.imageUrls!);
      }

      if (widget.meeting!.approvalType != null) {
        _approvalType = widget.meeting!.approvalType == ApprovalType.immediate
            ? '즉시 참여'
            : '승인 필요 (호스트 승인)';
      }

      if (widget.meeting!.genderRestriction != null &&
          widget.meeting!.genderRestriction != GenderRestriction.all) {
        _enableGenderRatio = true;
      }
    }
  }

  // 에러 상태 추적
  String? _titleError;
  String? _categoryError;
  String? _descriptionError;
  String? _dateError;
  String? _timeError;
  String? _locationError;
  String? _approvalTypeError;

  final List<String> _categories = ['운동', '취미', '자기계발', '여행', '투자', '기타'];

  final List<String> _approvalOptions = ['즉시 참여', '승인 필요 (호스트 승인)'];

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participationFeeController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return true;
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '모임 제목을 입력해주세요';
    }
    if (value.length > 40) {
      return '제목은 40자 이하여야 합니다';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '모임 소개를 입력해주세요';
    }
    if (value.length < 20) {
      return '모임 소개는 최소 20자 이상이어야 합니다';
    }
    if (value.length > 500) {
      return '모임 소개는 최대 500자까지 입력 가능합니다';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '장소를 입력해주세요';
    }
    return null;
  }

  String? _validateParticipationFee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '0';
    }
    final fee = int.tryParse(value);
    if (fee == null || fee < 0) {
      return '참가 비용은 0원 이상이어야 합니다';
    }
    return null;
  }

  /// 카카오맵으로 위치 선택
  Future<void> _showKakaoMapLocationPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KakaoMapLocationPicker(
          initialQuery: _locationController.text.trim(),
          onLocationSelected: (address, latitude, longitude) {
            setState(() {
              _locationController.text = address;
              _locationError = null;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeError = null;
        _hasUnsavedChanges = true;
      });
    }
  }

  void _validateAndSetErrors() {
    setState(() {
      // 모든 에러 초기화
      _titleError = null;
      _categoryError = null;
      _descriptionError = null;
      _dateError = null;
      _timeError = null;
      _locationError = null;
      _approvalTypeError = null;

      // 제목 검증
      if (_titleController.text.trim().isEmpty) {
        _titleError = '모임 제목을 입력해주세요';
      } else if (_titleController.text.length > 40) {
        _titleError = '제목은 40자 이하여야 합니다';
      }

      // 카테고리 검증
      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
        _categoryError = '카테고리를 선택해주세요';
      }

      // 설명 검증
      if (_descriptionController.text.trim().isEmpty) {
        _descriptionError = '모임 소개를 입력해주세요';
      } else if (_descriptionController.text.trim().length < 20) {
        _descriptionError = '모임 소개는 최소 20자 이상이어야 합니다';
      } else if (_descriptionController.text.length > 500) {
        _descriptionError = '모임 소개는 최대 500자까지 입력 가능합니다';
      }

      // 날짜 검증
      if (_selectedDate == null) {
        _dateError = '모임 날짜를 선택해주세요';
      } else if (_selectedDate!.isBefore(
        DateTime.now().subtract(const Duration(days: 1)),
      )) {
        _dateError = '과거 날짜는 선택할 수 없습니다';
      }

      // 시간 검증
      if (_selectedTime == null) {
        _timeError = '모임 시간을 선택해주세요';
      }

      // 장소 검증
      if (_locationController.text.trim().isEmpty) {
        _locationError = '장소를 입력해주세요';
      }

      // 승인 방식 검증
      if (_approvalType == null || _approvalType!.isEmpty) {
        _approvalTypeError = '참가 승인 방식을 선택해주세요';
      }
    });
  }

  bool _hasErrors() {
    return _titleError != null ||
        _categoryError != null ||
        _descriptionError != null ||
        _dateError != null ||
        _timeError != null ||
        _locationError != null ||
        _approvalTypeError != null;
  }

  /// 첫 번째 에러가 있는 섹션의 키 반환 (위에서부터 순서대로)
  GlobalKey? _getFirstErrorSectionKey() {
    if (_titleError != null) return _titleSectionKey;
    if (_categoryError != null) return _categorySectionKey;
    if (_descriptionError != null) return _descriptionSectionKey;
    if (_dateError != null || _timeError != null) return _dateTimeSectionKey;
    if (_locationError != null) return _locationSectionKey;
    if (_approvalTypeError != null) return _approvalSectionKey;
    return null;
  }

  Future<void> _submitForm() async {
    _validateAndSetErrors();

    // 에러가 있는지 확인하기 위해 잠시 대기 (setState 반영 보장)
    await Future.delayed(Duration.zero);

    if (_hasErrors()) {
      // 에러가 있는 첫 번째 섹션으로 스크롤
      final targetKey = _getFirstErrorSectionKey();

      if (targetKey != null) {
        // 렌더링 완료 후 확실하게 스크롤하기 위해 프레임 콜백 사용
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = targetKey.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          }
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine date and time
      final meetingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Parse participation fee
      final fee = int.tryParse(_participationFeeController.text) ?? 0;

      // Map gender restriction from ratio
      String? genderRestriction;
      if (_enableGenderRatio) {
        if (_genderRatio == 0.0) {
          genderRestriction = 'female'; // 여성만
        } else if (_genderRatio == 1.0) {
          genderRestriction = 'male'; // 남성만
        } else {
          genderRestriction = 'all'; // 성비 무관 (5:5 포함)
        }
      } else {
        genderRestriction = 'all'; // 체크 안하면 제한 없음
      }

      // Map approval type
      final approvalType = _approvalType == '즉시 참여'
          ? 'immediate'
          : 'approval_required';

      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }

      // 이미지 업로드
      List<String> imageUrls = List.from(_existingImageUrls);
      for (final imageFile in _selectedImages) {
        try {
          final imageUrl = await apiService.uploadMeetingImage(imageFile);
          imageUrls.add(imageUrl);
        } catch (e) {
          debugPrint('이미지 업로드 실패: $e');
        }
      }

      if (widget.meeting != null) {
        await apiService.updateMeeting(
          widget.meeting!.id,
          title: _titleController.text.trim(),
          meetingDate: meetingDateTime,
          location: _locationController.text.trim(),
          maxParticipants: _maxParticipants,
          minParticipants: _minParticipants,
          interests: [_selectedCategory!],
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          participationFee: fee > 0 ? fee : null,
          genderRestriction: genderRestriction,
          ageRangeMin: _ageRangeMin,
          ageRangeMax: _ageRangeMax,
          approvalType: approvalType,
          imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        );
      } else {
        final meeting = await apiService.createMeeting(
          title: _titleController.text.trim(),
          meetingDate: meetingDateTime,
          location: _locationController.text.trim(),
          maxParticipants: _maxParticipants,
          minParticipants: _minParticipants,
          interests: [
            _selectedCategory!,
          ], // TODO: Get from user interests or allow selection
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          participationFee: fee > 0 ? fee : null,
          genderRestriction: genderRestriction,
          ageRangeMin: _ageRangeMin,
          ageRangeMax: _ageRangeMax,
          approvalType: approvalType,
          imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        );

        // Refresh meetings list
        final meetingProvider = Provider.of<MeetingProvider>(
          context,
          listen: false,
        );
        await meetingProvider.loadMeetings();

        if (!mounted) return;

        // Navigate to meeting detail
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MeetingDetailScreen(meetingId: meeting.id),
          ),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모임이 수정되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.meeting != null
                ? '모임 수정에 실패했습니다: ${e.toString()}'
                : '모임 생성에 실패했습니다: ${e.toString()}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimaryColor,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.meeting != null ? '모임 수정' : '모임 만들기',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Column(
                  key: _titleSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('모임 제목 *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '모임 제목을 입력하세요 (최대 40자)',
                        border: const OutlineInputBorder(),
                        errorText: _titleError,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      maxLength: 40,
                      validator: _validateTitle,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() {
                            _titleError = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category
                Column(
                  key: _categorySectionKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('모임 카테고리 *'),
                    if (_categoryError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _categoryError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        hintText: '카테고리를 선택하세요',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _categoryError != null
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _categoryError = null;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Images
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('모임 사진 (최대 10개)'),
                    const SizedBox(height: 8),
                    _buildImagePicker(),
                  ],
                ),
                const SizedBox(height: 24),

                // Description
                Column(
                  key: _descriptionSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('모임 소개 *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: '모임 분위기, 대상, 기대 효과를 설명해주세요 (20-500자)',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        errorText: _descriptionError,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      maxLines: 5,
                      maxLength: 500,
                      validator: _validateDescription,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) {
                        if (_descriptionError != null) {
                          setState(() {
                            _descriptionError = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Date and Time
                Column(
                  key: _dateTimeSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('모임 날짜 *'),
                    if (_dateError != null || _timeError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _dateError ?? _timeError ?? '',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                hintText: '날짜 선택',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _dateError != null
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _selectedDate != null
                                    ? DateFormat(
                                        'yyyy년 MM월 dd일',
                                      ).format(_selectedDate!)
                                    : '날짜 선택',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                hintText: '시간 선택',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _timeError != null
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                                suffixIcon: const Icon(Icons.access_time),
                              ),
                              child: Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : '시간 선택',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Location
                Column(
                  key: _locationSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('장소 *'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: '예: 합정역 근처 카페, 강남 연습실',
                              border: const OutlineInputBorder(),
                              errorText: _locationError,
                              errorStyle: const TextStyle(color: Colors.red),
                            ),
                            validator: _validateLocation,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_locationError != null) {
                                setState(() {
                                  _locationError = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.map_outlined),
                          color: AppTheme.primaryColor,
                          tooltip: '지도에서 위치 선택',
                          onPressed: _showKakaoMapLocationPicker,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Min and Max Participants
                _buildSectionTitle('인원 설정 *'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '인원 범위',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_minParticipants명 ~ $_maxParticipants명',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: RangeValues(
                          _minParticipants.toDouble(),
                          _maxParticipants.toDouble(),
                        ),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        labels: RangeLabels(
                          '$_minParticipants명',
                          '$_maxParticipants명',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _minParticipants = values.start.toInt();
                            _maxParticipants = values.end.toInt();
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Participation Fee
                _buildSectionTitle('참가 비용 (선택)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _participationFeeController,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(),
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateParticipationFee,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                // Gender Ratio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '성비 설정',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Checkbox(
                      value: _enableGenderRatio,
                      onChanged: (value) {
                        setState(() {
                          _enableGenderRatio = value ?? false;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),
                if (_enableGenderRatio) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.woman,
                                  color: Colors.pink,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${((1 - _genderRatio) * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _getGenderRatioText(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${(_genderRatio * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.man,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbColor: AppTheme.primaryColor,
                            overlayColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(
                            value: _genderRatio,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                _genderRatio = value;
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Age Range
                _buildSectionTitle('연령 제한 (선택)'),
                const SizedBox(height: 8),
                AgeRangeSelector(
                  minAge: _ageRangeMin,
                  maxAge: _ageRangeMax,
                  onChanged: (min, max) {
                    setState(() {
                      _ageRangeMin = min;
                      _ageRangeMax = max;
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Approval Type
                Column(
                  key: _approvalSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('참가 승인 방식 *'),
                    if (_approvalTypeError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _approvalTypeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ..._approvalOptions.map((option) {
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: _approvalType,
                        onChanged: (value) {
                          setState(() {
                            _approvalType = value;
                            _approvalTypeError = null;
                            _hasUnsavedChanges = true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.meeting != null ? '모임 수정 완료' : '모임 만들기',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGenderRatioText() {
    if (_genderRatio == 0.0) {
      return '여성만';
    } else if (_genderRatio == 1.0) {
      return '남성만';
    } else if (_genderRatio == 0.5) {
      return '5:5';
    } else if (_genderRatio < 0.5) {
      return '여성 우대';
    } else {
      return '남성 우대';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length + _existingImageUrls.length >= 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최대 10개까지 선택할 수 있습니다.')));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      final remainingSlots =
          10 - (_selectedImages.length + _existingImageUrls.length);
      final imagesToAdd = images.take(remainingSlots).toList();

      setState(() {
        _selectedImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
        _hasUnsavedChanges = true;
      });

      if (images.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${remainingSlots}개만 추가되었습니다. (최대 10개)')),
        );
      }
    }
  }

  Widget _buildImagePicker() {
    final totalImages = _selectedImages.length + _existingImageUrls.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (totalImages < 10)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                ),
              const SizedBox(width: 8),
              // 기존 이미지 표시
              ..._existingImageUrls.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          entry.value,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _existingImageUrls.removeAt(entry.key),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // 새로 선택한 이미지 표시
              ..._selectedImages.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          entry.value,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _selectedImages.removeAt(entry.key),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (totalImages > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$totalImages / 10',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
      ],
    );
  }
}
