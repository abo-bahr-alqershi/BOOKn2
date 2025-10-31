// lib/features/admin_reviews/domain/usecases/get_all_reviews_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../entities/review.dart';
import '../repositories/reviews_repository.dart';

class GetAllReviewsParams {
  final String? status;
  final double? minRating;
  final double? maxRating;
  final bool? hasImages;
  final String? propertyId;
  final String? unitId;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? pageNumber;
  final int? pageSize;
  final bool? includeStats;
  
  GetAllReviewsParams({
    this.status,
    this.minRating,
    this.maxRating,
    this.hasImages,
    this.propertyId,
    this.unitId,
    this.userId,
    this.startDate,
    this.endDate,
    this.pageNumber,
    this.pageSize,
    this.includeStats,
  });
}

class GetAllReviewsUseCase implements UseCase<PaginatedResult<Review>, GetAllReviewsParams> {
  final ReviewsRepository repository;
  
  GetAllReviewsUseCase(this.repository);
  
  @override
  Future<Either<Failure, PaginatedResult<Review>>> call(GetAllReviewsParams params) {
    return repository.getAllReviews(
      status: params.status,
      minRating: params.minRating,
      maxRating: params.maxRating,
      hasImages: params.hasImages,
      propertyId: params.propertyId,
      unitId: params.unitId,
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      includeStats: params.includeStats,
    );
  }
}