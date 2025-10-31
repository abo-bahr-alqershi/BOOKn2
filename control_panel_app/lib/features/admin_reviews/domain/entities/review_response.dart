// lib/features/admin_reviews/domain/entities/review_response.dart

import 'package:equatable/equatable.dart';

class ReviewResponse extends Equatable {
  final String id;
  final String reviewId;
  final String responseText;
  final String respondedBy;
  final String respondedByName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const ReviewResponse({
    required this.id,
    required this.reviewId,
    required this.responseText,
    required this.respondedBy,
    required this.respondedByName,
    required this.createdAt,
    this.updatedAt,
  });
  
  @override
  List<Object?> get props => [
    id, reviewId, responseText, respondedBy,
    respondedByName, createdAt, updatedAt,
  ];
}