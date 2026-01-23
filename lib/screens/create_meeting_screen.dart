import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../providers/meeting_provider.dart';
import '../theme/app_theme.dart';
import 'meeting_detail_screen.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _participationFeeController = TextEditingController(text: '0');
  
  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _maxParticipants = 6;
  int? _ageRangeMin;
  int? _ageRangeMax;
  String? _genderRestriction;
  String? _approvalType;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  
  // 에러 상태 추적
  String? _titleError;
  String? _categoryError;
  String? _descriptionError;
  String? _dateError;
  String? _timeError;
  String? _locationError;
  String? _approvalTypeError;

  final List<String> _categories = [
    '운동',
    '취미',
    '자기계발',
    '여행',
    '투자',
    '기타',
  ];

  final List<String> _genderOptions = ['전체', '남성', '여성'];
  final List<String> _approvalOptions = ['즉시 참여', '승인 필요 (호스트 승인)'];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _participationFeeController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participationFeeController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변경사항이 있습니다'),
        content: const Text('입력한 내용이 저장되지 않았습니다. 정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
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

  Future<void> _selectAgeRange() async {
    final minController = TextEditingController(text: _ageRangeMin?.toString() ?? '');
    final maxController = TextEditingController(text: _ageRangeMax?.toString() ?? '');

    final result = await showDialog<Map<String, int?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연령 제한'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              decoration: const InputDecoration(
                labelText: '최소 연령',
                hintText: '제한 없음',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              decoration: const InputDecoration(
                labelText: '최대 연령',
                hintText: '제한 없음',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, {'min': null, 'max': null}),
            child: const Text('제한 없음'),
          ),
          TextButton(
            onPressed: () {
              final min = minController.text.isEmpty
                  ? null
                  : int.tryParse(minController.text);
              final max = maxController.text.isEmpty
                  ? null
                  : int.tryParse(maxController.text);
              Navigator.pop(context, {'min': min, 'max': max});
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _ageRangeMin = result['min'];
        _ageRangeMax = result['max'];
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
      } else if (_selectedDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
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

  Future<void> _submitForm() async {
    _validateAndSetErrors();
    
    if (_hasErrors()) {
      // 에러가 있는 필드로 스크롤
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

      // Map gender restriction
      String? genderRestriction;
      if (_genderRestriction != null && _genderRestriction!.isNotEmpty) {
        switch (_genderRestriction) {
          case '전체':
            genderRestriction = 'all';
            break;
          case '남성':
            genderRestriction = 'male';
            break;
          case '여성':
            genderRestriction = 'female';
            break;
        }
      }

      // Map approval type
      final approvalType = _approvalType == '즉시 참여' ? 'immediate' : 'approval_required';

      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }

      final meeting = await apiService.createMeeting(
        title: _titleController.text.trim(),
        meetingDate: meetingDateTime,
        location: _locationController.text.trim(),
        maxParticipants: _maxParticipants,
        interests: [], // TODO: Get from user interests or allow selection
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        participationFee: fee > 0 ? fee : null,
        genderRestriction: genderRestriction,
        ageRangeMin: _ageRangeMin,
        ageRangeMax: _ageRangeMax,
        approvalType: approvalType,
      );

      // Refresh meetings list
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
      await meetingProvider.loadMeetings();

      if (!mounted) return;

      // Navigate to meeting detail
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MeetingDetailScreen(meetingId: meeting.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('모임 생성에 실패했습니다: ${e.toString()}'),
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
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            '모임 만들기',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
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
              const SizedBox(height: 24),

              // Category
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
                      color: _categoryError != null ? Colors.red : Colors.grey,
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
              const SizedBox(height: 24),

              // Description
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
              const SizedBox(height: 24),

              // Date and Time
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
                              color: _dateError != null ? Colors.red : Colors.grey,
                            ),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('yyyy년 MM월 dd일').format(_selectedDate!)
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
                              color: _timeError != null ? Colors.red : Colors.grey,
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
              const SizedBox(height: 24),

              // Location
              _buildSectionTitle('장소 *'),
              const SizedBox(height: 8),
              TextFormField(
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
              const SizedBox(height: 24),

              // Max Participants
              _buildSectionTitle('최대 인원 *'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _maxParticipants.toDouble(),
                      min: 2,
                      max: 20,
                      divisions: 18,
                      label: '$_maxParticipants명',
                      onChanged: (value) {
                        setState(() {
                          _maxParticipants = value.toInt();
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$_maxParticipants명',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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

              // Gender Restriction
              _buildSectionTitle('성별 제한 (선택)'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _genderRestriction,
                decoration: const InputDecoration(
                  hintText: '제한 없음',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('제한 없음')),
                  ..._genderOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _genderRestriction = value;
                    _hasUnsavedChanges = true;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Age Range
              _buildSectionTitle('연령 제한 (선택)'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectAgeRange,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    hintText: '제한 없음',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  child: Text(
                    _ageRangeMin != null || _ageRangeMax != null
                        ? '${_ageRangeMin ?? "제한 없음"}세 ~ ${_ageRangeMax ?? "제한 없음"}세'
                        : '제한 없음',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Approval Type
              _buildSectionTitle('참가 승인 방식 *'),
              const SizedBox(height: 8),
              ..._approvalOptions.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _approvalType,
                  onChanged: (value) {
                    setState(() {
                      _approvalType = value;
                      _hasUnsavedChanges = true;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '모임 만들기',
                          style: TextStyle(
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
    );
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
}
