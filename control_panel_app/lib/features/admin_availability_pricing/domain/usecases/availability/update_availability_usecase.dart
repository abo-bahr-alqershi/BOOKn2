// lib/features/admin_availability_pricing/domain/usecases/availability/update_availability_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/availability.dart';
import '../../repositories/availability_repository.dart';

class UpdateAvailabilityUseCase
    implements UseCase<void, UpdateAvailabilityParams> {
  final AvailabilityRepository repository;

  UpdateAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    UpdateAvailabilityParams params,
  ) async {
    return await repository.updateAvailability(params.availability);
  }
}

class UpdateAvailabilityParams extends Equatable {
  final UnitAvailabilityEntry availability;

  const UpdateAvailabilityParams({required this.availability});

  @override
  List<Object> get props => [availability];
}