// lib/core/utils/video_utils.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoUtils {
  static Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 400,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return null;
    }
  }

  static Future<int?> getVideoDuration(String videoPath) async {
    try {
      // This would require FFmpeg or similar
      // For now, return null
      return null;
    } catch (e) {
      print('Error getting video duration: $e');
      return null;
    }
  }

  static bool isValidVideoFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return false;

    final sizeInBytes = file.lengthSync();
    const maxSize = 100 * 1024 * 1024; // 100MB

    return sizeInBytes <= maxSize;
  }
}
