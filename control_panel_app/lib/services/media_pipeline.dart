import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class MediaPreprocessResult {
  final String uploadPath;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final int? durationSeconds;

  const MediaPreprocessResult({
    required this.uploadPath,
    this.thumbnailPath,
    this.width,
    this.height,
    this.durationSeconds,
  });
}

class MediaPipeline {
  Future<MediaPreprocessResult> preprocess({
    required String filePath,
    required String messageType,
  }) async {
    try {
      if (messageType == 'image') {
        // Compress image: resize to a reasonable bound and encode as JPEG
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            // Limit longest side to 1920px to balance quality/size
            final int maxSide = 1920;
            final int w = decoded.width;
            final int h = decoded.height;
            img.Image imageForEncode = decoded;
            if (w > maxSide || h > maxSide) {
              imageForEncode = img.copyResize(
                decoded,
                width: w >= h ? maxSide : (w * maxSide ~/ h),
                height: h > w ? maxSide : (h * maxSide ~/ w),
                interpolation: img.Interpolation.average,
              );
            }
            final compressed = img.encodeJpg(imageForEncode, quality: 82);
            final tmpDir = await getTemporaryDirectory();
            final outPath = '${tmpDir.path}/cmp_${DateTime.now().microsecondsSinceEpoch}.jpg';
            final outFile = File(outPath);
            await outFile.writeAsBytes(compressed, flush: true);
            return MediaPreprocessResult(
              uploadPath: outPath,
              width: imageForEncode.width,
              height: imageForEncode.height,
            );
          }
        }
        // Fallback: original file if anything failed
        return MediaPreprocessResult(uploadPath: filePath);
      }

      if (messageType == 'video') {
        final tmpDir = await getTemporaryDirectory();
        final thumb = await VideoThumbnail.thumbnailFile(
          video: filePath,
          thumbnailPath: tmpDir.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 512,
          quality: 75,
        );
        return MediaPreprocessResult(
          uploadPath: filePath,
          thumbnailPath: thumb,
        );
      }

      // For images/doc/audio keep path as-is (safe default). Compression can be added later.
      return MediaPreprocessResult(uploadPath: filePath);
    } catch (_) {
      return MediaPreprocessResult(uploadPath: filePath);
    }
  }
}
