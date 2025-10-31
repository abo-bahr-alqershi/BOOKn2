import 'package:dartz/dartz.dart' hide Unit;
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/unit.dart';
import '../repositories/units_repository.dart';

class GetUnitDetailsUseCase implements UseCase<Unit, GetUnitDetailsParams> {
  final UnitsRepository repository;

  GetUnitDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(GetUnitDetailsParams params) async {
    return await repository.getUnitDetails(params.unitId);
  }
}

class GetUnitDetailsParams extends Equatable {
  final String unitId;

  const GetUnitDetailsParams({required this.unitId});

  @override
  List<Object> get props => [unitId];
}