// lib/features/admin_financial/presentation/bloc/accounts/accounts_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/chart_of_account.dart';
import '../../../domain/repositories/financial_repository.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

/// 📊 Bloc لإدارة دليل الحسابات
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final FinancialRepository repository;

  AccountsBloc({
    required this.repository,
  }) : super(AccountsInitial()) {
    on<LoadChartOfAccounts>(_onLoadChartOfAccounts);
    on<SearchAccounts>(_onSearchAccounts);
    on<FilterAccountsByType>(_onFilterAccountsByType);
    on<LoadMainAccounts>(_onLoadMainAccounts);
  }

  Future<void> _onLoadChartOfAccounts(
    LoadChartOfAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoading());

    final result = await repository.getChartOfAccounts();

    result.fold(
      (failure) => emit(AccountsError(failure.message)),
      (accounts) => emit(AccountsLoaded(accounts: accounts)),
    );
  }


  Future<void> _onSearchAccounts(
    SearchAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoading());

    final result = await repository.searchAccounts(event.query);

    result.fold(
      (failure) => emit(AccountsError(failure.message)),
      (accounts) => emit(AccountsLoaded(
        accounts: accounts,
        searchQuery: event.query,
      )),
    );
  }

  Future<void> _onFilterAccountsByType(
    FilterAccountsByType event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoading());

    final result = await repository.getAccountsByType(event.type);

    result.fold(
      (failure) => emit(AccountsError(failure.message)),
      (accounts) => emit(AccountsLoaded(
        accounts: accounts,
        selectedType: event.type,
      )),
    );
  }


  Future<void> _onLoadMainAccounts(
    LoadMainAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoading());

    final result = await repository.getMainAccounts();

    result.fold(
      (failure) => emit(AccountsError(failure.message)),
      (accounts) => emit(AccountsLoaded(
        accounts: accounts,
        showMainOnly: true,
      )),
    );
  }

  List<ChartOfAccount> _sortAccounts(List<ChartOfAccount> accounts) {
    accounts.sort((a, b) => a.accountNumber.compareTo(b.accountNumber));
    return accounts;
  }
}
