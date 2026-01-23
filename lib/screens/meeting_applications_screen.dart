import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/application.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MeetingApplicationsScreen extends StatefulWidget {
  final String meetingId;

  const MeetingApplicationsScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<MeetingApplicationsScreen> createState() =>
      _MeetingApplicationsScreenState();
}

class _MeetingApplicationsScreenState
    extends State<MeetingApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          _apiService.setToken(token);
        }
      }

      final applications = await _apiService.getApplications(widget.meetingId);

      if (!mounted) return;

      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveApplication(String applicationId) async {
    try {
      await _apiService.approveApplication(applicationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신청이 승인되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('승인 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectApplication(String applicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신청 거절'),
        content: const Text('정말 이 신청을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.rejectApplication(applicationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신청이 거절되었습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('거절 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신청 관리'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        '신청 목록을 불러올 수 없습니다',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadApplications,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppTheme.textTertiaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '아직 신청이 없습니다',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final applicationData = _applications[index];
                          final application = Application.fromJson(applicationData);
                          return _ApplicationCard(
                            applicationData: applicationData,
                            onApprove: application.status ==
                                    ApplicationStatus.pending
                                ? () => _approveApplication(application.id)
                                : null,
                            onReject: application.status ==
                                    ApplicationStatus.pending
                                ? () => _rejectApplication(application.id)
                                : null,
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> applicationData;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ApplicationCard({
    required this.applicationData,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final application = Application.fromJson(applicationData);
    final userInfo = applicationData['letsmeet_users'] as Map<String, dynamic>?;
    final userNickname = userInfo?['nickname'] ?? '알 수 없음';
    final userTrustScore = userInfo?['trust_score'] ?? 0;

    final statusColor = {
      ApplicationStatus.pending: Colors.orange,
      ApplicationStatus.approved: Colors.green,
      ApplicationStatus.rejected: Colors.red,
      ApplicationStatus.cancelled: Colors.grey,
    }[application.status];

    final statusText = {
      ApplicationStatus.pending: '대기 중',
      ApplicationStatus.approved: '승인됨',
      ApplicationStatus.rejected: '거절됨',
      ApplicationStatus.cancelled: '취소됨',
    }[application.status];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    userNickname.isNotEmpty ? userNickname[0] : '?',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userNickname,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '신뢰도: $userTrustScore',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor ?? Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusText ?? '',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (application.answer1 != null) ...[
              const SizedBox(height: 16),
              Text(
                '답변 1',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                application.answer1!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (application.answer2 != null) ...[
              const SizedBox(height: 16),
              Text(
                '답변 2',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                application.answer2!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '신청일: ${DateFormat('yyyy년 M월 d일 HH:mm', 'ko_KR').format(application.appliedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiaryColor,
                  ),
            ),
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    TextButton(
                      onPressed: onReject,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('거절'),
                    ),
                  if (onApprove != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('승인'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
