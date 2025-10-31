import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/city.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/save_cities_usecase.dart';
import '../../domain/usecases/create_city_usecase.dart';
import '../../domain/usecases/update_city_usecase.dart';
import '../../domain/usecases/delete_city_usecase.dart';
import '../../domain/usecases/search_cities_usecase.dart';
import '../../domain/usecases/get_cities_statistics_usecase.dart';
import '../../domain/usecases/upload_city_image_usecase.dart';
import '../../domain/usecases/delete_city_image_usecase.dart';
import 'cities_event.dart';
import 'cities_state.dart';

class CitiesBloc extends Bloc<CitiesEvent, CitiesState> {
  final GetCitiesUseCase getCities;
  final SaveCitiesUseCase saveCities;
  final CreateCityUseCase createCity;
  final UpdateCityUseCase updateCity;
  final DeleteCityUseCase deleteCity;
  final SearchCitiesUseCase searchCities;
  final GetCitiesStatisticsUseCase getCitiesStatistics;
  final UploadCityImageUseCase uploadCityImage;
  final DeleteCityImageUseCase deleteCityImage;

  static const int _itemsPerPage = 10;
  List<City> _allCities = [];
  Map<String, dynamic>? _statistics;

  CitiesBloc({
    required this.getCities,
    required this.saveCities,
    required this.createCity,
    required this.updateCity,
    required this.deleteCity,
    required this.searchCities,
    required this.getCitiesStatistics,
    required this.uploadCityImage,
    required this.deleteCityImage,
  }) : super(CitiesInitial()) {
    on<LoadCitiesEvent>(_onLoadCities);
    on<SaveCitiesEvent>(_onSaveCities);
    on<CreateCityEvent>(_onCreateCity);
    on<UpdateCityEvent>(_onUpdateCity);
    on<DeleteCityEvent>(_onDeleteCity);
    on<SearchCitiesEvent>(_onSearchCities);
    on<LoadCitiesStatisticsEvent>(_onLoadStatistics);
    on<UploadCityImageEvent>(_onUploadImage);
    on<DeleteCityImageEvent>(_onDeleteImage);
    on<RefreshCitiesEvent>(_onRefreshCities);
    on<ChangeCitiesPageEvent>(_onChangePage);
    on<CityImageProgressInternalEvent>(_onCityImageProgressInternal);
  }

  Future<void> _onLoadCities(
    LoadCitiesEvent event,
    Emitter<CitiesState> emit,
  ) async {
    emit(CitiesLoading());

    final result = await getCities(GetCitiesParams(
      page: event.page,
      limit: event.limit,
      search: event.search,
      country: event.country,
      isActive: event.isActive,
    ));

    result.fold(
      (failure) => emit(CitiesError(message: failure.message)),
      (cities) {
        _allCities = cities;
        final totalPages = (cities.length / _itemsPerPage).ceil();

        final pagedCities = _getPagedCities(1);

        emit(CitiesLoaded(
          cities: cities,
          filteredCities: pagedCities,
          currentPage: 1,
          totalPages: totalPages,
          itemsPerPage: _itemsPerPage,
          statistics: _statistics,
        ));
      },
    );
  }

  Future<void> _onSaveCities(
    SaveCitiesEvent event,
    Emitter<CitiesState> emit,
  ) async {
    final currentState = state;
    emit(const CityOperationInProgress(operation: 'saving'));

    final result = await saveCities(event.cities);

    result.fold(
      (failure) {
        emit(CityOperationFailure(message: failure.message));
        if (currentState is CitiesLoaded) {
          emit(currentState);
        }
      },
      (success) {
        emit(const CityOperationSuccess(message: 'تم حفظ المدن بنجاح'));
        add(const RefreshCitiesEvent());
      },
    );
  }

  Future<void> _onCreateCity(
    CreateCityEvent event,
    Emitter<CitiesState> emit,
  ) async {
    final currentState = state;
    emit(CityOperationInProgress(
      operation: 'creating',
      cityName: event.city.name,
    ));

    final result = await createCity(event.city);

    result.fold(
      (failure) {
        emit(CityOperationFailure(message: failure.message));
        if (currentState is CitiesLoaded) {
          emit(currentState);
        }
      },
      (city) {
        emit(const CityOperationSuccess(message: 'تم إضافة المدينة بنجاح'));
        add(const RefreshCitiesEvent());
      },
    );
  }

  Future<void> _onUpdateCity(
    UpdateCityEvent event,
    Emitter<CitiesState> emit,
  ) async {
    final currentState = state;
    emit(CityOperationInProgress(
      operation: 'updating',
      cityName: event.oldName,
    ));

    final result = await updateCity(UpdateCityParams(
      oldName: event.oldName,
      city: event.city,
    ));

    result.fold(
      (failure) {
        emit(CityOperationFailure(message: failure.message));
        if (currentState is CitiesLoaded) {
          emit(currentState);
        }
      },
      (city) {
        emit(const CityOperationSuccess(message: 'تم تحديث المدينة بنجاح'));
        add(const RefreshCitiesEvent());
      },
    );
  }

  Future<void> _onDeleteCity(
    DeleteCityEvent event,
    Emitter<CitiesState> emit,
  ) async {
    final currentState = state;
    emit(CityOperationInProgress(
      operation: 'deleting',
      cityName: event.name,
    ));

    final result = await deleteCity(event.name);

    result.fold(
      (failure) {
        emit(CityOperationFailure(message: failure.message));
        if (currentState is CitiesLoaded) {
          emit(currentState);
        }
      },
      (success) {
        emit(const CityOperationSuccess(message: 'تم حذف المدينة بنجاح'));

        // Update local list immediately
        if (currentState is CitiesLoaded) {
          final updatedCities = List<City>.from(currentState.cities)
            ..removeWhere((city) => city.name == event.name);

          final totalPages = (updatedCities.length / _itemsPerPage).ceil();
          var currentPage = currentState.currentPage;

          // Adjust page if necessary
          if (currentPage > totalPages && totalPages > 0) {
            currentPage = totalPages;
          }

          final pagedCities = _getPagedCitiesFromList(
            updatedCities,
            currentPage,
          );

          emit(currentState.copyWith(
            cities: updatedCities,
            filteredCities: pagedCities,
            currentPage: currentPage,
            totalPages: totalPages,
          ));
        }
      },
    );
  }

  Future<void> _onSearchCities(
    SearchCitiesEvent event,
    Emitter<CitiesState> emit,
  ) async {
    if (state is CitiesLoaded) {
      final currentState = state as CitiesLoaded;

      if (event.query.isEmpty) {
        // Reset to all cities
        final pagedCities = _getPagedCities(1);
        emit(currentState.copyWith(
          filteredCities: pagedCities,
          currentPage: 1,
          searchQuery: null,
        ));
      } else {
        // Filter cities
        final filteredCities = _allCities
            .where((city) =>
                city.name.toLowerCase().contains(event.query.toLowerCase()) ||
                city.country.toLowerCase().contains(event.query.toLowerCase()))
            .toList();

        final totalPages = (filteredCities.length / _itemsPerPage).ceil();
        final pagedCities = _getPagedCitiesFromList(filteredCities, 1);

        emit(currentState.copyWith(
          filteredCities: pagedCities,
          currentPage: 1,
          totalPages: totalPages,
          searchQuery: event.query,
        ));
      }
    }
  }

  Future<void> _onLoadStatistics(
    LoadCitiesStatisticsEvent event,
    Emitter<CitiesState> emit,
  ) async {
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));
    final result = await getCitiesStatistics(GetCitiesStatsParams(startDate: last30, endDate: now));

    result.fold(
      (failure) => null, // Silently fail for statistics
      (statistics) {
        _statistics = statistics;
        if (state is CitiesLoaded) {
          final currentState = state as CitiesLoaded;
          emit(currentState.copyWith(statistics: statistics));
        }
      },
    );
  }

  Future<void> _onUploadImage(
    UploadCityImageEvent event,
    Emitter<CitiesState> emit,
  ) async {
    emit(CityImageUploadProgress(
      progress: 0,
      cityName: event.cityName,
    ));

    final result = await uploadCityImage(UploadCityImageParams(
      cityName: event.cityName,
      imagePath: event.imagePath,
      onSendProgress: (sent, total) {
        if (total > 0) {
          final p = sent / total;
          add(CityImageProgressInternalEvent(event.cityName, p));
        }
      },
    ));

    result.fold(
      (failure) => emit(CityOperationFailure(message: failure.message)),
      (imageUrl) {
        // Update city with new image
        final cityIndex = _allCities.indexWhere(
          (city) => city.name == event.cityName,
        );

        if (cityIndex != -1) {
          final updatedCity = _allCities[cityIndex].copyWith(
            images: [..._allCities[cityIndex].images, imageUrl],
          );

          add(UpdateCityEvent(
            oldName: event.cityName,
            city: updatedCity,
          ));
        }
      },
    );
  }

  // Internal event to reflect upload progress in state safely
  void _onCityImageProgressInternal(
    CityImageProgressInternalEvent event,
    Emitter<CitiesState> emit,
  ) {
    emit(CityImageUploadProgress(
      progress: event.progress,
      cityName: event.cityName,
    ));
  }

  Future<void> _onDeleteImage(
    DeleteCityImageEvent event,
    Emitter<CitiesState> emit,
  ) async {
    final result = await deleteCityImage(DeleteCityImageParams(
      cityName: event.cityName,
      imageUrl: event.imageUrl,
    ));

    result.fold(
      (failure) => emit(CityOperationFailure(message: failure.message)),
      (success) {
        // Update city without the deleted image
        final cityIndex = _allCities.indexWhere(
          (city) => city.name == event.cityName,
        );

        if (cityIndex != -1) {
          final updatedImages = List<String>.from(
            _allCities[cityIndex].images,
          )..remove(event.imageUrl);

          final updatedCity = _allCities[cityIndex].copyWith(
            images: updatedImages,
          );

          add(UpdateCityEvent(
            oldName: event.cityName,
            city: updatedCity,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshCities(
    RefreshCitiesEvent event,
    Emitter<CitiesState> emit,
  ) async {
    add(const LoadCitiesEvent());
    add(LoadCitiesStatisticsEvent());
  }

  Future<void> _onChangePage(
    ChangeCitiesPageEvent event,
    Emitter<CitiesState> emit,
  ) async {
    if (state is CitiesLoaded) {
      final currentState = state as CitiesLoaded;
      final pagedCities = currentState.searchQuery != null
          ? _getFilteredPagedCities(currentState.searchQuery!, event.page)
          : _getPagedCities(event.page);

      emit(currentState.copyWith(
        filteredCities: pagedCities,
        currentPage: event.page,
      ));
    }
  }

  List<City> _getPagedCities(int page) {
    return _getPagedCitiesFromList(_allCities, page);
  }

  List<City> _getPagedCitiesFromList(List<City> cities, int page) {
    final startIndex = (page - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= cities.length) {
      return [];
    }

    return cities.sublist(
      startIndex,
      endIndex > cities.length ? cities.length : endIndex,
    );
  }

  List<City> _getFilteredPagedCities(String query, int page) {
    final filteredCities = _allCities
        .where((city) =>
            city.name.toLowerCase().contains(query.toLowerCase()) ||
            city.country.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _getPagedCitiesFromList(filteredCities, page);
  }
}
