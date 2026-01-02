import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

class GallerySaver {
  static Future<void> saveImage(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 이미 main.dart에서 처리된 JPEG 이미지를 바로 갤러리에 저장
      // 중복 디코딩/인코딩 제거로 성능 개선
      await PhotoManager.editor.saveImageWithPath(
        path,
        title: 'photoit_${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      throw UnsupportedError('Gallery save is only supported on Android/iOS');
    }
  }
}
