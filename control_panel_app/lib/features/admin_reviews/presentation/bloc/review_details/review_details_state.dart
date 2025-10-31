// lib/features/admin_reviews/presentation/bloc/review_details/review_details_state.dart

part of 'review_details_bloc.dart';

abstract class ReviewDetailsState extends Equatable {
  const ReviewDetailsState();
  
  @override
  List<Object> get props => [];
}

class ReviewDetailsInitial extends ReviewDetailsState {}

class ReviewDetailsLoading extends ReviewDetailsState {}

class ReviewDetailsLoaded extends ReviewDetailsState {
  final Review review;
  final List<ReviewResponse> responses;
  
  const ReviewDetailsLoaded({
    required this.review,
    required this.responses,
  });
  
  ReviewDetailsLoaded copyWith({
    Review? review,
    List<ReviewResponse>? responses,
  }) {
    return ReviewDetailsLoaded(
      review: review ?? this.review,
      responses: responses ?? this.responses,
    );
  }
  
  @override
  List<Object> get props => [review, responses];
}

class ReviewDetailsError extends ReviewDetailsState {
  final String message;
  
  const ReviewDetailsError(this.message);
  
  @override
  List<Object> get props => [message];
}