// lib/features/admin_properties/domain/usecases/property_images/get_property_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/property_image.dart';
import '../../repositories/property_images_repository.dart';

class GetPropertyImagesUseCase implements UseCase<List<PropertyImage>, GetImagesParams> {
  final PropertyImagesRepository repository;

  GetPropertyImagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyImage>>> call(GetImagesParams params) async {
    return await repository.getPropertyImages(params.propertyId, tempKey: params.tempKey);
  }
}

class GetImagesParams {
  final String? propertyId;
  final String? tempKey;

  GetImagesParams({this.propertyId, this.tempKey});
}