// lib/features/admin_reviews/data/repositories/reviews_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_response.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_remote_datasource.dart';
import '../datasources/reviews_local_datasource.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource remoteDataSource;
  final ReviewsLocalDataSource localDataSource;
  
  ReviewsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
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
  }) async {
    try {
      final paginatedReviews = await remoteDataSource.getAllReviews(
        status: status,
        minRating: minRating,
        maxRating: maxRating,
        hasImages: hasImages,
        propertyId: propertyId,
        unitId: unitId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        pageNumber: pageNumber,
        pageSize: pageSize,
        includeStats: includeStats,
      );
      
      // Cache the results
      await localDataSource.cacheReviews(paginatedReviews.items);
      
      return Right(paginatedReviews);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Review>> getReviewDetails(String reviewId) async {
    try {
      final review = await remoteDataSource.getReviewDetails(reviewId);
      // Optionally update cache entry for this review
      await localDataSource.upsertReview(review);
      return Right(review);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> approveReview(String reviewId) async {
    try {
      final result = await remoteDataSource.approveReview(reviewId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> rejectReview(String reviewId) async {
    try {
      final result = await remoteDataSource.rejectReview(reviewId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deleteReview(String reviewId) async {
    try {
      final result = await remoteDataSource.deleteReview(reviewId);
      // Clear from cache
      await localDataSource.deleteReview(reviewId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, ReviewResponse>> respondToReview({
    required String reviewId,
    required String responseText,
    required String respondedBy,
  }) async {
    try {
      final response = await remoteDataSource.respondToReview(
        reviewId: reviewId,
        responseText: responseText,
        respondedBy: respondedBy,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, Review?>> getReviewByBooking(String bookingId) async {
    try {
      final review = await remoteDataSource.getReviewByBooking(bookingId);
      if (review != null) {
        await localDataSource.upsertReview(review);
      }
      return Right(review);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<ReviewResponse>>> getReviewResponses(
    String reviewId,
  ) async {
    try {
      final responses = await remoteDataSource.getReviewResponses(reviewId);
      return Right(responses);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deleteReviewResponse(String responseId) async {
    try {
      final result = await remoteDataSource.deleteReviewResponse(responseId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}