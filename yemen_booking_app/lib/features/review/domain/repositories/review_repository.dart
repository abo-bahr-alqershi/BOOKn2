import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/review.dart';
import '../entities/review_image.dart';

abstract class ReviewRepository {
  /// <summary>
  /// إنشاء مراجعة جديدة
  /// Create new review
  /// </summary>
  Future<Either<Failure, Review>> createReview({
    required String bookingId,
    required String propertyId,
    required int cleanliness,
    required int service,
    required int location,
    required int value,
    required String comment,
    List<String>? imagesBase64,
  });

  /// <summary>
  /// الحصول على مراجعات العقار
  /// Get property reviews
  /// </summary>
  Future<Either<Failure, PaginatedResult<Review>>> getPropertyReviews({
    required String propertyId,
    required int pageNumber,
    required int pageSize,
    int? rating,
    String? sortBy,
    String? sortDirection,
    bool? withImagesOnly,
    String? userId,
  });

  /// <summary>
  /// الحصول على ملخص المراجعات
  /// Get reviews summary
  /// </summary>
  Future<Either<Failure, ReviewsSummary>> getPropertyReviewsSummary({
    required String propertyId,
  });

  /// <summary>
  /// رفع صور المراجعة
  /// Upload review images
  /// </summary>
  Future<Either<Failure, List<ReviewImage>>> uploadReviewImages({
    required String reviewId,
    required List<String> imagesBase64,
  });
}