// lib/features/admin_units/domain/usecases/unit_images/delete_multiple_unit_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/unit_images_repository.dart';

class DeleteMultipleUnitImagesUseCase implements UseCase<bool, List<String>> {
  final UnitImagesRepository repository;

  DeleteMultipleUnitImagesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(List<String> imageIds) async {
    return await repository.deleteMultipleImages(imageIds);
  }
}