// lib/features/admin_reviews/domain/usecases/delete_review_response_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../repositories/reviews_repository.dart';

class DeleteReviewResponseUseCase implements UseCase<bool, String> {
  final ReviewsRepository repository;
  
  DeleteReviewResponseUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String responseId) {
    return repository.deleteReviewResponse(responseId);
  }
}