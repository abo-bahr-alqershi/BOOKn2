import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class CreateReviewUseCase {
  final ReviewRepository repository;

  CreateReviewUseCase(this.repository);

  Future<Either<Failure, Review>> call(CreateReviewParams params) async {
    return await repository.createReview(
      bookingId: params.bookingId,
      propertyId: params.propertyId,
      cleanliness: params.cleanliness,
      service: params.service,
      location: params.location,
      value: params.value,
      comment: params.comment,
      imagesBase64: params.imagesBase64,
    );
  }
}

class CreateReviewParams extends Equatable {
  final String bookingId;
  final String propertyId;
  final int cleanliness;
  final int service;
  final int location;
  final int value;
  final String comment;
  final List<String>? imagesBase64;

  const CreateReviewParams({
    required this.bookingId,
    required this.propertyId,
    required this.cleanliness,
    required this.service,
    required this.location,
    required this.value,
    required this.comment,
    this.imagesBase64,
  });

  @override
  List<Object?> get props => [
        bookingId,
        propertyId,
        cleanliness,
        service,
        location,
        value,
        comment,
        imagesBase64,
      ];
}