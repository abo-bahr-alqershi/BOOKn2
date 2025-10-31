// lib/features/admin_reviews/data/models/review_image_model.dart

import 'package:bookn_cp_app/features/admin_reviews/domain/entities/review_image.dart';

class ReviewImageModel extends ReviewImage {
  const ReviewImageModel({
    required super.id,
    required super.reviewId,
    required super.name,
    required super.url,
    required super.sizeBytes,
    required super.type,
    required super.category,
    required super.caption,
    required super.altText,
    required super.uploadedAt,
  });
  
  factory ReviewImageModel.fromJson(Map<String, dynamic> json) {
    return ReviewImageModel(
      id: json['id'] as String,
      reviewId: json['reviewId'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      sizeBytes: json['sizeBytes'] as int,
      type: json['type'] as String,
      category: _parseCategory(json['category']),
      caption: json['caption'] as String,
      altText: json['altText'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
  
  static ImageCategory _parseCategory(dynamic value) {
    // Backend serializes enums as strings (JsonStringEnumConverter)
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'exterior':
          return ImageCategory.exterior;
        case 'interior':
          return ImageCategory.interior;
        case 'amenity':
          return ImageCategory.amenity;
        case 'floorplan':
        case 'floor_plan':
          return ImageCategory.floorPlan;
        case 'documents':
          return ImageCategory.documents;
        case 'avatar':
          return ImageCategory.avatar;
        case 'cover':
          return ImageCategory.cover;
        case 'gallery':
          return ImageCategory.gallery;
      }
    }
    if (value is int) {
      // Fallback if server ever sends numeric
      final index = value;
      final values = ImageCategory.values;
      if (index >= 0 && index < values.length) {
        return values[index];
      }
    }
    return ImageCategory.gallery;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewId': reviewId,
      'name': name,
      'url': url,
      'sizeBytes': sizeBytes,
      'type': type,
      // Keep string value to match backend JsonStringEnumConverter
      'category': _categoryToString(category),
      'caption': caption,
      'altText': altText,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  static String _categoryToString(ImageCategory category) {
    switch (category) {
      case ImageCategory.exterior:
        return 'Exterior';
      case ImageCategory.interior:
        return 'Interior';
      case ImageCategory.amenity:
        return 'Amenity';
      case ImageCategory.floorPlan:
        return 'FloorPlan';
      case ImageCategory.documents:
        return 'Documents';
      case ImageCategory.avatar:
        return 'Avatar';
      case ImageCategory.cover:
        return 'Cover';
      case ImageCategory.gallery:
        return 'Gallery';
    }
  }
}