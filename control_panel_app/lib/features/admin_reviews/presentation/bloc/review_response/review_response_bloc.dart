// lib/features/admin_reviews/presentation/bloc/review_response/review_response_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/review_response.dart';
import '../../../domain/usecases/respond_to_review_usecase.dart';

part 'review_response_event.dart';
part 'review_response_state.dart';

class ReviewResponseBloc extends Bloc<ReviewResponseEvent, ReviewResponseState> {
  final RespondToReviewUseCase respondToReview;
  
  ReviewResponseBloc({
    required this.respondToReview,
  }) : super(ReviewResponseInitial()) {
    on<SubmitResponseEvent>(_onSubmitResponse);
  }
  
  Future<void> _onSubmitResponse(
    SubmitResponseEvent event,
    Emitter<ReviewResponseState> emit,
  ) async {
    emit(ReviewResponseSubmitting());
    
    final result = await respondToReview(RespondToReviewParams(
      reviewId: event.reviewId,
      responseText: event.responseText,
      respondedBy: event.respondedBy,
    ));
    
    result.fold(
      (failure) => emit(ReviewResponseError(failure.message)),
      (response) => emit(ReviewResponseSuccess(response)),
    );
  }
}