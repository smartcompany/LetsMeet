import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_comment.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String feedId;
  const CommentsBottomSheet({super.key, required this.feedId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FeedComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }
      final comments = await apiService.getFeedComments(widget.feedId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('댓글을 입력해주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }

      final comment = await apiService.createFeedComment(
        widget.feedId,
        _commentController.text.trim(),
      );

      setState(() {
        _comments.add(comment);
        _commentController.clear();
        _isSubmitting = false;
      });

      // 댓글 목록 하단으로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 작성 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '댓글',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              ),
              // 댓글 목록
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? Center(
                        child: Text(
                          '아직 댓글이 없습니다.',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      comment.userProfileImage != null
                                      ? NetworkImage(comment.userProfileImage!)
                                      : null,
                                  child: comment.userProfileImage == null
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                                  radius: 16,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            comment.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat(
                                              'MM.dd HH:mm',
                                            ).format(comment.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              // 댓글 입력 영역
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: '댓글을 입력하세요...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSubmitting ? null : _submitComment,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
