// lib/features/admin_properties/presentation/bloc/policies/policies_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/policy.dart';
import '../../../domain/usecases/policies/get_policies_usecase.dart';
import '../../../domain/usecases/policies/create_policy_usecase.dart';
import '../../../domain/usecases/policies/update_policy_usecase.dart';
import '../../../domain/usecases/policies/delete_policy_usecase.dart';

part 'policies_event.dart';
part 'policies_state.dart';

class PoliciesBloc extends Bloc<PoliciesEvent, PoliciesState> {
  final GetPoliciesUseCase getPolicies;
  final CreatePolicyUseCase createPolicy;
  final UpdatePolicyUseCase updatePolicy;
  final DeletePolicyUseCase deletePolicy;
  
  PoliciesBloc({
    required this.getPolicies,
    required this.createPolicy,
    required this.updatePolicy,
    required this.deletePolicy,
  }) : super(PoliciesInitial()) {
    on<LoadPoliciesEvent>(_onLoadPolicies);
    on<CreatePolicyEvent>(_onCreatePolicy);
    on<UpdatePolicyEvent>(_onUpdatePolicy);
    on<DeletePolicyEvent>(_onDeletePolicy);
  }
  
  Future<void> _onLoadPolicies(
    LoadPoliciesEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(PoliciesLoading());
    
    final result = await getPolicies(
      GetPoliciesParams(
        propertyId: event.propertyId,
        policyType: event.policyType,
      ),
    );
    
    result.fold(
      (failure) => emit(PoliciesError(failure.message)),
      (policies) => emit(PoliciesLoaded(policies)),
    );
  }
  
  Future<void> _onCreatePolicy(
    CreatePolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(PolicyCreating());
    
    final result = await createPolicy(
      CreatePolicyParams(
        propertyId: event.propertyId,
        policyType: event.policyType,
        description: event.description,
        rules: event.rules,
      ),
    );
    
    result.fold(
      (failure) => emit(PoliciesError(failure.message)),
      (policyId) {
        emit(PolicyCreated(policyId));
        add(LoadPoliciesEvent(propertyId: event.propertyId));
      },
    );
  }
  
  Future<void> _onUpdatePolicy(
    UpdatePolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(PolicyUpdating());
    
    final result = await updatePolicy(
      UpdatePolicyParams(
        policyId: event.policyId,
        policyType: event.policyType,
        description: event.description,
        rules: event.rules,
      ),
    );
    
    result.fold(
      (failure) => emit(PoliciesError(failure.message)),
      (_) {
        emit(PolicyUpdated());
        // Reload policies after update
        add(LoadPoliciesEvent());
      },
    );
  }
  
  Future<void> _onDeletePolicy(
    DeletePolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(PolicyDeleting());
    
    final result = await deletePolicy(event.policyId);
    
    result.fold(
      (failure) => emit(PoliciesError(failure.message)),
      (_) {
        emit(PolicyDeleted());
        // Reload policies after deletion
        add(LoadPoliciesEvent());
      },
    );
  }
}