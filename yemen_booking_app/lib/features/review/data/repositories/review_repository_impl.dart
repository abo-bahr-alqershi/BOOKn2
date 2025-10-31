import 'package:dartz/dartz.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_image.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ReviewRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Review>> createReview({
    required String bookingId,
    required String propertyId,
    required int cleanliness,
    required int service,
    required int location,
    required int value,
    required String comment,
    List<String>? imagesBase64,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createReview(
          bookingId: bookingId,
          propertyId: propertyId,
          cleanliness: cleanliness,
          service: service,
          location: location,
          value: value,
          comment: comment,
          imagesBase64: imagesBase64,
        );
        return Right(result.toEntity());
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Review>>> getPropertyReviews({
    required String propertyId,
    required int pageNumber,
    required int pageSize,
    int? rating,
    String? sortBy,
    String? sortDirection,
    bool? withImagesOnly,
    String? userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPropertyReviews(
          propertyId: propertyId,
          pageNumber: pageNumber,
          pageSize: pageSize,
          rating: rating,
          sortBy: sortBy,
          sortDirection: sortDirection,
          withImagesOnly: withImagesOnly,
          userId: userId,
        );
        
        // Convert models to entities
        final reviews = result.items.map((model) => model.toEntity()).toList();
        
        return Right(PaginatedResult<Review>(
          items: reviews,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          metadata: result.metadata,
        ));
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, ReviewsSummary>> getPropertyReviewsSummary({
    required String propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPropertyReviewsSummary(
          propertyId: propertyId,
        );
        return Right(result.toEntity());
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<ReviewImage>>> uploadReviewImages({
    required String reviewId,
    required List<String> imagesBase64,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.uploadReviewImages(
          reviewId: reviewId,
          imagesBase64: imagesBase64,
        );
        return Right(result.map((model) => model.toEntity()).toList());
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }
}