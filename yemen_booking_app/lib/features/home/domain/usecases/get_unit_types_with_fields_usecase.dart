import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yemen_booking_app/features/home/domain/entities/unit_type.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/home_repository.dart';

class GetUnitTypesWithFieldsUseCase implements UseCase<List<UnitType>, GetUnitTypesParams> {
  final HomeRepository repository;

  GetUnitTypesWithFieldsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UnitType>>> call(GetUnitTypesParams params) async {
    return repository.getUnitTypes(propertyTypeId: params.propertyTypeId);
  }
}

class GetUnitTypesParams extends Equatable {
  final String propertyTypeId;

  const GetUnitTypesParams({required this.propertyTypeId});

  @override
  List<Object?> get props => [propertyTypeId];
}