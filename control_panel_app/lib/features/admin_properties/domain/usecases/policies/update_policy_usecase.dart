// lib/features/admin_properties/domain/usecases/policies/update_policy_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/policy.dart';
import '../../repositories/policies_repository.dart';

class UpdatePolicyParams {
  final String policyId;
  final PolicyType? policyType;
  final String? description;
  final String? rules;
  
  UpdatePolicyParams({
    required this.policyId,
    this.policyType,
    this.description,
    this.rules,
  });
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (policyType != null) data['policyType'] = policyType!.index.toString();
    if (description != null) data['description'] = description;
    if (rules != null) data['rules'] = rules;
    return data;
  }
}

class UpdatePolicyUseCase implements UseCase<bool, UpdatePolicyParams> {
  final PoliciesRepository repository;
  
  UpdatePolicyUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(UpdatePolicyParams params) async {
    return await repository.updatePolicy(params.policyId, params.toJson());
  }
}