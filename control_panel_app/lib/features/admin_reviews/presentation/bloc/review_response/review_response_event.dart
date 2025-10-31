// lib/features/admin_reviews/presentation/bloc/review_response/review_response_event.dart

part of 'review_response_bloc.dart';

abstract class ReviewResponseEvent extends Equatable {
  const ReviewResponseEvent();
  
  @override
  List<Object> get props => [];
}

class SubmitResponseEvent extends ReviewResponseEvent {
  final String reviewId;
  final String responseText;
  final String respondedBy;
  
  const SubmitResponseEvent({
    required this.reviewId,
    required this.responseText,
    required this.respondedBy,
  });
  
  @override
  List<Object> get props => [reviewId, responseText, respondedBy];
}