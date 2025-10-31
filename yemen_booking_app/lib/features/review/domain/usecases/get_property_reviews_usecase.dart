import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetPropertyReviewsUseCase {
  final ReviewRepository repository;

  GetPropertyReviewsUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<Review>>> call(
      GetPropertyReviewsParams params) async {
    return await repository.getPropertyReviews(
      propertyId: params.propertyId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      rating: params.rating,
      sortBy: params.sortBy,
      sortDirection: params.sortDirection,
      withImagesOnly: params.withImagesOnly,
      userId: params.userId,
    );
  }
}

class GetPropertyReviewsParams extends Equatable {
  final String propertyId;
  final int pageNumber;
  final int pageSize;
  final int? rating;
  final String? sortBy;
  final String? sortDirection;
  final bool? withImagesOnly;
  final String? userId;

  const GetPropertyReviewsParams({
    required this.propertyId,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.rating,
    this.sortBy = 'CreatedAt',
    this.sortDirection = 'Desc',
    this.withImagesOnly = false,
    this.userId,
  });

  @override
  List<Object?> get props => [
        propertyId,
        pageNumber,
        pageSize,
        rating,
        sortBy,
        sortDirection,
        withImagesOnly,
        userId,
      ];
}