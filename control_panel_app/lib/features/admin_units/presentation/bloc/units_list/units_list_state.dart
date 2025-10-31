// lib/features/admin_units/presentation/bloc/units_list/units_list_state.dart

part of 'units_list_bloc.dart';

abstract class UnitsListState extends Equatable {
  const UnitsListState();

  @override
  List<Object?> get props => [];
}

class UnitsListInitial extends UnitsListState {}

class UnitsListLoading extends UnitsListState {}

class UnitsListLoaded extends UnitsListState {
  final List<Unit> units;
  final List<Unit> selectedUnits;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final String? searchQuery;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic>? stats;

  const UnitsListLoaded({
    required this.units,
    this.selectedUnits = const [],
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    this.hasMore = false,
    this.searchQuery,
    this.filters,
    this.stats,
  });

  @override
  List<Object?> get props => [
        units,
        selectedUnits,
        totalCount,
        currentPage,
        pageSize,
        hasMore,
        searchQuery,
        filters,
        stats,
      ];

  UnitsListLoaded copyWith({
    List<Unit>? units,
    List<Unit>? selectedUnits,
    int? totalCount,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    String? searchQuery,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? stats,
  }) {
    return UnitsListLoaded(
      units: units ?? this.units,
      selectedUnits: selectedUnits ?? this.selectedUnits,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery,
      filters: filters,
      stats: stats ?? this.stats,
    );
  }
}

class UnitsListError extends UnitsListState {
  final String message;

  const UnitsListError({required this.message});

  @override
  List<Object?> get props => [message];
}
