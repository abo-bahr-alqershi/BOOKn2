// lib/features/admin_properties/domain/entities/city_image.dart

import 'package:equatable/equatable.dart';

enum ImageCategory {
  exterior,
  interior,
  amenity,
  floorPlan,
  documents,
  avatar,
  cover,
  gallery,
  video,
}

enum ProcessingStatus {
  uploading,
  processing,
  ready,
  failed,
  deleted,
}

enum MediaType {
  image,
  video,
}

class CityImage extends Equatable {
  final String id;
  final String url;
  final String filename;
  final int size;
  final String mimeType;
  final int width;
  final int height;
  final String? alt;
  final DateTime uploadedAt;
  final String uploadedBy;
  final int order;
  final bool isPrimary;
  final String? cityId;
  final ImageCategory category;
  final List<String> tags;
  final ProcessingStatus processingStatus;
  final ImageThumbnails thumbnails;
  final MediaType mediaType; // إضافة نوع الوسائط
  final String? videoThumbnail; // إضافة thumbnail للفيديو
  final int? duration; // مدة الفيديو بالثواني

  const CityImage({
    required this.id,
    required this.url,
    required this.filename,
    required this.size,
    required this.mimeType,
    required this.width,
    required this.height,
    this.alt,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.order,
    required this.isPrimary,
    this.cityId,
    required this.category,
    this.tags = const [],
    required this.processingStatus,
    required this.thumbnails,
    this.mediaType = MediaType.image,
    this.videoThumbnail,
    this.duration,
  });

  bool get isReady => processingStatus == ProcessingStatus.ready;
  bool get isVideo => mediaType == MediaType.video;
  bool get isImage => mediaType == MediaType.image;
  String get sizeInMB => (size / (1024 * 1024)).toStringAsFixed(2);

  String get displayThumbnail {
    if (isVideo && videoThumbnail != null) return videoThumbnail!;
    return thumbnails.medium;
  }

  String get durationFormatted {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        url,
        filename,
        size,
        mimeType,
        width,
        height,
        alt,
        uploadedAt,
        uploadedBy,
        order,
        isPrimary,
        cityId,
        category,
        tags,
        processingStatus,
        thumbnails,
        mediaType,
        duration,
        videoThumbnail,
      ];
}

class ImageThumbnails extends Equatable {
  final String small;
  final String medium;
  final String large;
  final String hd;

  const ImageThumbnails({
    required this.small,
    required this.medium,
    required this.large,
    required this.hd,
  });

  @override
  List<Object> get props => [small, medium, large, hd];
}
