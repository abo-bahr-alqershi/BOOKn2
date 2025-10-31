import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/repositories/sections_repository.dart';

class DeleteSectionUseCase implements UseCase<bool, DeleteSectionParams> {
  final SectionsRepository repository;
  DeleteSectionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteSectionParams params) {
    return repository.deleteSection(params.sectionId);
  }
}

class DeleteSectionParams extends Equatable {
  final String sectionId;
  const DeleteSectionParams(this.sectionId);

  @override
  List<Object?> get props => [sectionId];
}

