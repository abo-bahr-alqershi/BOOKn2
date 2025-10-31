// lib/features/admin_reviews/presentation/bloc/review_details/review_details_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/entities/review_response.dart';
import '../../../domain/usecases/get_review_details_usecase.dart';
import '../../../domain/usecases/get_review_responses_usecase.dart';
import '../../../domain/usecases/respond_to_review_usecase.dart';
import '../../../domain/usecases/delete_review_response_usecase.dart';

part 'review_details_event.dart';
part 'review_details_state.dart';

class ReviewDetailsBloc extends Bloc<ReviewDetailsEvent, ReviewDetailsState> {
  final GetReviewDetailsUseCase getReviewDetails;
  final GetReviewResponsesUseCase getReviewResponses;
  final RespondToReviewUseCase respondToReview;
  final DeleteReviewResponseUseCase deleteReviewResponse;
  
  ReviewDetailsBloc({
    required this.getReviewDetails,
    required this.getReviewResponses,
    required this.respondToReview,
    required this.deleteReviewResponse,
  }) : super(ReviewDetailsInitial()) {
    on<LoadReviewDetailsEvent>(_onLoadReviewDetails);
    on<AddResponseEvent>(_onAddResponse);
    on<DeleteResponseEvent>(_onDeleteResponse);
    on<RefreshReviewDetailsEvent>(_onRefreshReviewDetails);
  }
  
  Future<void> _onLoadReviewDetails(
    LoadReviewDetailsEvent event,
    Emitter<ReviewDetailsState> emit,
  ) async {
    emit(ReviewDetailsLoading());
    
    final reviewResult = await getReviewDetails(event.reviewId);
    final responsesResult = await getReviewResponses(event.reviewId);
    
    reviewResult.fold(
      (failure) => emit(ReviewDetailsError(failure.message)),
      (review) {
        responsesResult.fold(
          (failure) => emit(ReviewDetailsError(failure.message)),
          (responses) => emit(ReviewDetailsLoaded(
            review: review,
            responses: responses,
          )),
        );
      },
    );
  }
  
  Future<void> _onAddResponse(
    AddResponseEvent event,
    Emitter<ReviewDetailsState> emit,
  ) async {
    if (state is ReviewDetailsLoaded) {
      final currentState = state as ReviewDetailsLoaded;
      emit(ReviewDetailsLoading());
      
      final result = await respondToReview(RespondToReviewParams(
        reviewId: event.reviewId,
        responseText: event.responseText,
        respondedBy: event.respondedBy,
      ));
      
      result.fold(
        (failure) => emit(ReviewDetailsError(failure.message)),
        (response) {
          final updatedResponses = [...currentState.responses, response];
          emit(currentState.copyWith(responses: updatedResponses));
        },
      );
    }
  }
  
  Future<void> _onDeleteResponse(
    DeleteResponseEvent event,
    Emitter<ReviewDetailsState> emit,
  ) async {
    if (state is ReviewDetailsLoaded) {
      final currentState = state as ReviewDetailsLoaded;
      
      final result = await deleteReviewResponse(event.responseId);
      
      result.fold(
        (failure) => emit(ReviewDetailsError(failure.message)),
        (_) {
          final updatedResponses = currentState.responses
              .where((r) => r.id != event.responseId)
              .toList();
          emit(currentState.copyWith(responses: updatedResponses));
        },
      );
    }
  }
  
  Future<void> _onRefreshReviewDetails(
    RefreshReviewDetailsEvent event,
    Emitter<ReviewDetailsState> emit,
  ) async {
    if (state is ReviewDetailsLoaded) {
      final currentState = state as ReviewDetailsLoaded;
      add(LoadReviewDetailsEvent(currentState.review.id));
    }
  }
}