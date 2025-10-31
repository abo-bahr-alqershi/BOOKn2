import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/entities/section.dart';
import '../../../domain/repositories/sections_repository.dart';

class UpdateSectionUseCase implements UseCase<Section, UpdateSectionParams> {
  final SectionsRepository repository;
  UpdateSectionUseCase(this.repository);

  @override
  Future<Either<Failure, Section>> call(UpdateSectionParams params) {
    return repository.updateSection(params.sectionId, params.section);
  }
}

class UpdateSectionParams extends Equatable {
  final String sectionId;
  final Section section;
  const UpdateSectionParams({required this.sectionId, required this.section});

  @override
  List<Object?> get props => [sectionId, section];
}

