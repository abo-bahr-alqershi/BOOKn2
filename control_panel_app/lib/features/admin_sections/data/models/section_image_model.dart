// lib/features/admin_properties/data/models/unit_image_model.dart

import 'package:bookn_cp_app/core/constants/api_constants.dart';
import 'package:bookn_cp_app/core/constants/app_constants.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/entities/section_image.dart';

class SectionImageModel extends SectionImage {
  const SectionImageModel({
    required super.id,
    required super.url,
    required super.filename,
    required super.size,
    required super.mimeType,
    required super.width,
    required super.height,
    super.alt,
    required super.uploadedAt,
    required super.uploadedBy,
    required super.order,
    required super.isPrimary,
    super.sectionId,
    super.propertyInSectionId,
    super.unitInSectionId,
    required super.category,
    super.tags,
    required super.processingStatus,
    required super.thumbnails,
    super.mediaType,
    super.duration,
    super.videoThumbnail,
  });

  static String _validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://via.placeholder.com/400x300?text=No+Image';
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('/')) {
        return '${ApiConstants.imageBaseUrl}$url';
      }
      return 'https://via.placeholder.com/400x300?text=$url';
    }

    return url;
  }

  static MediaType _detectMediaType(Map<String, dynamic> json) {
    // التحقق من mediaType المباشر
    if (json['mediaType'] != null) {
      return _parseMediaType(json['mediaType'].toString());
    }

    // التحقق من mimeType
    final mimeType = json['mimeType']?.toString() ?? '';
    if (mimeType.startsWith('video/')) {
      return MediaType.video;
    }

    // التحقق من الملف
    final filename = json['filename']?.toString() ?? '';
    if (AppConstants.isVideoFile(filename)) {
      return MediaType.video;
    }

    return MediaType.image;
  }

  factory SectionImageModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
      } else if (json['tags'] is String) {
        final tagsString = json['tags'] as String;
        if (tagsString.isNotEmpty) {
          parsedTags = tagsString
              .split(RegExp(r'[,\s]+'))
              .where((tag) => tag.isNotEmpty)
              .toList();
        }
      }
    }

    final url =
        _validateUrl(json['url'] ?? json['imageUrl'] ?? json['videoUrl']);
    final mediaType = _detectMediaType(json);
    final videoThumbnail = mediaType == MediaType.video
        ? _validateUrl(
            json['videoThumbnail'] ?? json['thumbnail'] ?? json['poster'])
        : null;

    return SectionImageModel(
      id: (json['id'] ??
          json['imageId'] ??
          json['videoId'] ??
          DateTime.now().millisecondsSinceEpoch.toString()) as String,
      url: url,
      filename: (json['filename'] ?? json['name'] ?? 'media.jpg') as String,
      size: (json['size'] as num?)?.toInt() ?? 0,
      mimeType: (json['mimeType'] ?? json['type'] ?? 'image/jpeg') as String,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      alt: json['alt'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      uploadedBy: (json['uploadedBy'] ?? json['ownerId'] ?? '') as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isPrimary: (json['isPrimary'] as bool?) ?? false,
      sectionId: json['sectionId']?.toString(),
      propertyInSectionId: json['propertyInSectionId']?.toString(),
      unitInSectionId: json['unitInSectionId']?.toString(),
      category: _parseImageCategory((json['category'] ?? 'gallery').toString()),
      tags: parsedTags,
      processingStatus: _parseProcessingStatus(
          (json['processingStatus'] ?? 'ready').toString()),
      thumbnails: _parseThumbnails(json['thumbnails'], videoThumbnail ?? url),
      mediaType: mediaType,
      duration: (json['duration'] as num?)?.toInt(),
      videoThumbnail: videoThumbnail,
    );
  }

  static ImageThumbnails _parseThumbnails(
      dynamic thumbnailsData, String fallbackUrl) {
    if (thumbnailsData == null) {
      return ImageThumbnailsModel(
        small: fallbackUrl,
        medium: fallbackUrl,
        large: fallbackUrl,
        hd: fallbackUrl,
      );
    }

    if (thumbnailsData is Map<String, dynamic>) {
      return ImageThumbnailsModel.fromJson(thumbnailsData, fallbackUrl);
    }

    if (thumbnailsData is String) {
      final validUrl = _validateUrl(thumbnailsData);
      return ImageThumbnailsModel(
        small: validUrl,
        medium: validUrl,
        large: validUrl,
        hd: validUrl,
      );
    }

    return ImageThumbnailsModel(
      small: fallbackUrl,
      medium: fallbackUrl,
      large: fallbackUrl,
      hd: fallbackUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'width': width,
      'height': height,
      'alt': alt,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
      'order': order,
      'isPrimary': isPrimary,
      'sectionId': sectionId,
      'propertyInSectionId': propertyInSectionId,
      'unitInSectionId': unitInSectionId,
      'category': _imageCategoryToString(category),
      'tags': tags,
      'processingStatus': _processingStatusToString(processingStatus),
      'thumbnails': (thumbnails as ImageThumbnailsModel).toJson(),
      'mediaType': _mediaTypeToString(mediaType),
      if (duration != null) 'duration': duration,
      if (videoThumbnail != null) 'videoThumbnail': videoThumbnail,
    };
  }

  static ImageCategory _parseImageCategory(String value) {
    switch (value.toLowerCase()) {
      case 'exterior':
        return ImageCategory.exterior;
      case 'interior':
        return ImageCategory.interior;
      case 'amenity':
        return ImageCategory.amenity;
      case 'floor_plan':
      case 'floorplan':
        return ImageCategory.floorPlan;
      case 'documents':
        return ImageCategory.documents;
      case 'avatar':
        return ImageCategory.avatar;
      case 'cover':
        return ImageCategory.cover;
      case 'video':
        return ImageCategory.video;
      default:
        return ImageCategory.gallery;
    }
  }

  static String _imageCategoryToString(ImageCategory category) {
    switch (category) {
      case ImageCategory.exterior:
        return 'exterior';
      case ImageCategory.interior:
        return 'interior';
      case ImageCategory.amenity:
        return 'amenity';
      case ImageCategory.floorPlan:
        return 'floor_plan';
      case ImageCategory.documents:
        return 'documents';
      case ImageCategory.avatar:
        return 'avatar';
      case ImageCategory.cover:
        return 'cover';
      case ImageCategory.gallery:
        return 'gallery';
      case ImageCategory.video:
        return 'video';
    }
  }

  static ProcessingStatus _parseProcessingStatus(String value) {
    switch (value.toLowerCase()) {
      case 'uploading':
        return ProcessingStatus.uploading;
      case 'processing':
        return ProcessingStatus.processing;
      case 'ready':
        return ProcessingStatus.ready;
      case 'failed':
        return ProcessingStatus.failed;
      case 'deleted':
        return ProcessingStatus.deleted;
      default:
        return ProcessingStatus.processing;
    }
  }

  static String _processingStatusToString(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.uploading:
        return 'uploading';
      case ProcessingStatus.processing:
        return 'processing';
      case ProcessingStatus.ready:
        return 'ready';
      case ProcessingStatus.failed:
        return 'failed';
      case ProcessingStatus.deleted:
        return 'deleted';
    }
  }

  static MediaType _parseMediaType(String value) {
    switch (value.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'image':
      default:
        return MediaType.image;
    }
  }

  static String _mediaTypeToString(MediaType type) {
    switch (type) {
      case MediaType.video:
        return 'video';
      case MediaType.image:
        return 'image';
    }
  }
}

class ImageThumbnailsModel extends ImageThumbnails {
  const ImageThumbnailsModel({
    required super.small,
    required super.medium,
    required super.large,
    required super.hd,
  });

  factory ImageThumbnailsModel.fromJson(Map<String, dynamic> json,
      [String? fallbackUrl]) {
    final fallback =
        fallbackUrl ?? 'https://via.placeholder.com/400x300?text=No+Image';
    return ImageThumbnailsModel(
      small: SectionImageModel._validateUrl(
          json['small'] ?? json['s'] ?? fallback),
      medium: SectionImageModel._validateUrl(
          json['medium'] ?? json['m'] ?? fallback),
      large: SectionImageModel._validateUrl(
          json['large'] ?? json['l'] ?? fallback),
      hd: SectionImageModel._validateUrl(json['hd'] ?? json['xl'] ?? fallback),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'small': small,
      'medium': medium,
      'large': large,
      'hd': hd,
    };
  }
}
