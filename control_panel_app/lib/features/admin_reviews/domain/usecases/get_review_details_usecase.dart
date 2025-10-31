// lib/features/admin_reviews/domain/usecases/get_review_details_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../entities/review.dart';
import '../repositories/reviews_repository.dart';

class GetReviewDetailsUseCase implements UseCase<Review, String> {
  final ReviewsRepository repository;
  
  GetReviewDetailsUseCase(this.repository);
  
  @override
  Future<Either<Failure, Review>> call(String reviewId) {
    return repository.getReviewDetails(reviewId);
  }
}