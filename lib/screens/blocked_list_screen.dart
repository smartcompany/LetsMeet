import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../app_auth_provider.dart';

class BlockedListScreen extends StatefulWidget {
  const BlockedListScreen({super.key});

  @override
  State<BlockedListScreen> createState() => _BlockedListScreenState();
}

class _BlockedListScreenState extends State<BlockedListScreen> {
  bool _loading = true;
  List<BlockedUserInfo> _list = [];
  final Set<String> _unblockingIds = {};

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.shared.getBlockedUsers();
      if (mounted) {
        setState(() {
          _list = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목록을 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _unblock(BlockedUserInfo user) async {
    if (_unblockingIds.contains(user.userId)) return;
    setState(() => _unblockingIds.add(user.userId));
    try {
      await ApiService.shared.unblockUser(user.userId);
      if (mounted) {
        setState(() {
          _list.removeWhere((e) => e.userId == user.userId);
          _unblockingIds.remove(user.userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${user.fullName ?? user.userId} 님 차단을 해제했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _unblockingIds.remove(user.userId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('차단 해제에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('차단 목록'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 64,
                        color: AppTheme.textTertiaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '차단한 사용자가 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final u = _list[index];
                      final isUnblocking = _unblockingIds.contains(u.userId);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.dividerColor.withOpacity(0.5)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: u.profileImageUrl != null &&
                                    u.profileImageUrl!.isNotEmpty
                                ? NetworkImage(u.profileImageUrl!)
                                : null,
                            child: u.profileImageUrl == null ||
                                    u.profileImageUrl!.isEmpty
                                ? Text(
                                    (u.fullName?.isNotEmpty == true
                                            ? u.fullName!.substring(0, 1)
                                            : '?')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: AppTheme.textSecondaryColor),
                                  )
                                : null,
                          ),
                          title: Text(
                            u.fullName?.isNotEmpty == true
                                ? u.fullName!
                                : '알 수 없음',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: isUnblocking
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('차단 해제'),
                                        content: Text(
                                          '${u.fullName ?? u.userId} 님의 차단을 해제하시겠습니까?\n해제하면 해당 사용자의 피드와 댓글이 다시 보입니다.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('취소'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('차단 해제'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) await _unblock(u);
                                  },
                            child: isUnblocking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('차단 해제'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
