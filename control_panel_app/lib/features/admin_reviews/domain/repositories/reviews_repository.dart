// lib/features/admin_reviews/domain/repositories/reviews_repository.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../entities/review.dart';
import '../entities/review_response.dart';

abstract class ReviewsRepository {
  Future<Either<Failure, PaginatedResult<Review>>> getAllReviews({
    String? status,
    double? minRating,
    double? maxRating,
    bool? hasImages,
    String? propertyId,
    String? unitId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
    bool? includeStats,
  });
  
  Future<Either<Failure, Review>> getReviewDetails(String reviewId);
  
  Future<Either<Failure, bool>> approveReview(String reviewId);
  
  Future<Either<Failure, bool>> rejectReview(String reviewId);
  
  Future<Either<Failure, bool>> deleteReview(String reviewId);
  
  Future<Either<Failure, ReviewResponse>> respondToReview({
    required String reviewId,
    required String responseText,
    required String respondedBy,
  });
  
  Future<Either<Failure, List<ReviewResponse>>> getReviewResponses(String reviewId);
  
  Future<Either<Failure, bool>> deleteReviewResponse(String responseId);

  /// احضر تقييم الحجز إن وجد
  Future<Either<Failure, Review?>> getReviewByBooking(String bookingId);
}