import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/entities/section.dart';
import '../../../domain/repositories/sections_repository.dart';

class GetSectionByIdUseCase implements UseCase<Section, GetSectionByIdParams> {
  final SectionsRepository repository;
  GetSectionByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Section>> call(GetSectionByIdParams params) {
    return repository.getSectionById(params.sectionId);
  }
}

class GetSectionByIdParams extends Equatable {
  final String sectionId;
  const GetSectionByIdParams(this.sectionId);

  @override
  List<Object?> get props => [sectionId];
}

