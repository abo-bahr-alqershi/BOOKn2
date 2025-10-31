// lib/features/admin_citys/presentation/bloc/city_images/city_images_event.dart

import 'package:equatable/equatable.dart';

abstract class CityImagesEvent extends Equatable {
  const CityImagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCityImagesEvent extends CityImagesEvent {
  final String? cityId;
  final String? tempKey;

  const LoadCityImagesEvent({this.cityId, this.tempKey});

  @override
  List<Object?> get props => [cityId, tempKey];
}

class UploadCityImageEvent extends CityImagesEvent {
  final String? cityId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;

  const UploadCityImageEvent({
    this.cityId,
    this.tempKey,
    required this.filePath,
    this.category,
    this.alt,
    this.isPrimary = false,
    this.order,
    this.tags,
  });

  @override
  List<Object?> get props =>
      [cityId, tempKey, filePath, category, alt, isPrimary, order, tags];
}

class UploadMultipleCityImagesEvent extends CityImagesEvent {
  final String? cityId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;

  const UploadMultipleCityImagesEvent({
    this.cityId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
  });

  @override
  List<Object?> get props => [cityId, tempKey, filePaths, category, tags];
}

class UpdateCityImageEvent extends CityImagesEvent {
  final String imageId;
  final Map<String, dynamic> data;

  const UpdateCityImageEvent({
    required this.imageId,
    required this.data,
  });

  @override
  List<Object?> get props => [imageId, data];
}

class DeleteCityImageEvent extends CityImagesEvent {
  final String imageId;

  const DeleteCityImageEvent({required this.imageId});

  @override
  List<Object?> get props => [imageId];
}

class DeleteMultipleCityImagesEvent extends CityImagesEvent {
  final List<String> imageIds;

  const DeleteMultipleCityImagesEvent({required this.imageIds});

  @override
  List<Object?> get props => [imageIds];
}

class ReorderCityImagesEvent extends CityImagesEvent {
  final String? cityId;
  final String? tempKey;
  final List<String> imageIds;

  const ReorderCityImagesEvent({
    this.cityId,
    this.tempKey,
    required this.imageIds,
  });

  @override
  List<Object?> get props => [cityId, tempKey, imageIds];
}

class SetPrimaryCityImageEvent extends CityImagesEvent {
  final String? cityId;
  final String? tempKey;
  final String imageId;

  const SetPrimaryCityImageEvent({
    this.cityId,
    this.tempKey,
    required this.imageId,
  });

  @override
  List<Object?> get props => [cityId, tempKey, imageId];
}

class ClearCityImagesEvent extends CityImagesEvent {
  const ClearCityImagesEvent();
}

class RefreshCityImagesEvent extends CityImagesEvent {
  final String? cityId;
  final String? tempKey;

  const RefreshCityImagesEvent({this.cityId, this.tempKey});

  @override
  List<Object?> get props => [cityId, tempKey];
}

class ToggleCityImageSelectionEvent extends CityImagesEvent {
  final String imageId;

  const ToggleCityImageSelectionEvent({required this.imageId});

  @override
  List<Object?> get props => [imageId];
}

class SelectAllCityImagesEvent extends CityImagesEvent {
  const SelectAllCityImagesEvent();
}

class DeselectAllCityImagesEvent extends CityImagesEvent {
  const DeselectAllCityImagesEvent();
}
