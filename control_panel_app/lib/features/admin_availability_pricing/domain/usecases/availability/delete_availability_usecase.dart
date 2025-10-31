// lib/features/admin_availability_pricing/domain/usecases/availability/delete_availability_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/availability_repository.dart';

class DeleteAvailabilityUseCase
    implements UseCase<void, DeleteAvailabilityParams> {
  final AvailabilityRepository repository;

  DeleteAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    DeleteAvailabilityParams params,
  ) async {
    return await repository.deleteAvailability(
      unitId: params.unitId,
      availabilityId: params.availabilityId,
      startDate: params.startDate,
      endDate: params.endDate,
      forceDelete: params.forceDelete,
    );
  }
}

class DeleteAvailabilityParams extends Equatable {
  final String unitId;
  final String? availabilityId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? forceDelete;

  const DeleteAvailabilityParams({
    required this.unitId,
    this.availabilityId,
    this.startDate,
    this.endDate,
    this.forceDelete,
  });

  @override
  List<Object?> get props => [
        unitId,
        availabilityId,
        startDate,
        endDate,
        forceDelete,
      ];
}