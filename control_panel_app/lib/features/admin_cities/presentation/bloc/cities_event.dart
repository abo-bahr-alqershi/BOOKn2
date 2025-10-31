import 'package:equatable/equatable.dart';
import '../../domain/entities/city.dart';

abstract class CitiesEvent extends Equatable {
  const CitiesEvent();

  @override
  List<Object?> get props => [];
}

/// Load cities event
class LoadCitiesEvent extends CitiesEvent {
  final int? page;
  final int? limit;
  final String? search;
  final String? country;
  final bool? isActive;

  const LoadCitiesEvent({
    this.page,
    this.limit,
    this.search,
    this.country,
    this.isActive,
  });

  @override
  List<Object?> get props => [page, limit, search, country, isActive];
}

/// Save cities event
class SaveCitiesEvent extends CitiesEvent {
  final List<City> cities;
  const SaveCitiesEvent({required this.cities});

  @override
  List<Object?> get props => [cities];
}

/// Create city event
class CreateCityEvent extends CitiesEvent {
  final City city;
  const CreateCityEvent({required this.city});

  @override
  List<Object?> get props => [city];
}

/// Update city event
class UpdateCityEvent extends CitiesEvent {
  final String oldName;
  final City city;
  const UpdateCityEvent({required this.oldName, required this.city});

  @override
  List<Object?> get props => [oldName, city];
}

/// Delete city event
class DeleteCityEvent extends CitiesEvent {
  final String name;
  const DeleteCityEvent({required this.name});

  @override
  List<Object?> get props => [name];
}

/// Search cities event
class SearchCitiesEvent extends CitiesEvent {
  final String query;
  const SearchCitiesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Load statistics event
class LoadCitiesStatisticsEvent extends CitiesEvent {}

/// Upload city image event
class UploadCityImageEvent extends CitiesEvent {
  final String cityName;
  final String imagePath;
  const UploadCityImageEvent({required this.cityName, required this.imagePath});

  @override
  List<Object?> get props => [cityName, imagePath];
}

/// Delete city image event
class DeleteCityImageEvent extends CitiesEvent {
  final String cityName;
  final String imageUrl;
  const DeleteCityImageEvent({required this.cityName, required this.imageUrl});

  @override
  List<Object?> get props => [cityName, imageUrl];
}

/// Refresh cities event
class RefreshCitiesEvent extends CitiesEvent {
  const RefreshCitiesEvent();

  @override
  List<Object?> get props => [];
}

/// Change page event
class ChangeCitiesPageEvent extends CitiesEvent {
  final int page;
  const ChangeCitiesPageEvent(this.page);

  @override
  List<Object?> get props => [page];
}

// Internal event for upload progress (public within library)
class CityImageProgressInternalEvent extends CitiesEvent {
  final String cityName;
  final double progress;
  const CityImageProgressInternalEvent(this.cityName, this.progress);

  @override
  List<Object?> get props => [cityName, progress];
}