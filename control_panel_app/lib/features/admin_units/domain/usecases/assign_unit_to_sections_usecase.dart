import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/units_repository.dart';

class AssignUnitToSectionsUseCase implements UseCase<bool, AssignUnitToSectionsParams> {
  final UnitsRepository repository;

  AssignUnitToSectionsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(AssignUnitToSectionsParams params) async {
    return await repository.assignUnitToSections(
      params.unitId,
      params.sectionIds,
    );
  }
}

class AssignUnitToSectionsParams extends Equatable {
  final String unitId;
  final List<String> sectionIds;

  const AssignUnitToSectionsParams({
    required this.unitId,
    required this.sectionIds,
  });

  @override
  List<Object> get props => [unitId, sectionIds];
}