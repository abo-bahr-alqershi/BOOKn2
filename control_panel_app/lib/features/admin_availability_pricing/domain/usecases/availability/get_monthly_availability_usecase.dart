// lib/features/admin_availability_pricing/domain/usecases/availability/get_monthly_availability_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/unit_availability.dart';
import '../../repositories/availability_repository.dart';

class GetMonthlyAvailabilityUseCase
    implements UseCase<UnitAvailability, GetMonthlyAvailabilityParams> {
  final AvailabilityRepository repository;

  GetMonthlyAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, UnitAvailability>> call(
    GetMonthlyAvailabilityParams params,
  ) async {
    return await repository.getMonthlyAvailability(
      params.unitId,
      params.year,
      params.month,
    );
  }
}

class GetMonthlyAvailabilityParams extends Equatable {
  final String unitId;
  final int year;
  final int month;

  const GetMonthlyAvailabilityParams({
    required this.unitId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [unitId, year, month];
}