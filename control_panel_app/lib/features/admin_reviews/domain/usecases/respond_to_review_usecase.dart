// lib/features/admin_reviews/domain/usecases/respond_to_review_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../entities/review_response.dart';
import '../repositories/reviews_repository.dart';

class RespondToReviewParams {
  final String reviewId;
  final String responseText;
  final String respondedBy;
  
  RespondToReviewParams({
    required this.reviewId,
    required this.responseText,
    required this.respondedBy,
  });
}

class RespondToReviewUseCase implements UseCase<ReviewResponse, RespondToReviewParams> {
  final ReviewsRepository repository;
  
  RespondToReviewUseCase(this.repository);
  
  @override
  Future<Either<Failure, ReviewResponse>> call(RespondToReviewParams params) {
    return repository.respondToReview(
      reviewId: params.reviewId,
      responseText: params.responseText,
      respondedBy: params.respondedBy,
    );
  }
}