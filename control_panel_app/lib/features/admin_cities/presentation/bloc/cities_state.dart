import 'package:equatable/equatable.dart';
import '../../domain/entities/city.dart';

abstract class CitiesState extends Equatable {
  const CitiesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CitiesInitial extends CitiesState {}

/// Loading state
class CitiesLoading extends CitiesState {}

/// Loaded state
class CitiesLoaded extends CitiesState {
  final List<City> cities;
  final List<City> filteredCities;
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final String? searchQuery;
  final Map<String, dynamic>? statistics;

  const CitiesLoaded({
    required this.cities,
    required this.filteredCities,
    this.currentPage = 1,
    this.totalPages = 1,
    this.itemsPerPage = 10,
    this.searchQuery,
    this.statistics,
  });

  CitiesLoaded copyWith({
    List<City>? cities,
    List<City>? filteredCities,
    int? currentPage,
    int? totalPages,
    int? itemsPerPage,
    String? searchQuery,
    Map<String, dynamic>? statistics,
  }) {
    return CitiesLoaded(
      cities: cities ?? this.cities,
      filteredCities: filteredCities ?? this.filteredCities,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      searchQuery: searchQuery ?? this.searchQuery,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => [
    cities,
    filteredCities,
    currentPage,
    totalPages,
    itemsPerPage,
    searchQuery,
    statistics,
  ];
}

/// Error state
class CitiesError extends CitiesState {
  final String message;

  const CitiesError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// City operation in progress
class CityOperationInProgress extends CitiesState {
  final String operation;
  final String? cityName;

  const CityOperationInProgress({
    required this.operation,
    this.cityName,
  });

  @override
  List<Object?> get props => [operation, cityName];
}

/// City operation success
class CityOperationSuccess extends CitiesState {
  final String message;

  const CityOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// City operation failure
class CityOperationFailure extends CitiesState {
  final String message;

  const CityOperationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Image upload progress
class CityImageUploadProgress extends CitiesState {
  final double progress;
  final String cityName;

  const CityImageUploadProgress({
    required this.progress,
    required this.cityName,
  });

  @override
  List<Object?> get props => [progress, cityName];
}