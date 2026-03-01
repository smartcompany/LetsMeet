import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_lib/share_lib_image_picker.dart';
import '../services/api_service.dart';
import '../utils/photo_permission_helper.dart';
import '../utils/ugc_moderation.dart';

class FeedCreateScreen extends StatefulWidget {
  const FeedCreateScreen({super.key});

  @override
  State<FeedCreateScreen> createState() => _FeedCreateScreenState();
}

class _FeedCreateScreenState extends State<FeedCreateScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    if (!await requestPhotoPermission(context)) return;
    final images = await MediaPickerService.pickImages(context, maxCount: 9);
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
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

      List<String> imageUrls = [];
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

      await apiService.createFeed(
        content: text,
        imageUrls: imageUrls,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('피드 등록 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('피드 쓰기'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitFeed,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '등록',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '오늘의 이야기를 들려주세요...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
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
                      child: const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }
}
