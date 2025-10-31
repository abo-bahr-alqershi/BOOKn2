// lib/features/admin_sections/data/repositories/property_in_section_images_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/section_image.dart';
import '../../domain/repositories/property_in_section_images_repository.dart';
import '../datasources/property_in_section_images_remote_datasource.dart';
import '../models/section_image_model.dart';

class PropertyInSectionImagesRepositoryImpl
    implements PropertyInSectionImagesRepository {
  final PropertyInSectionImagesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PropertyInSectionImagesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, SectionImage>> uploadImage({
    String? propertyInSectionId,
    String? tempKey,
    required String filePath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final SectionImageModel result = await remoteDataSource.uploadImage(
          propertyInSectionId: propertyInSectionId,
          tempKey: tempKey,
          filePath: filePath,
          category: category,
          alt: alt,
          isPrimary: isPrimary,
          order: order,
          tags: tags,
          onSendProgress: onSendProgress,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<SectionImage>>> getPropertyInSectionImages(
    String? propertyInSectionId, {
    String? tempKey,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final List<SectionImageModel> result = await remoteDataSource
            .getPropertyInSectionImages(propertyInSectionId, tempKey: tempKey);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> updateImage(
    String imageId,
    Map<String, dynamic> data,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final bool result = await remoteDataSource.updateImage(imageId, data);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteImage(String imageId) async {
    if (await networkInfo.isConnected) {
      try {
        final bool result = await remoteDataSource.deleteImage(imageId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> reorderImages(
    String? propertyInSectionId,
    String? tempKey,
    List<String> imageIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final bool result = await remoteDataSource.reorderImages(
            propertyInSectionId, tempKey, imageIds);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> setAsPrimaryImage(
    String? propertyInSectionId,
    String? tempKey,
    String imageId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final bool result = await remoteDataSource.setAsPrimaryImage(
            propertyInSectionId, tempKey, imageId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMultipleImages(
      List<String> imageIds) async {
    if (await networkInfo.isConnected) {
      try {
        bool allDeleted = true;
        for (final imageId in imageIds) {
          final result = await remoteDataSource.deleteImage(imageId);
          if (!result) {
            allDeleted = false;
            break;
          }
        }
        return Right(allDeleted);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<SectionImage>>> uploadMultipleImages({
    String? propertyInSectionId,
    String? tempKey,
    required List<String> filePaths,
    String? category,
    List<String>? tags,
    void Function(String filePath, int sent, int total)? onProgress,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final List<SectionImageModel> uploadedImages = [];
        int order = 0;

        for (final filePath in filePaths) {
          try {
            final result = await remoteDataSource.uploadImage(
              propertyInSectionId: propertyInSectionId,
              tempKey: tempKey,
              filePath: filePath,
              category: category,
              isPrimary: order == 0,
              order: order,
              tags: tags,
              onSendProgress: onProgress != null
                  ? (sent, total) => onProgress(filePath, sent, total)
                  : null,
            );
            uploadedImages.add(result);
            order++;
          } catch (e) {
            continue;
          }
        }

        if (uploadedImages.isEmpty) {
          return const Left(ServerFailure('Failed to upload any images'));
        }

        return Right(uploadedImages);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(
            ServerFailure('An unexpected error occurred: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
