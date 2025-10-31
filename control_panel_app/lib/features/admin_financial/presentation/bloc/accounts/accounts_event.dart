// lib/features/admin_financial/presentation/bloc/accounts/accounts_event.dart

part of 'accounts_bloc.dart';

/// 📋 أحداث دليل الحسابات
abstract class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object?> get props => [];
}

/// تحميل دليل الحسابات الكامل
class LoadChartOfAccounts extends AccountsEvent {
  const LoadChartOfAccounts();
}

/// البحث في الحسابات
class SearchAccounts extends AccountsEvent {
  final String query;

  const SearchAccounts({required this.query});

  @override
  List<Object> get props => [query];
}

/// فلترة الحسابات حسب النوع
class FilterAccountsByType extends AccountsEvent {
  final AccountType type;

  const FilterAccountsByType({required this.type});

  @override
  List<Object> get props => [type];
}

/// تحميل الحسابات الرئيسية فقط
class LoadMainAccounts extends AccountsEvent {
  const LoadMainAccounts();
}
