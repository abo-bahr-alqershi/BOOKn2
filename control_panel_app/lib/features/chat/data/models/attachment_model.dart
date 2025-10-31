import 'dart:io';
import 'dart:convert';
import '../../domain/entities/attachment.dart';

/// نموذج المرفقات مع دعم كامل لجميع أنواع الوسائط
class AttachmentModel extends Attachment {
  const AttachmentModel({
    required super.id,
    required super.conversationId,
    required super.fileName,
    required super.contentType,
    required super.fileSize,
    required super.filePath,
    required super.fileUrl,
    required super.url,
    required super.uploadedBy,
    required super.createdAt,
    super.thumbnailUrl,
    super.metadata,
    super.duration,
    super.downloadProgress,
    super.uploadProgress,
    super.isUploading,
    super.uploadError,
    super.localFile,
    super.width,
    super.height,
    super.blurhash,
  });

  /// إنشاء نموذج من JSON مع معالجة شاملة للبيانات
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['attachment_id'] ?? json['id'] ?? '',
      conversationId: json['conversation_id'] ?? json['conversationId'] ?? '',
      fileName: _extractFileName(json),
      contentType: _resolveContentType(json),
      fileSize: _parseFileSize(json),
      filePath: json['file_path'] ?? json['filePath'] ?? '',
      fileUrl: _buildFileUrl(json),
      url: _buildUrl(json),
      uploadedBy: json['uploaded_by'] ?? json['uploadedBy'] ?? '',
      createdAt: _parseDateTime(json),
      thumbnailUrl: _extractThumbnailUrl(json),
      metadata: _parseMetadata(json),
      duration: _parseDuration(json),
      downloadProgress: _parseProgress(json['downloadProgress']),
      uploadProgress: _parseProgress(json['uploadProgress']),
      isUploading: json['isUploading'] ?? false,
      uploadError: json['uploadError'],
      localFile: json['localFile'] != null ? File(json['localFile']) : null,
      width: _parseIntSafe(json['width']),
      height: _parseIntSafe(json['height']),
      blurhash: json['blurhash'],
    );
  }

  /// تحويل النموذج إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'attachment_id': id,
      'conversation_id': conversationId,
      'file_name': fileName,
      'mime_type': contentType,
      'file_size': fileSize,
      'file_path': filePath,
      'file_url': fileUrl,
      'url': url,
      'uploaded_by': uploadedBy,
      'uploaded_at': createdAt.toIso8601String(),
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (metadata != null) 'metadata': metadata,
      if (duration != null) 'duration': duration,
      if (downloadProgress != null) 'downloadProgress': downloadProgress,
      if (uploadProgress != null) 'uploadProgress': uploadProgress,
      if (isUploading) 'isUploading': isUploading,
      if (uploadError != null) 'uploadError': uploadError,
      if (localFile != null) 'localFile': localFile!.path,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (blurhash != null) 'blurhash': blurhash,
    };
  }

  /// إنشاء نموذج من Entity
  factory AttachmentModel.fromEntity(Attachment attachment) {
    if (attachment is AttachmentModel) return attachment;

    return AttachmentModel(
      id: attachment.id,
      conversationId: attachment.conversationId,
      fileName: attachment.fileName,
      contentType: attachment.contentType,
      fileSize: attachment.fileSize,
      filePath: attachment.filePath,
      fileUrl: attachment.fileUrl,
      url: attachment.url,
      uploadedBy: attachment.uploadedBy,
      createdAt: attachment.createdAt,
      thumbnailUrl: attachment.thumbnailUrl,
      metadata: attachment.metadata,
      duration: attachment.duration,
      downloadProgress: attachment.downloadProgress,
      uploadProgress: attachment.uploadProgress,
      isUploading: attachment.isUploading,
      uploadError: attachment.uploadError,
      localFile: attachment.localFile,
      width: attachment.width,
      height: attachment.height,
      blurhash: attachment.blurhash,
    );
  }

  /// نسخ النموذج مع التحديثات
  AttachmentModel copyWith({
    String? id,
    String? conversationId,
    String? fileName,
    String? contentType,
    int? fileSize,
    String? filePath,
    String? fileUrl,
    String? url,
    String? uploadedBy,
    DateTime? createdAt,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    int? duration,
    double? downloadProgress,
    double? uploadProgress,
    bool? isUploading,
    String? uploadError,
    File? localFile,
    int? width,
    int? height,
    String? blurhash,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      url: url ?? this.url,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      duration: duration ?? this.duration,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      uploadError: uploadError ?? this.uploadError,
      localFile: localFile ?? this.localFile,
      width: width ?? this.width,
      height: height ?? this.height,
      blurhash: blurhash ?? this.blurhash,
    );
  }

  // ========== دوال مساعدة خاصة ==========

  /// استخراج اسم الملف بذكاء
  static String _extractFileName(Map<String, dynamic> json) {
    final fileName = json['file_name'] ?? json['fileName'] ?? '';
    if (fileName.isNotEmpty) return fileName;

    // محاولة استخراج من URL
    final url = json['file_url'] ?? json['url'] ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          return segments.last;
        }
      }
    }

    return 'attachment_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// تحديد نوع المحتوى بذكاء
  static String _resolveContentType(Map<String, dynamic> json) {
    // أولاً: التحقق من القيمة المباشرة
    final directType =
        json['mime_type'] ?? json['contentType'] ?? json['content_type'];
    if (directType != null && directType.toString().isNotEmpty) {
      return directType.toString();
    }

    // ثانياً: الاستنتاج من اسم الملف أو URL
    final fileName = _extractFileName(json);
    final ext = fileName.split('.').last.toLowerCase();

    // خريطة الامتدادات إلى أنواع MIME
    const extensionMap = {
      // صور
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'ico': 'image/x-icon',

      // فيديو
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      '3gp': 'video/3gpp',

      // صوت
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'opus': 'audio/opus',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'flac': 'audio/flac',
      'wma': 'audio/x-ms-wma',

      // مستندات
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'rtf': 'application/rtf',
      'csv': 'text/csv',

      // أرشيف
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',
    };

    return extensionMap[ext] ?? 'application/octet-stream';
  }

  /// تحليل حجم الملف
  static int _parseFileSize(Map<String, dynamic> json) {
    final size = json['file_size'] ?? json['fileSize'] ?? json['size'];
    if (size == null) return 0;
    if (size is int) return size;
    if (size is String) return int.tryParse(size) ?? 0;
    if (size is double) return size.round();
    return 0;
  }

  /// بناء URL الملف
  static String _buildFileUrl(Map<String, dynamic> json) {
    // 1) URL المباشر إذا توفر
    final directUrl = json['file_url'] ?? json['fileUrl'] ?? json['url'];
    if (directUrl != null && directUrl.toString().isNotEmpty) {
      return directUrl.toString();
    }

    // 2) المسار الثابت للملف (مفضل للعرض العام عبر imageBaseUrl)
    final filePath = json['file_path'] ?? json['filePath'];
    if (filePath != null && filePath.toString().isNotEmpty) {
      return filePath.toString();
    }

    // 3) مسار API كحل أخير (قد يتطلب صلاحيات؛ يفضل تجنبه للعرض المباشر)
    final id = json['attachment_id'] ?? json['id'];
    if (id != null && id.toString().isNotEmpty) {
      return '/api/common/chat/attachments/$id';
    }

    return '';
  }

  /// بناء URL العام
  static String _buildUrl(Map<String, dynamic> json) {
    final url = json['url'];
    if (url != null && url.toString().isNotEmpty) return url.toString();
    return _buildFileUrl(json);
  }

  /// تحليل التاريخ والوقت
  static DateTime _parseDateTime(Map<String, dynamic> json) {
    final dateStr = json['uploaded_at'] ??
        json['created_at'] ??
        json['createdAt'] ??
        json['timestamp'];

    if (dateStr != null) {
      final parsed = DateTime.tryParse(dateStr.toString());
      if (parsed != null) return parsed;
    }

    return DateTime.now();
  }

  /// استخراج URL الصورة المصغرة
  static String? _extractThumbnailUrl(Map<String, dynamic> json) {
    final thumb = json['thumbnail_url'] ??
        json['thumbnailUrl'] ??
        json['thumb_url'] ??
        json['preview_url'];

    if (thumb != null && thumb.toString().isNotEmpty) {
      return thumb.toString();
    }

    // للصور، يمكن استخدام نفس URL مع معاملات
    final contentType = _resolveContentType(json);
    if (contentType.startsWith('image/')) {
      final url = _buildFileUrl(json);
      if (url.isNotEmpty) {
        return '$url?w=200&h=200&mode=crop';
      }
    }

    return null;
  }

  /// تحليل البيانات الوصفية
  static Map<String, dynamic>? _parseMetadata(Map<String, dynamic> json) {
    final meta = json['metadata'] ?? json['meta'];
    if (meta == null) return null;

    if (meta is Map<String, dynamic>) return meta;
    if (meta is String) {
      try {
        final decoded = jsonDecode(meta);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }

    return null;
  }

  /// تحليل المدة (للفيديو والصوت)
  static int? _parseDuration(Map<String, dynamic> json) {
    final duration = json['duration'] ??
        json['video_duration'] ??
        json['audio_duration'] ??
        json['length'];

    if (duration == null) return null;
    if (duration is int) return duration;
    if (duration is double) return duration.round();
    if (duration is String) {
      // محاولة تحليل تنسيقات مختلفة
      final intValue = int.tryParse(duration);
      if (intValue != null) return intValue;

      // تنسيق HH:mm:ss
      final parts = duration.split(':');
      if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        return h * 3600 + m * 60 + s;
      }
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return m * 60 + s;
      }
    }

    return null;
  }

  /// تحليل نسبة التقدم
  static double? _parseProgress(dynamic value) {
    if (value == null) return null;
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is int) return value.toDouble().clamp(0.0, 100.0) / 100.0;
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        if (parsed > 1.0) return parsed / 100.0;
        return parsed.clamp(0.0, 1.0);
      }
    }
    return null;
  }

  /// تحليل الأعداد الصحيحة بأمان
  static int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
