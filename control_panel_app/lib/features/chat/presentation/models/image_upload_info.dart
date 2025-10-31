import 'dart:io';

// معلومات رفع الصورة لعرض حالة الرفع في الواجهة
class ImageUploadInfo {
  final String id;
  final File? file;
  final double progress;
  final bool isCompleted;
  final bool isFailed;
  final String? error;

  const ImageUploadInfo({
    required this.id,
    this.file,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isFailed = false,
    this.error,
  });

  ImageUploadInfo copyWith({
    String? id,
    File? file,
    double? progress,
    bool? isCompleted,
    bool? isFailed,
    String? error,
  }) {
    return ImageUploadInfo(
      id: id ?? this.id,
      file: file ?? this.file,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      error: error ?? this.error,
    );
  }
}
