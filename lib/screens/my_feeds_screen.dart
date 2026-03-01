import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_lib/share_lib_image_picker.dart';
import '../services/api_service.dart';
import '../models/feed.dart';
import '../utils/photo_permission_helper.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../utils/ugc_moderation.dart';

class MyFeedsScreen extends StatefulWidget {
  const MyFeedsScreen({super.key});

  @override
  State<MyFeedsScreen> createState() => _MyFeedsScreenState();
}

class _MyFeedsScreenState extends State<MyFeedsScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = []; // 수정 모드에서 기존 이미지 URL
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Feed> _myFeeds = [];
  String? _editingFeedId; // 수정 중인 피드 ID

  @override
  void initState() {
    super.initState();
    _loadMyFeeds();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMyFeeds() async {
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
      final feeds = await apiService.getMyFeeds();
      setState(() {
        _myFeeds = feeds..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('피드를 불러오는데 실패했습니다: $e')));
      }
    }
  }

  Future<void> _pickImages() async {
    if (!await requestPhotoPermission(context)) return;
    final files = await MediaPickerService.pickImages(context, maxCount: 9);
    if (files != null && files.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(files);
      });
    }
  }

  void _startEdit(Feed feed) {
    setState(() {
      _editingFeedId = feed.id;
      _contentController.text = feed.content;
      _selectedImages.clear();
      _existingImageUrls.clear();
      _existingImageUrls.addAll(feed.imageUrls);
      // 작성 영역으로 스크롤
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingFeedId = null;
      _contentController.clear();
      _selectedImages.clear();
      _existingImageUrls.clear();
    });
  }

  Future<void> _deleteFeed(String feedId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('피드 삭제'),
        content: const Text('정말로 이 피드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ApiService();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          apiService.setToken(token);
        }
      }

      await apiService.deleteFeed(feedId);
      await _loadMyFeeds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('피드 삭제 실패: $e')));
      }
    }
  }

  Future<void> _submitFeed() async {
    final text = _contentController.text.trim();
    final validationError = UGCModeration.validateText(text);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
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

      List<String> imageUrls = List.from(_existingImageUrls);
      for (var image in _selectedImages) {
        try {
          final url = await apiService.uploadFeedImage(File(image.path));
          imageUrls.add(url);
        } catch (e) {
          setState(() => _isSubmitting = false);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('이미지 업로드 실패: $e')));
          }
          return;
        }
      }

      if (_editingFeedId != null) {
        // 수정 모드
        await apiService.updateFeed(
          _editingFeedId!,
          content: text,
          imageUrls: imageUrls,
        );
      } else {
        // 생성 모드
        await apiService.createFeed(
          content: text,
          imageUrls: imageUrls,
        );
      }

      final wasEditing = _editingFeedId != null;

      // 작성/수정 후 폼 초기화
      setState(() {
        _contentController.clear();
        _selectedImages.clear();
        _existingImageUrls.clear();
        _editingFeedId = null;
        _isSubmitting = false;
      });

      if (wasEditing) {
        await _loadMyFeeds();
      } else {
        // 새 피드 등록 시 이전 페이지로 이동 (피드 탭에서 새로고침 + SnackBar는 호출자가 처리)
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingFeedId != null ? '피드 수정 실패: $e' : '피드 등록 실패: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 피드 보기')),
      body: RefreshIndicator(
        onRefresh: _loadMyFeeds,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 피드 작성 영역
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingFeedId != null ? '피드 수정' : '새 피드 작성',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_editingFeedId != null)
                          TextButton(
                            onPressed: _cancelEdit,
                            child: const Text('취소'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '오늘의 이야기를 들려주세요...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                              ),
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
                                        () => _existingImageUrls.removeAt(
                                          entry.key,
                                        ),
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
                                      File(entry.value.path),
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
                                        () =>
                                            _selectedImages.removeAt(entry.key),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(_editingFeedId != null ? '수정' : '등록'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 내 피드 목록
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_myFeeds.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.feed_outlined,
                        size: 64,
                        color: AppTheme.textTertiaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '작성한 피드가 없습니다.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final feed = _myFeeds[index];
                  return _FeedCard(
                    feed: feed,
                    onEdit: () => _startEdit(feed),
                    onDelete: () => _deleteFeed(feed.id),
                  );
                }, childCount: _myFeeds.length),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Feed feed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _FeedCard({
    required this.feed,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: feed.authorProfileImage != null
                      ? NetworkImage(feed.authorProfileImage!)
                      : null,
                  child: feed.authorProfileImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('yyyy.MM.dd HH:mm').format(feed.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (feed.imageUrls.isNotEmpty)
            Container(
              width: double.infinity,
              height: 280,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: PageView.builder(
                itemCount: feed.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    feed.imageUrls[index],
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          Padding(padding: const EdgeInsets.all(16), child: Text(feed.content)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text('${feed.likeCount}', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${feed.commentCount}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
