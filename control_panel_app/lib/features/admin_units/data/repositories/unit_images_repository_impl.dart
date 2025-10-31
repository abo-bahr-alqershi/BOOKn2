// lib/features/admin_units/data/repositories/unit_images_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/network/network_info.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/unit_image.dart';
import '../../domain/repositories/unit_images_repository.dart';
import '../datasources/unit_images_remote_datasource.dart';
import '../models/unit_image_model.dart';

class UnitImagesRepositoryImpl implements UnitImagesRepository {
  final UnitImagesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UnitImagesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UnitImage>> uploadImage({
    String? unitId,
    String? sectionId,
    String? unitInSectionId,
    String? tempKey,
    required String filePath,
    String? videoThumbnailPath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final UnitImageModel result = await remoteDataSource.uploadImage(
          unitId: unitId,
          sectionId: sectionId,
          unitInSectionId: unitInSectionId,
          tempKey: tempKey,
          filePath: filePath,
          videoThumbnailPath: videoThumbnailPath,
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
  Future<Either<Failure, List<UnitImage>>> getUnitImages(String? unitId,
      {String? tempKey}) async {
    if (await networkInfo.isConnected) {
      try {
        final List<UnitImageModel> result =
            await remoteDataSource.getUnitImages(unitId, tempKey: tempKey);
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
    String? unitId,
    String? tempKey,
    List<String> imageIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final bool result =
            await remoteDataSource.reorderImages(unitId, tempKey, imageIds);
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
    String? unitId,
    String? tempKey,
    String imageId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final bool result =
            await remoteDataSource.setAsPrimaryImage(unitId, tempKey, imageId);
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
  Future<Either<Failure, List<UnitImage>>> uploadMultipleImages({
    String? unitId,
    String? tempKey,
    required List<String> filePaths,
    String? category,
    List<String>? tags,
    void Function(String filePath, int sent, int total)? onProgress,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final List<UnitImageModel> uploadedImages = [];
        int order = 0;

        for (final filePath in filePaths) {
          try {
            final result = await remoteDataSource.uploadImage(
              unitId: unitId,
              tempKey: tempKey,
              filePath: filePath,
              category: category,
              isPrimary: order == 0, // الصورة الأولى تكون رئيسية
              order: order,
              tags: tags,
              onSendProgress: onProgress != null
                  ? (sent, total) => onProgress(filePath, sent, total)
                  : null,
            );
            uploadedImages.add(result);
            order++;
          } catch (e) {
            // تجاهل الصور الفاشلة والاستمرار
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
