import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/policy.dart';
import '../repositories/policies_repository.dart';

class UpdatePolicyUseCase implements UseCase<void, UpdatePolicyParams> {
  final PoliciesRepository repository;

  UpdatePolicyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePolicyParams params) async {
    return await repository.updatePolicy(
      policyId: params.policyId,
      type: params.type,
      description: params.description,
      rules: params.rules,
      cancellationWindowDays: params.cancellationWindowDays,
      requireFullPaymentBeforeConfirmation: params.requireFullPaymentBeforeConfirmation,
      minimumDepositPercentage: params.minimumDepositPercentage,
      minHoursBeforeCheckIn: params.minHoursBeforeCheckIn,
    );
  }
}

class UpdatePolicyParams extends Equatable {
  final String policyId;
  final PolicyType type;
  final String description;
  final String rules;
  final int? cancellationWindowDays;
  final bool? requireFullPaymentBeforeConfirmation;
  final double? minimumDepositPercentage;
  final int? minHoursBeforeCheckIn;

  const UpdatePolicyParams({
    required this.policyId,
    required this.type,
    required this.description,
    required this.rules,
    this.cancellationWindowDays,
    this.requireFullPaymentBeforeConfirmation,
    this.minimumDepositPercentage,
    this.minHoursBeforeCheckIn,
  });

  @override
  List<Object?> get props => [
        policyId,
        type,
        description,
        rules,
        cancellationWindowDays,
        requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage,
        minHoursBeforeCheckIn,
      ];
}
