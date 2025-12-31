import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class GallerySaver {
  static Future<void> saveImage(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 1. Read the original image file
      final originalFile = File(path);
      final imageBytes = await originalFile.readAsBytes();

      // 2. Decode the image
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        // Handle case where image decoding fails
        return;
      }

      // 3. Encode the image as a compressed JPEG (e.g., 85% quality)
      final compressedImageBytes = img.encodeJpg(originalImage, quality: 85);

      // 4. Get a temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_image.jpg';
      final tempFile = File(tempPath);

      // 5. Write the compressed image to the temporary file
      await tempFile.writeAsBytes(compressedImageBytes);


      // 6. Save the compressed image to the gallery
      await PhotoManager.editor.saveImageWithPath(
        tempPath,
        title: 'photoit_${DateTime.now().millisecondsSinceEpoch}',
      );

      // 7. Clean up the temporary file
      await tempFile.delete();

    } else {
      throw UnsupportedError('Gallery save is only supported on Android/iOS');
    }
  }
}
