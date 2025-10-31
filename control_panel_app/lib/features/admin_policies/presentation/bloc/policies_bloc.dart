import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/policy.dart';
import '../../domain/repositories/policies_repository.dart';
import '../../domain/usecases/create_policy_usecase.dart';
import '../../domain/usecases/delete_policy_usecase.dart';
import '../../domain/usecases/get_all_policies_usecase.dart';
import '../../domain/usecases/get_policies_by_property_usecase.dart';
import '../../domain/usecases/get_policies_by_type_usecase.dart';
import '../../domain/usecases/get_policy_by_id_usecase.dart';
import '../../domain/usecases/toggle_policy_status_usecase.dart';
import '../../domain/usecases/update_policy_usecase.dart';
import 'policies_event.dart';
import 'policies_state.dart';

class PoliciesBloc extends Bloc<PoliciesEvent, PoliciesState> {
  final CreatePolicyUseCase createPolicyUseCase;
  final UpdatePolicyUseCase updatePolicyUseCase;
  final DeletePolicyUseCase deletePolicyUseCase;
  final GetAllPoliciesUseCase getAllPoliciesUseCase;
  final GetPolicyByIdUseCase getPolicyByIdUseCase;
  final GetPoliciesByPropertyUseCase getPoliciesByPropertyUseCase;
  final GetPoliciesByTypeUseCase getPoliciesByTypeUseCase;
  final TogglePolicyStatusUseCase togglePolicyStatusUseCase;
  final PoliciesRepository repository;

  // متغيرات لحفظ حالة البحث والفلاتر
  String? _currentSearchTerm;
  String? _currentPropertyId;
  PolicyType? _currentPolicyType;
  int _currentPageNumber = 1;
  int _currentPageSize = 10;

  PoliciesBloc({
    required this.createPolicyUseCase,
    required this.updatePolicyUseCase,
    required this.deletePolicyUseCase,
    required this.getAllPoliciesUseCase,
    required this.getPolicyByIdUseCase,
    required this.getPoliciesByPropertyUseCase,
    required this.getPoliciesByTypeUseCase,
    required this.togglePolicyStatusUseCase,
    required this.repository,
  }) : super(const PoliciesInitial()) {
    on<LoadPoliciesEvent>(_onLoadPolicies);
    on<CreatePolicyEvent>(_onCreatePolicy);
    on<UpdatePolicyEvent>(_onUpdatePolicy);
    on<DeletePolicyEvent>(_onDeletePolicy);
    on<TogglePolicyStatusEvent>(_onTogglePolicyStatus);
    on<LoadPolicyStatsEvent>(_onLoadPolicyStats);
    on<SearchPoliciesEvent>(_onSearchPolicies);
    on<SelectPolicyEvent>(_onSelectPolicy);
    on<DeselectPolicyEvent>(_onDeselectPolicy);
    on<RefreshPoliciesEvent>(_onRefreshPolicies);
    on<ChangePageEvent>(_onChangePage);
    on<ChangePageSizeEvent>(_onChangePageSize);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<ClearFiltersEvent>(_onClearFilters);
    on<LoadPolicyByIdEvent>(_onLoadPolicyById);
    on<LoadPoliciesByPropertyEvent>(_onLoadPoliciesByProperty);
    on<LoadPoliciesByTypeEvent>(_onLoadPoliciesByType);
  }

  Future<void> _onLoadPolicies(
    LoadPoliciesEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    _currentSearchTerm = event.searchTerm;
    _currentPropertyId = event.propertyId;
    _currentPolicyType = event.policyType;
    _currentPageNumber = event.pageNumber;
    _currentPageSize = event.pageSize;

    final bool isLoadMore = state is PoliciesLoaded && event.pageNumber > 1;
    if (!isLoadMore) {
      emit(const PoliciesLoading());
    }

    final result = await getAllPoliciesUseCase(
      GetAllPoliciesParams(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        searchTerm: event.searchTerm,
        propertyId: event.propertyId,
        policyType: event.policyType,
      ),
    );

    await result.fold(
      (failure) async {
        emit(PoliciesError(message: failure.message));
      },
      (page) async {
        final statsResult = !isLoadMore
            ? await repository.getPolicyStats(propertyId: _currentPropertyId)
            : null;
        final stats = statsResult == null
            ? (state is PoliciesLoaded ? (state as PoliciesLoaded).stats : null)
            : statsResult.fold((_) => null, (s) => s);

        if (!emit.isDone) {
          if (isLoadMore && state is PoliciesLoaded) {
            final current = state as PoliciesLoaded;
            final mergedItems = <Policy>[];
            final existing = current.policies.items;
            mergedItems.addAll(existing);
            for (final p in page.items) {
              if (!mergedItems.any((x) => x.id == p.id)) mergedItems.add(p);
            }
            final merged = PaginatedResult<Policy>(
              items: mergedItems,
              pageNumber: page.pageNumber,
              pageSize: page.pageSize,
              totalCount: page.totalCount,
            );
            emit(current.copyWith(
              policies: merged,
              searchTerm: event.searchTerm,
              propertyId: event.propertyId,
              policyType: event.policyType,
              stats: stats,
            ));
          } else {
            emit(PoliciesLoaded(
              policies: page,
              searchTerm: event.searchTerm,
              propertyId: event.propertyId,
              policyType: event.policyType,
              stats: stats,
            ));
          }
        }
      },
    );
  }

  Future<void> _onCreatePolicy(
    CreatePolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(const PolicyOperationInProgress(operation: 'create'));

    final result = await createPolicyUseCase(
      CreatePolicyParams(
        propertyId: event.propertyId,
        type: event.type,
        description: event.description,
        rules: event.rules,
        cancellationWindowDays: event.cancellationWindowDays,
        requireFullPaymentBeforeConfirmation: event.requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage: event.minimumDepositPercentage,
        minHoursBeforeCheckIn: event.minHoursBeforeCheckIn,
      ),
    );

    result.fold(
      (failure) => emit(PolicyOperationFailure(message: failure.message)),
      (policyId) {
        emit(PolicyOperationSuccess(
          message: 'تم إنشاء السياسة بنجاح',
          policyId: policyId,
        ));
        if (!isClosed) {
          add(LoadPoliciesEvent(
            pageNumber: _currentPageNumber,
            pageSize: _currentPageSize,
            searchTerm: _currentSearchTerm,
            propertyId: _currentPropertyId,
            policyType: _currentPolicyType,
          ));
        }
      },
    );
  }

  Future<void> _onUpdatePolicy(
    UpdatePolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(PolicyOperationInProgress(
      operation: 'update',
      policyId: event.policyId,
    ));

    final result = await updatePolicyUseCase(
      UpdatePolicyParams(
        policyId: event.policyId,
        type: event.type,
        description: event.description,
        rules: event.rules,
        cancellationWindowDays: event.cancellationWindowDays,
        requireFullPaymentBeforeConfirmation: event.requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage: event.minimumDepositPercentage,
        minHoursBeforeCheckIn: event.minHoursBeforeCheckIn,
      ),
    );

    result.fold(
      (failure) => emit(PolicyOperationFailure(
        message: failure.message,
        policyId: event.policyId,
      )),
      (_) {
        emit(PolicyOperationSuccess(
          message: 'تم تحديث السياسة بنجاح',
          policyId: event.policyId,
        ));
        if (!isClosed) {
          add(LoadPoliciesEvent(
            pageNumber: _currentPageNumber,
            pageSize: _currentPageSize,
            searchTerm: _currentSearchTerm,
            propertyId: _currentPropertyId,
            policyType: _currentPolicyType,
          ));
        }
      },
    );
  }

  Future<void> _onDeletePolicy(
    DeletePolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(PolicyOperationInProgress(
      operation: 'delete',
      policyId: event.policyId,
    ));

    final result = await deletePolicyUseCase(event.policyId);

    result.fold(
      (failure) => emit(PolicyOperationFailure(
        message: failure.message,
        policyId: event.policyId,
      )),
      (_) {
        emit(PolicyOperationSuccess(
          message: 'تم حذف السياسة بنجاح',
          policyId: event.policyId,
        ));
        if (!isClosed) {
          add(LoadPoliciesEvent(
            pageNumber: _currentPageNumber,
            pageSize: _currentPageSize,
            searchTerm: _currentSearchTerm,
            propertyId: _currentPropertyId,
            policyType: _currentPolicyType,
          ));
        }
      },
    );
  }

  Future<void> _onTogglePolicyStatus(
    TogglePolicyStatusEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(PolicyOperationInProgress(
      operation: 'toggle',
      policyId: event.policyId,
    ));

    final result = await togglePolicyStatusUseCase(event.policyId);

    result.fold(
      (failure) => emit(PolicyOperationFailure(
        message: failure.message,
        policyId: event.policyId,
      )),
      (_) {
        emit(PolicyOperationSuccess(
          message: 'تم تغيير حالة السياسة بنجاح',
          policyId: event.policyId,
        ));
        if (!isClosed) {
          add(LoadPoliciesEvent(
            pageNumber: _currentPageNumber,
            pageSize: _currentPageSize,
            searchTerm: _currentSearchTerm,
            propertyId: _currentPropertyId,
            policyType: _currentPolicyType,
          ));
        }
      },
    );
  }

  Future<void> _onLoadPolicyStats(
    LoadPolicyStatsEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    if (state is PoliciesLoaded) {
      final currentState = state as PoliciesLoaded;
      final result = await repository.getPolicyStats(propertyId: _currentPropertyId);

      result.fold(
        (_) {},
        (stats) {
          emit(currentState.copyWith(stats: stats));
        },
      );
    }
  }

  Future<void> _onSearchPolicies(
    SearchPoliciesEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    add(LoadPoliciesEvent(
      pageNumber: 1,
      pageSize: _currentPageSize,
      searchTerm: event.searchTerm,
      propertyId: _currentPropertyId,
      policyType: event.type,
    ));
  }

  Future<void> _onSelectPolicy(
    SelectPolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    if (state is PoliciesLoaded) {
      final currentState = state as PoliciesLoaded;
      final selectedPolicy = currentState.policies.items
          .firstWhere((policy) => policy.id == event.policyId);
      emit(currentState.copyWith(selectedPolicy: selectedPolicy));
    }
  }

  Future<void> _onDeselectPolicy(
    DeselectPolicyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    if (state is PoliciesLoaded) {
      final currentState = state as PoliciesLoaded;
      emit(currentState.copyWith(clearSelectedPolicy: true));
    }
  }

  Future<void> _onRefreshPolicies(
    RefreshPoliciesEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    add(LoadPoliciesEvent(
      pageNumber: _currentPageNumber,
      pageSize: _currentPageSize,
      searchTerm: _currentSearchTerm,
      propertyId: _currentPropertyId,
      policyType: _currentPolicyType,
    ));
  }

  Future<void> _onChangePage(
    ChangePageEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    add(LoadPoliciesEvent(
      pageNumber: event.pageNumber,
      pageSize: _currentPageSize,
      searchTerm: _currentSearchTerm,
      propertyId: _currentPropertyId,
      policyType: _currentPolicyType,
    ));
  }

  Future<void> _onChangePageSize(
    ChangePageSizeEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    add(LoadPoliciesEvent(
      pageNumber: 1,
      pageSize: event.pageSize,
      searchTerm: _currentSearchTerm,
      propertyId: _currentPropertyId,
      policyType: _currentPolicyType,
    ));
  }

  Future<void> _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    add(LoadPoliciesEvent(
      pageNumber: 1,
      pageSize: _currentPageSize,
      searchTerm: _currentSearchTerm,
      propertyId: event.propertyId,
      policyType: event.policyType,
    ));
  }

  Future<void> _onClearFilters(
    ClearFiltersEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    add(LoadPoliciesEvent(
      pageNumber: 1,
      pageSize: _currentPageSize,
      searchTerm: null,
      propertyId: null,
      policyType: null,
    ));
  }

  Future<void> _onLoadPolicyById(
    LoadPolicyByIdEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(const PoliciesLoading());

    final result = await getPolicyByIdUseCase(event.policyId);

    result.fold(
      (failure) => emit(PoliciesError(message: failure.message)),
      (policy) => emit(PolicyDetailsLoaded(policy: policy)),
    );
  }

  Future<void> _onLoadPoliciesByProperty(
    LoadPoliciesByPropertyEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(const PoliciesLoading());

    final result = await getPoliciesByPropertyUseCase(event.propertyId);

    result.fold(
      (failure) => emit(PoliciesError(message: failure.message)),
      (policies) => emit(PolicyByPropertyLoaded(
        policies: policies,
        propertyId: event.propertyId,
      )),
    );
  }

  Future<void> _onLoadPoliciesByType(
    LoadPoliciesByTypeEvent event,
    Emitter<PoliciesState> emit,
  ) async {
    emit(const PoliciesLoading());

    final result = await getPoliciesByTypeUseCase(
      GetPoliciesByTypeParams(
        type: event.type,
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
      ),
    );

    result.fold(
      (failure) => emit(PoliciesError(message: failure.message)),
      (page) => emit(PoliciesLoaded(
        policies: page,
        policyType: event.type,
      )),
    );
  }
}
