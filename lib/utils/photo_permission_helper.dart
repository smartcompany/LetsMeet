import 'package:flutter/material.dart';

/// 사진 선택 시 권한은 피커(시스템)가 처리합니다.
/// 호출부 호환용으로 유지하며, 항상 true를 반환해 곧바로 pickImages()가 호출되도록 합니다.
/// (MyStyle 등과 동일: image_picker 등이 갤러리 오픈 시 시스템 권한 요청)
Future<bool> requestPhotoPermission(BuildContext context) async {
  return true;
}
