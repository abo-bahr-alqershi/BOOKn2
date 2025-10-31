// lib/features/admin_reviews/domain/entities/review_image.dart

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
}

class ReviewImage extends Equatable {
  final String id;
  final String reviewId;
  final String name;
  final String url;
  final int sizeBytes;
  final String type;
  final ImageCategory category;
  final String caption;
  final String altText;
  final DateTime uploadedAt;
  
  const ReviewImage({
    required this.id,
    required this.reviewId,
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.type,
    required this.category,
    required this.caption,
    required this.altText,
    required this.uploadedAt,
  });
  
  @override
  List<Object> get props => [
    id, reviewId, name, url, sizeBytes,
    type, category, caption, altText, uploadedAt,
  ];
}