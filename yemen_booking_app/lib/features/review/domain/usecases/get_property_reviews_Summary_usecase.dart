import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetPropertyReviewsSummaryUseCase {
  final ReviewRepository repository;

  GetPropertyReviewsSummaryUseCase(this.repository);

  Future<Either<Failure, ReviewsSummary>> call(
      GetPropertyReviewsSummaryParams params) async {
    return await repository.getPropertyReviewsSummary(
      propertyId: params.propertyId,
    );
  }
}

class GetPropertyReviewsSummaryParams extends Equatable {
  final String propertyId;

  const GetPropertyReviewsSummaryParams({required this.propertyId});

  @override
  List<Object> get props => [propertyId];
}