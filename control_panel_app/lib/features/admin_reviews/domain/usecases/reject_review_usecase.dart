// lib/features/admin_reviews/domain/usecases/reject_review_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../repositories/reviews_repository.dart';

class RejectReviewUseCase implements UseCase<bool, String> {
  final ReviewsRepository repository;
  
  RejectReviewUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String reviewId) {
    return repository.rejectReview(reviewId);
  }
}