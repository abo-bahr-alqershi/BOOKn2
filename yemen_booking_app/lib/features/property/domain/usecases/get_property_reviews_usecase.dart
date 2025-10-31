import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

class GetPropertyReviewsUseCase implements UseCase<List<PropertyReview>, GetPropertyReviewsParams> {
  final PropertyRepository repository;

  GetPropertyReviewsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<PropertyReview>>> call(GetPropertyReviewsParams params) async {
    return await repository.getPropertyReviews(
      propertyId: params.propertyId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
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
  final String? sortBy;
  final String? sortDirection;
  final bool withImagesOnly;
  final String? userId;

  const GetPropertyReviewsParams({
    required this.propertyId,
    this.pageNumber = 1,
    this.pageSize = 20,
    this.sortBy,
    this.sortDirection,
    this.withImagesOnly = false,
    this.userId,
  });

  @override
  List<Object?> get props => [
        propertyId,
        pageNumber,
        pageSize,
        sortBy,
        sortDirection,
        withImagesOnly,
        userId,
      ];
}