// lib/features/admin_reviews/data/models/review_response_model.dart

import 'package:bookn_cp_app/features/admin_reviews/domain/entities/review_response.dart';

class ReviewResponseModel extends ReviewResponse {
  const ReviewResponseModel({
    required super.id,
    required super.reviewId,
    required super.responseText,
    required super.respondedBy,
    required super.respondedByName,
    required super.createdAt,
    super.updatedAt,
  });
  
  factory ReviewResponseModel.fromJson(Map<String, dynamic> json) {
    return ReviewResponseModel(
      id: json['id'] as String,
      reviewId: json['reviewId'] as String,
      responseText: json['responseText'] as String,
      respondedBy: json['respondedBy'] as String,
      respondedByName: json['respondedByName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewId': reviewId,
      'responseText': responseText,
      'respondedBy': respondedBy,
      'respondedByName': respondedByName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}