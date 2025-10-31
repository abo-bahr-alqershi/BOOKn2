import 'package:equatable/equatable.dart';

class Attachment extends Equatable {
  final String id;
  final String conversationId;
  final String fileName;
  final String contentType; // MIME type
  final int fileSize;
  final String filePath;
  final String fileUrl;
  final String uploadedBy;
  final DateTime createdAt;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  // New optional fields used by UI
  final int? duration; // in seconds for audio/video
  final double? downloadProgress; // 0.0 - 1.0 (transient, not from backend)

  const Attachment({
    required this.id,
    required this.conversationId,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    required this.filePath,
    required this.fileUrl,
    required this.uploadedBy,
    required this.createdAt,
    this.thumbnailUrl,
    this.metadata,
    this.duration,
    this.downloadProgress,
  });

  @override
  List<Object?> get props => [
    id,
    conversationId,
    fileName,
    contentType,
    fileSize,
    filePath,
    fileUrl,
    uploadedBy,
    createdAt,
    thumbnailUrl,
    metadata,
    duration,
    downloadProgress,
  ];

  // Helper methods
  String get fileExtension => fileName.split('.').last.toLowerCase();
  
  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');
  bool get isAudio => contentType.startsWith('audio/');
  bool get isDocument => !isImage && !isVideo && !isAudio;
  
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class ChatSettings extends Equatable {
  final String id;
  final String userId;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool showReadReceipts;
  final bool showTypingIndicator;
  final String theme; // "light", "dark", "auto"
  final String fontSize; // "small", "medium", "large"
  final bool autoDownloadMedia;
  final bool backupMessages;

  const ChatSettings({
    required this.id,
    required this.userId,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.showReadReceipts = true,
    this.showTypingIndicator = true,
    this.theme = 'auto',
    this.fontSize = 'medium',
    this.autoDownloadMedia = true,
    this.backupMessages = false,
  });

  @override
  List<Object> get props => [
    id,
    userId,
    notificationsEnabled,
    soundEnabled,
    showReadReceipts,
    showTypingIndicator,
    theme,
    fontSize,
    autoDownloadMedia,
    backupMessages,
  ];
}