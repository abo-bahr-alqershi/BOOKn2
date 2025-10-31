import '../../domain/entities/review.dart';
import 'review_image_model.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.userId,
    required super.userName,
    super.userAvatar,
    required super.bookingId,
    required super.propertyId,
    required super.cleanliness,
    required super.service,
    required super.location,
    required super.value,
    required super.rating,
    required super.title,
    required super.comment,
    required super.createdAt,
    super.updatedAt,
    required super.images,
    required super.isUserReview,
    required super.likesCount,
    required super.isLikedByUser,
    super.managementReply,
    super.bookingType,
    required super.isRecommended,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      bookingId: json['bookingId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      cleanliness: json['cleanliness'] ?? 0,
      service: json['service'] ?? 0,
      location: json['location'] ?? 0,
      value: json['value'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      title: json['title'] ?? '',
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      images: (json['images'] as List?)
              ?.map((e) => ReviewImageModel.fromJson(e))
              .toList() ??
          [],
      isUserReview: json['isUserReview'] ?? false,
      likesCount: json['likesCount'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      managementReply: json['managementReply'] != null
          ? ReviewReplyModel.fromJson(json['managementReply'])
          : null,
      bookingType: json['bookingType'],
      isRecommended: json['isRecommended'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'bookingId': bookingId,
      'propertyId': propertyId,
      'cleanliness': cleanliness,
      'service': service,
      'location': location,
      'value': value,
      'rating': rating,
      'title': title,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'images': images.map((e) => (e as ReviewImageModel).toJson()).toList(),
      'isUserReview': isUserReview,
      'likesCount': likesCount,
      'isLikedByUser': isLikedByUser,
      'managementReply':
          managementReply != null ? (managementReply as ReviewReplyModel).toJson() : null,
      'bookingType': bookingType,
      'isRecommended': isRecommended,
    };
  }

  Review toEntity() {
    return Review(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      bookingId: bookingId,
      propertyId: propertyId,
      cleanliness: cleanliness,
      service: service,
      location: location,
      value: value,
      rating: rating,
      title: title,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      images: images,
      isUserReview: isUserReview,
      likesCount: likesCount,
      isLikedByUser: isLikedByUser,
      managementReply: managementReply,
      bookingType: bookingType,
      isRecommended: isRecommended,
    );
  }
}

class ReviewReplyModel extends ReviewReply {
  const ReviewReplyModel({
    required super.id,
    required super.content,
    required super.createdAt,
    required super.replierName,
    required super.replierPosition,
  });

  factory ReviewReplyModel.fromJson(Map<String, dynamic> json) {
    return ReviewReplyModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      replierName: json['replierName'] ?? '',
      replierPosition: json['replierPosition'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'replierName': replierName,
      'replierPosition': replierPosition,
    };
  }
}

class ReviewsSummaryModel extends ReviewsSummary {
  const ReviewsSummaryModel({
    required super.totalReviews,
    required super.averageRating,
    required super.ratingDistribution,
    required super.ratingPercentages,
    required super.reviewsWithImagesCount,
    required super.recommendedCount,
    required super.latestReviews,
    required super.topReviews,
    required super.commonKeywords,
    required super.managementResponseRate,
  });

  factory ReviewsSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReviewsSummaryModel(
      totalReviews: json['totalReviews'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      ratingDistribution: Map<int, int>.from(json['ratingDistribution'] ?? {}),
      ratingPercentages:
          Map<int, double>.from(json['ratingPercentages'] ?? {}),
      reviewsWithImagesCount: json['reviewsWithImagesCount'] ?? 0,
      recommendedCount: json['recommendedCount'] ?? 0,
      latestReviews: (json['latestReviews'] as List?)
              ?.map((e) => ReviewModel.fromJson(e))
              .toList() ??
          [],
      topReviews: (json['topReviews'] as List?)
              ?.map((e) => ReviewModel.fromJson(e))
              .toList() ??
          [],
      commonKeywords: (json['commonKeywords'] as List?)
              ?.map((e) => ReviewKeywordModel.fromJson(e))
              .toList() ??
          [],
      managementResponseRate:
          (json['managementResponseRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
      'ratingPercentages': ratingPercentages,
      'reviewsWithImagesCount': reviewsWithImagesCount,
      'recommendedCount': recommendedCount,
      'latestReviews':
          latestReviews.map((e) => (e as ReviewModel).toJson()).toList(),
      'topReviews':
          topReviews.map((e) => (e as ReviewModel).toJson()).toList(),
      'commonKeywords': commonKeywords
          .map((e) => (e as ReviewKeywordModel).toJson())
          .toList(),
      'managementResponseRate': managementResponseRate,
    };
  }

  ReviewsSummary toEntity() {
    return ReviewsSummary(
      totalReviews: totalReviews,
      averageRating: averageRating,
      ratingDistribution: ratingDistribution,
      ratingPercentages: ratingPercentages,
      reviewsWithImagesCount: reviewsWithImagesCount,
      recommendedCount: recommendedCount,
      latestReviews: latestReviews,
      topReviews: topReviews,
      commonKeywords: commonKeywords,
      managementResponseRate: managementResponseRate,
    );
  }
}

class ReviewKeywordModel extends ReviewKeyword {
  const ReviewKeywordModel({
    required super.keyword,
    required super.count,
    required super.percentage,
    required super.sentiment,
  });

  factory ReviewKeywordModel.fromJson(Map<String, dynamic> json) {
    return ReviewKeywordModel(
      keyword: json['keyword'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      sentiment: json['sentiment'] ?? 'Neutral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'count': count,
      'percentage': percentage,
      'sentiment': sentiment,
    };
  }
}