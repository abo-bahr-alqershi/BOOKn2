// lib/features/admin_reviews/presentation/bloc/review_response/review_response_state.dart

part of 'review_response_bloc.dart';

abstract class ReviewResponseState extends Equatable {
  const ReviewResponseState();
  
  @override
  List<Object> get props => [];
}

class ReviewResponseInitial extends ReviewResponseState {}

class ReviewResponseSubmitting extends ReviewResponseState {}

class ReviewResponseSuccess extends ReviewResponseState {
  final ReviewResponse response;
  
  const ReviewResponseSuccess(this.response);
  
  @override
  List<Object> get props => [response];
}

class ReviewResponseError extends ReviewResponseState {
  final String message;
  
  const ReviewResponseError(this.message);
  
  @override
  List<Object> get props => [message];
}