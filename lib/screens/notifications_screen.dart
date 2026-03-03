import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart' as auth_lib;
import '../models/meeting.dart';
import '../models/user.dart' as app_user;
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'meeting_applications_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Meeting> _meetingsWithPending = [];
  final ApiService _apiService = ApiService();

  Future<void> _load(BuildContext context) async {
    setState(() => _isLoading = true);
    final provider = context.read<NotificationProvider>();
    await provider.loadUnreadCount();
    final counts = provider.pendingCounts;
    if (counts.isEmpty) {
      if (mounted) {
        setState(() {
          _meetingsWithPending = [];
          _isLoading = false;
        });
      }
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final token = await user.getIdToken();
      if (token != null) _apiService.setToken(token);
      final meetings = await _apiService.getMeetings(
        hostId: user.uid,
        includeCompleted: false,
      );
      final withPending = meetings
          .where((m) => counts.containsKey(m.id) && (counts[m.id] ?? 0) > 0)
          .toList();
      if (mounted) {
        setState(() {
          _meetingsWithPending = withPending;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('받은 알림'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: Consumer<auth_lib.AuthProvider<app_user.User>>(
        builder: (context, authProvider, _) {
          if (authProvider.needProfileSetup()) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_rounded,
                    size: 64,
                    color: AppTheme.textTertiaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '로그인이 필요합니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_meetingsWithPending.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: AppTheme.textTertiaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '새 알림이 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }
          final provider = context.watch<NotificationProvider>();
          return RefreshIndicator(
            onRefresh: () => _load(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _meetingsWithPending.length,
              itemBuilder: (context, i) {
                final meeting = _meetingsWithPending[i];
                final count = provider.pendingCounts[meeting.id] ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.group_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      meeting.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('모임 신청 $count건이 있습니다'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MeetingApplicationsScreen(
                            meetingId: meeting.id,
                          ),
                        ),
                      );
                      if (context.mounted) _load(context);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
