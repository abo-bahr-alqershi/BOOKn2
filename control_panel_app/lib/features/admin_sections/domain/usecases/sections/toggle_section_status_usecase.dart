import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/repositories/sections_repository.dart';

class ToggleSectionStatusUseCase implements UseCase<bool, ToggleSectionStatusParams> {
  final SectionsRepository repository;
  ToggleSectionStatusUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ToggleSectionStatusParams params) {
    return repository.toggleSectionStatus(params.sectionId, params.isActive);
  }
}

class ToggleSectionStatusParams extends Equatable {
  final String sectionId;
  final bool isActive;
  const ToggleSectionStatusParams({required this.sectionId, required this.isActive});

  @override
  List<Object?> get props => [sectionId, isActive];
}

