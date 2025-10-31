// lib/features/admin_reviews/domain/usecases/approve_review_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../repositories/reviews_repository.dart';

class ApproveReviewUseCase implements UseCase<bool, String> {
  final ReviewsRepository repository;
  
  ApproveReviewUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String reviewId) {
    return repository.approveReview(reviewId);
  }
}