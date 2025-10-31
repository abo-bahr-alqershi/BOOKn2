import '../../domain/entities/attachment.dart';

class AttachmentModel extends Attachment {
  const AttachmentModel({
    required super.id,
    required super.conversationId,
    required super.fileName,
    required super.contentType,
    required super.fileSize,
    required super.filePath,
    required super.fileUrl,
    required super.uploadedBy,
    required super.createdAt,
    super.thumbnailUrl,
    super.metadata,
    super.duration,
    super.downloadProgress,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['attachment_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? '',
      contentType: json['mime_type'] ?? json['contentType'] ?? '',
      fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
      filePath: json['file_path'] ?? json['filePath'] ?? '',
      fileUrl: json['file_url'] ??
          '/api/common/chat/attachments/${json['attachment_id'] ?? json['id']}',
      uploadedBy: json['uploaded_by'] ?? json['uploadedBy'] ?? '',
      createdAt: DateTime.parse(
          json['uploaded_at'] ?? json['created_at'] ?? json['createdAt']),
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      metadata: json['metadata'],
      duration: _parseDurationSeconds(
          json['duration'] ?? json['video_duration'] ?? json['audio_duration']),
      downloadProgress: json['downloadProgress']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachment_id': id,
      'conversation_id': conversationId,
      'file_name': fileName,
      'mime_type': contentType,
      'file_size': fileSize,
      'file_path': filePath,
      'file_url': fileUrl,
      'uploaded_by': uploadedBy,
      'uploaded_at': createdAt.toIso8601String(),
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (metadata != null) 'metadata': metadata,
      if (duration != null) 'duration': duration,
      if (downloadProgress != null) 'downloadProgress': downloadProgress,
    };
  }

  factory AttachmentModel.fromEntity(Attachment attachment) {
    return AttachmentModel(
      id: attachment.id,
      conversationId: attachment.conversationId,
      fileName: attachment.fileName,
      contentType: attachment.contentType,
      fileSize: attachment.fileSize,
      filePath: attachment.filePath,
      fileUrl: attachment.fileUrl,
      uploadedBy: attachment.uploadedBy,
      createdAt: attachment.createdAt,
      thumbnailUrl: attachment.thumbnailUrl,
      metadata: attachment.metadata,
      duration: attachment.duration,
      downloadProgress: attachment.downloadProgress,
    );
  }
}

int? _parseDurationSeconds(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    // Try to parse ISO8601 duration or HH:mm:ss or seconds string
    final s = value.trim();
    if (RegExp(r'^\d+$').hasMatch(s)) return int.tryParse(s);
    // HH:mm:ss
    final parts = s.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final sec = int.tryParse(parts[2]) ?? 0;
      return h * 3600 + m * 60 + sec;
    }
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final sec = int.tryParse(parts[1]) ?? 0;
      return m * 60 + sec;
    }
  }
  return null;
}
