import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_lib/share_lib_image_picker.dart';
import '../services/api_service.dart';
import '../providers/meeting_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kakao_map_location_picker.dart';
import '../widgets/age_range_selector.dart';
import '../widgets/category_picker_sheet.dart';
import '../models/meeting.dart';
import '../utils/region_hierarchy.dart';
import '../utils/photo_permission_helper.dart';
import 'meeting_detail_screen.dart';
import 'package:share_lib/share_lib.dart';

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
  DateTime? _selectedDateTime;
  int _minParticipants = 2;
  int _maxParticipants = 6;
  int? _ageRangeMin;
  int? _ageRangeMax;
  bool _enableGenderRatio = false;
  double _genderRatio = 0.5; // 0.0 = 여성만, 1.0 = 남성만, 0.5 = 5:5
  String? _approvalType;
  bool _enableQuestion = false;
  final TextEditingController _questionController = TextEditingController();
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  bool _isRequestingAi = false;
  final List<XFile> _selectedImages = [];
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
      _selectedDateTime = widget.meeting!.meetingDate;
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

      if (widget.meeting!.applicationQuestions != null &&
          widget.meeting!.applicationQuestions!.isNotEmpty) {
        _enableQuestion = true;
        _questionController.text = widget.meeting!.applicationQuestions!.first;
      }
    }
  }

  // 에러 상태 추적
  String? _titleError;
  String? _categoryError;
  String? _descriptionError;
  String? _dateTimeError;
  String? _locationError;
  String? _approvalTypeError;
  String? _applicationQuestionsError;

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
    _questionController.dispose();
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
              _locationController.text = RegionHierarchy.normalizeForFilter(address);
              _locationError = null;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 1);
    DateTime tempDate = _selectedDateTime ?? firstDate.add(const Duration(days: 1));
    TimeOfDay tempTime = _selectedDateTime != null
        ? TimeOfDay.fromDateTime(_selectedDateTime!)
        : const TimeOfDay(hour: 19, minute: 0);

    if (!context.mounted) return;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '날짜와 시간 선택',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CalendarDatePicker2(
                                config: CalendarDatePicker2Config(
                                  calendarType: CalendarDatePicker2Type.single,
                                  firstDate: firstDate,
                                  lastDate: lastDate,
                                  weekdayLabels: ['일', '월', '화', '수', '목', '금', '토'],
                                  firstDayOfWeek: 1,
                                  controlsHeight: 44,
                                  dayTextStyle: const TextStyle(fontSize: 15),
                                  selectedDayTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  selectedDayHighlightColor: Theme.of(context).primaryColor,
                                  todayTextStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                value: [tempDate],
                                onValueChanged: (dates) {
                                  final d = dates.isNotEmpty ? dates[0] : null;
                                  if (d != null) {
                                    setModalState(() => tempDate = d);
                                  }
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.access_time),
                                title: const Text('시간'),
                                subtitle: Text(
                                  tempTime.format(context),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: tempTime,
                                  );
                                  if (picked != null && context.mounted) {
                                    setModalState(() => tempTime = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final dt = DateTime(
                                    tempDate.year,
                                    tempDate.month,
                                    tempDate.day,
                                    tempTime.hour,
                                    tempTime.minute,
                                  );
                                  Navigator.pop(context, dt);
                                },
                                child: const Text('선택'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
    },
  );

    if (result != null && mounted) {
      setState(() {
        _selectedDateTime = result;
        _dateTimeError = null;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _requestAiIntroduction() async {
    setState(() => _isRequestingAi = true);
    try {
      void doGenerateIntro() async {
        if (!mounted) return;
        try {
          final api = context.read<ApiService>();
          final intro = await api.generateMeetingIntroduction(
            content: _descriptionController.text.trim(),
          );
          if (mounted) {
            setState(() {
              _descriptionController.text = intro;
              _descriptionError = null;
              _hasUnsavedChanges = true;
              _isRequestingAi = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isRequestingAi = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
      }

      if (kIsWeb) {
        // 웹에서는 AdService(Platform) 미지원으로 광고 스킵 후 바로 AI 생성
        doGenerateIntro();
      } else {
        await AdService.shared.showAd(
          onAdDismissed: doGenerateIntro,
          onAdFailedToShow: () {
            if (mounted) {
              setState(() => _isRequestingAi = false);
            }
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isRequestingAi = false);
    }
  }

  void _validateAndSetErrors() {
    setState(() {
      // 모든 에러 초기화
      _titleError = null;
      _categoryError = null;
      _descriptionError = null;
      _dateTimeError = null;
      _locationError = null;
      _approvalTypeError = null;
      _applicationQuestionsError = null;

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

      // 날짜·시간 검증
      if (_selectedDateTime == null) {
        _dateTimeError = '모임 날짜와 시간을 선택해주세요';
      } else if (_selectedDateTime!.isBefore(DateTime.now())) {
        _dateTimeError = '과거 날짜·시간은 선택할 수 없습니다';
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
        _dateTimeError != null ||
        _locationError != null ||
        _approvalTypeError != null ||
        _applicationQuestionsError != null;
  }

  /// 첫 번째 에러가 있는 섹션의 키 반환 (위에서부터 순서대로)
  GlobalKey? _getFirstErrorSectionKey() {
    if (_titleError != null) return _titleSectionKey;
    if (_categoryError != null) return _categorySectionKey;
    if (_descriptionError != null) return _descriptionSectionKey;
    if (_dateTimeError != null) return _dateTimeSectionKey;
    if (_locationError != null) return _locationSectionKey;
    if (_approvalTypeError != null) return _approvalSectionKey;
    if (_applicationQuestionsError != null) return _approvalSectionKey;
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
      final meetingDateTime = _selectedDateTime!;

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
      final approvalType =
          _approvalType == '즉시 참여' ? 'immediate' : 'approval_required';

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
          applicationQuestions: _enableQuestion && _questionController.text.trim().isNotEmpty
              ? [_questionController.text.trim()]
              : [],
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
          applicationQuestions: _enableQuestion && _questionController.text.trim().isNotEmpty
              ? [_questionController.text.trim()]
              : null,
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
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // 금지어 등 검증 에러: 필드별로 표시 (스넥바 사용 안 함)
      if (e is ApiValidationException && e.field != null) {
        setState(() {
          switch (e.field!) {
            case 'title':
              _titleError = e.message;
              break;
            case 'description':
              _descriptionError = e.message;
              break;
            case 'location':
              _locationError = e.message;
              break;
            case 'location_detail':
              _locationError = e.message;
              break;
            case 'application_questions':
              _applicationQuestionsError = e.message;
              break;
            default:
              _descriptionError = e.message;
              break;
          }
        });
        final targetKey = _getFirstErrorSectionKey();
        if (targetKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = targetKey.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                alignment: 0.1,
              );
            }
          });
        }
        return;
      }
      // 서버가 field 없이 금지어 메시지만 보낸 경우: 본문 아래에 표시
      final errMsg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      if (errMsg.contains('허용되지 않는 표현')) {
        setState(() => _descriptionError = errMsg);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _descriptionSectionKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          }
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.meeting != null
                ? '모임 수정에 실패했습니다: $errMsg'
                : '모임 생성에 실패했습니다: $errMsg',
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
                    InkWell(
                      onTap: () async {
                        final result = await CategoryPickerSheet.show(
                          context,
                          initial: _selectedCategory,
                        );
                        if (mounted && result != null) {
                          setState(() {
                            _selectedCategory = identical(result,
                                    CategoryPickerSheet.categoryClearSentinel)
                                ? null
                                : result as String;
                            _categoryError = null;
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: '카테고리를 선택하세요',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _categoryError != null
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.grey,
                          ),
                        ),
                        child: Text(
                          _selectedCategory ?? '',
                          style: TextStyle(
                            color: _selectedCategory != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
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
                    Row(
                      children: [
                        _buildSectionTitle('모임 소개 *'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed:
                              _isRequestingAi ? null : _requestAiIntroduction,
                          icon: _isRequestingAi
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('광고보고 AI에게 요청하기'),
                        ),
                      ],
                    ),
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
                    if (_dateTimeError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _dateTimeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDateTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: '날짜와 시간 선택',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _dateTimeError != null
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          suffixIcon: const Icon(Icons.calendar_month),
                        ),
                        child: Text(
                          _selectedDateTime != null
                              ? '${DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDateTime!)} ${DateFormat('a h:mm', 'ko_KR').format(_selectedDateTime!)}'
                              : '날짜와 시간',
                        ),
                      ),
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
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: '지도에서 위치 선택',
                              border: const OutlineInputBorder(),
                              errorText: _locationError,
                              errorStyle: const TextStyle(color: Colors.red),
                            ),
                            validator: _validateLocation,
                            onTap: _showKakaoMapLocationPicker,
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
                const SizedBox(height: 24),

                // 참가 전 질문 (선택)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '참가 전 질문 (선택)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Checkbox(
                      value: _enableQuestion,
                      onChanged: (value) {
                        setState(() {
                          _enableQuestion = value ?? false;
                          if (!_enableQuestion) _questionController.clear();
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),
                if (_enableQuestion) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionController,
                    onChanged: (_) {
                      _hasUnsavedChanges = true;
                      if (_applicationQuestionsError != null) {
                        setState(() => _applicationQuestionsError = null);
                      }
                    },
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '참가 신청 시 답변을 요청할 질문을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      errorText: _applicationQuestionsError,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '질문이 있으면 참가 신청 시 필수로 답변해야 합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.meeting != null ? '모임 수정 완료' : '모임 만들기',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

    if (!await requestPhotoPermission(context)) return;

    final remainingSlots =
        10 - (_selectedImages.length + _existingImageUrls.length);
    final images = await MediaPickerService.pickImages(
      context,
      maxCount: remainingSlots,
    );

    if (images != null && images.isNotEmpty) {
      final imagesToAdd = images.take(remainingSlots).toList();

      setState(() {
        _selectedImages.addAll(imagesToAdd);
        _hasUnsavedChanges = true;
      });

      if (images.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 10개까지 선택할 수 있습니다.')),
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
              // 새로 선택한 이미지 표시 (XFile 사용 - 웹/모바일 공통)
              ..._selectedImages.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<dynamic>(
                          future: entry.value.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            );
                          },
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
