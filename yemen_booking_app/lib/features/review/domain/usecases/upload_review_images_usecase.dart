import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/review_image.dart';
import '../repositories/review_repository.dart';

class UploadReviewImagesUseCase {
  final ReviewRepository repository;

  UploadReviewImagesUseCase(this.repository);

  Future<Either<Failure, List<ReviewImage>>> call(
      UploadReviewImagesParams params) async {
    return await repository.uploadReviewImages(
      reviewId: params.reviewId,
      imagesBase64: params.imagesBase64,
    );
  }
}

class UploadReviewImagesParams extends Equatable {
  final String reviewId;
  final List<String> imagesBase64;

  const UploadReviewImagesParams({
    required this.reviewId,
    required this.imagesBase64,
  });

  @override
  List<Object> get props => [reviewId, imagesBase64];
}