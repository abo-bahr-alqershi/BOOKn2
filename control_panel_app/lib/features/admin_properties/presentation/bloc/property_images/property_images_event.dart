// lib/features/admin_properties/presentation/bloc/property_images/property_images_event.dart

import 'package:equatable/equatable.dart';

abstract class PropertyImagesEvent extends Equatable {
  const PropertyImagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPropertyImagesEvent extends PropertyImagesEvent {
  final String? propertyId;
  final String? tempKey;

  const LoadPropertyImagesEvent({this.propertyId, this.tempKey});

  @override
  List<Object?> get props => [propertyId, tempKey];
}

class UploadPropertyImageEvent extends PropertyImagesEvent {
  final String? propertyId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;

  const UploadPropertyImageEvent({
    this.propertyId,
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
      [propertyId, tempKey, filePath, category, alt, isPrimary, order, tags];
}

class UploadMultipleImagesEvent extends PropertyImagesEvent {
  final String? propertyId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;

  const UploadMultipleImagesEvent({
    this.propertyId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
  });

  @override
  List<Object?> get props => [propertyId, tempKey, filePaths, category, tags];
}

class UpdatePropertyImageEvent extends PropertyImagesEvent {
  final String imageId;
  final Map<String, dynamic> data;

  const UpdatePropertyImageEvent({
    required this.imageId,
    required this.data,
  });

  @override
  List<Object?> get props => [imageId, data];
}

class DeletePropertyImageEvent extends PropertyImagesEvent {
  final String imageId;

  const DeletePropertyImageEvent({required this.imageId});

  @override
  List<Object?> get props => [imageId];
}

class DeleteMultipleImagesEvent extends PropertyImagesEvent {
  final List<String> imageIds;

  const DeleteMultipleImagesEvent({required this.imageIds});

  @override
  List<Object?> get props => [imageIds];
}

class ReorderImagesEvent extends PropertyImagesEvent {
  final String? propertyId;
  final String? tempKey;
  final List<String> imageIds;

  const ReorderImagesEvent({
    this.propertyId,
    this.tempKey,
    required this.imageIds,
  });

  @override
  List<Object?> get props => [propertyId, tempKey, imageIds];
}

class SetPrimaryImageEvent extends PropertyImagesEvent {
  final String? propertyId;
  final String? tempKey;
  final String imageId;

  const SetPrimaryImageEvent({
    this.propertyId,
    this.tempKey,
    required this.imageId,
  });

  @override
  List<Object?> get props => [propertyId, tempKey, imageId];
}

class ClearPropertyImagesEvent extends PropertyImagesEvent {
  const ClearPropertyImagesEvent();
}

class RefreshPropertyImagesEvent extends PropertyImagesEvent {
  final String? propertyId;
  final String? tempKey;

  const RefreshPropertyImagesEvent({this.propertyId, this.tempKey});

  @override
  List<Object?> get props => [propertyId, tempKey];
}

class ToggleImageSelectionEvent extends PropertyImagesEvent {
  final String imageId;

  const ToggleImageSelectionEvent({required this.imageId});

  @override
  List<Object?> get props => [imageId];
}

class SelectAllImagesEvent extends PropertyImagesEvent {
  const SelectAllImagesEvent();
}

class DeselectAllImagesEvent extends PropertyImagesEvent {
  const DeselectAllImagesEvent();
}
