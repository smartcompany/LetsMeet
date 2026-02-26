import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android API 33+ → READ_MEDIA_IMAGES (Permission.photos)
/// Android API 32 이하 → READ_EXTERNAL_STORAGE (Permission.storage)
Future<Permission> _getPhotoPermissionForPlatform() async {
  if (!Platform.isAndroid) return Permission.photos;
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  return androidInfo.version.sdkInt >= 33 ? Permission.photos : Permission.storage;
}

/// 사진/앨범 접근 권한을 요청합니다.
/// Android 버전에 맞는 권한을 요청하고, 거부 시 설정 열기 안내를 합니다.
Future<bool> requestPhotoPermission(BuildContext context) async {
  final permission = await _getPhotoPermissionForPlatform();

  var status = await permission.status;
  if (status.isGranted || status.isLimited) return true;

  // 첫 요청 전 안내 (일부 기기에서 시스템 권한 창이 잘 뜨도록)
  if (status.isDenied && context.mounted) {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('앨범 접근 권한'),
        content: const Text(
          '사진을 선택하려면 앨범(사진 및 동영상) 접근 권한을 허용해 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (go != true) return false;
  }

  status = await permission.request();
  if (status.isGranted || status.isLimited) return true;

  // Android: 다른 권한으로 한 번 더 시도 (API 33+ ↔ 32 이하)
  if (Platform.isAndroid) {
    final other = permission == Permission.photos ? Permission.storage : Permission.photos;
    final otherStatus = await other.request();
    if (otherStatus.isGranted || otherStatus.isLimited) return true;
  }

  // 영구 거부 → 설정에서 허용 유도
  if (status.isPermanentlyDenied || !status.isGranted) {
    if (context.mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('앨범 접근 권한'),
          content: const Text(
            '사진을 선택하려면 설정에서 앨범(사진 및 동영상) 접근 권한을 허용해 주세요.\n\n설정 화면으로 이동할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('설정 열기'),
            ),
          ],
        ),
      );
      if (open == true) {
        await openAppSettings();
      }
    }
    return false;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('앨범 접근 권한이 필요합니다')),
    );
  }
  return false;
}
