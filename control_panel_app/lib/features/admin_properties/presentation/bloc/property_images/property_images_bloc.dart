// lib/features/admin_properties/presentation/bloc/property_images/property_images_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import '../../../domain/entities/property_image.dart';
import '../../../domain/usecases/property_images/upload_property_image_usecase.dart';
import '../../../domain/usecases/property_images/upload_multiple_images_usecase.dart';
import '../../../domain/usecases/property_images/get_property_images_usecase.dart';
import '../../../domain/usecases/property_images/update_property_image_usecase.dart';
import '../../../domain/usecases/property_images/delete_property_image_usecase.dart';
import '../../../domain/usecases/property_images/delete_multiple_images_usecase.dart';
import '../../../domain/usecases/property_images/reorder_images_usecase.dart';
import '../../../domain/usecases/property_images/set_primary_image_usecase.dart';
import 'property_images_event.dart';
import 'property_images_state.dart';

class PropertyImagesBloc
    extends Bloc<PropertyImagesEvent, PropertyImagesState> {
  final UploadPropertyImageUseCase uploadPropertyImage;
  final UploadMultipleImagesUseCase uploadMultipleImages;
  final GetPropertyImagesUseCase getPropertyImages;
  final UpdatePropertyImageUseCase updatePropertyImage;
  final DeletePropertyImageUseCase deletePropertyImage;
  final DeleteMultipleImagesUseCase deleteMultipleImages;
  final ReorderImagesUseCase reorderImages;
  final SetPrimaryImageUseCase setPrimaryImage;

  List<PropertyImage> _currentImages = [];
  Set<String> _selectedImageIds = {};
  String? _currentPropertyId;

  PropertyImagesBloc({
    required this.uploadPropertyImage,
    required this.uploadMultipleImages,
    required this.getPropertyImages,
    required this.updatePropertyImage,
    required this.deletePropertyImage,
    required this.deleteMultipleImages,
    required this.reorderImages,
    required this.setPrimaryImage,
  }) : super(const PropertyImagesInitial()) {
    on<LoadPropertyImagesEvent>(_onLoadPropertyImages);
    on<UploadPropertyImageEvent>(_onUploadPropertyImage);
    on<UploadMultipleImagesEvent>(_onUploadMultipleImages);
    on<UpdatePropertyImageEvent>(_onUpdatePropertyImage);
    on<DeletePropertyImageEvent>(_onDeletePropertyImage);
    on<DeleteMultipleImagesEvent>(_onDeleteMultipleImages);
    on<ReorderImagesEvent>(_onReorderImages);
    on<SetPrimaryImageEvent>(_onSetPrimaryImage);
    on<ClearPropertyImagesEvent>(_onClearPropertyImages);
    on<RefreshPropertyImagesEvent>(_onRefreshPropertyImages);
    on<ToggleImageSelectionEvent>(_onToggleImageSelection);
    on<SelectAllImagesEvent>(_onSelectAllImages);
    on<DeselectAllImagesEvent>(_onDeselectAllImages);
  }
  Future<void> _onLoadPropertyImages(
    LoadPropertyImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    // منع جلب الصور إذا لم يكن هناك propertyId أو tempKey
    if ((event.propertyId == null || event.propertyId!.isEmpty) &&
        (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(const PropertyImagesLoaded(images: []));
      return;
    }

    emit(const PropertyImagesLoading(message: 'Loading images...'));

    final Either<Failure, List<PropertyImage>> result = await getPropertyImages(
        GetImagesParams(propertyId: event.propertyId, tempKey: event.tempKey));

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentPropertyId = event.propertyId;
        emit(PropertyImagesLoaded(
          images: images,
          currentPropertyId: event.propertyId,
        ));
      },
    );
  }

  Future<void> _onUploadPropertyImage(
    UploadPropertyImageEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    // require propertyId or tempKey
    if ((event.propertyId == null || event.propertyId!.isEmpty) &&
        (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(PropertyImagesError(
        message: 'لا يمكن رفع الصور بدون معرف العقار أو tempKey',
        previousImages: _currentImages,
      ));
      return;
    }

    emit(PropertyImageUploading(
      currentImages: _currentImages,
      uploadingFileName: event.filePath.split('/').last,
    ));

    final params = UploadImageParams(
      propertyId: event.propertyId,
      tempKey: event.tempKey,
      filePath: event.filePath,
      category: event.category,
      alt: event.alt,
      isPrimary: event.isPrimary,
      order: event.order,
      tags: event.tags,
      onSendProgress: (sent, total) {
        if (total > 0) {
          final progress = sent / total;
          emit(PropertyImageUploading(
            currentImages: _currentImages,
            uploadingFileName: event.filePath.split('/').last,
            uploadProgress: progress,
          ));
        }
      },
    );

    final Either<Failure, PropertyImage> result =
        await uploadPropertyImage(params);

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (image) {
        _currentImages.add(image);
        emit(PropertyImageUploaded(
          uploadedImage: image,
          allImages: List.from(_currentImages),
        ));
        // بعد ثانية واحدة، عرض قائمة الصور المحدثة
        Future.delayed(const Duration(seconds: 1), () {
          // add(LoadPropertyImagesEvent(propertyId: event.propertyId, tempKey: event.tempKey));
        });
      },
    );
  }

  Future<void> _onUploadMultipleImages(
    UploadMultipleImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    emit(PropertyImageUploading(
      currentImages: _currentImages,
      totalFiles: event.filePaths.length,
      currentFileIndex: 0,
    ));

    final params = UploadMultipleImagesParams(
      propertyId: event.propertyId,
      tempKey: event.tempKey,
      filePaths: event.filePaths,
      category: event.category,
      tags: event.tags,
      onProgress: (filePath, sent, total) {
        if (total > 0) {
          final progress = sent / total;
          emit(PropertyImageUploading(
            currentImages: _currentImages,
            uploadingFileName: filePath.split('/').last,
            uploadProgress: progress,
            totalFiles: event.filePaths.length,
          ));
        }
      },
    );

    final Either<Failure, List<PropertyImage>> result =
        await uploadMultipleImages(params);

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages.addAll(images);
        emit(MultipleImagesUploaded(
          uploadedImages: images,
          allImages: List.from(_currentImages),
          successCount: images.length,
          failedCount: event.filePaths.length - images.length,
        ));
        // بعد ثانية واحدة، عرض قائمة الصور المحدثة
        Future.delayed(const Duration(seconds: 1), () {
          add(LoadPropertyImagesEvent(
              propertyId: event.propertyId, tempKey: event.tempKey));
        });
      },
    );
  }

  Future<void> _onUpdatePropertyImage(
    UpdatePropertyImageEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    emit(PropertyImageUpdating(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final params = UpdateImageParams(
      imageId: event.imageId,
      data: event.data,
    );

    final Either<Failure, bool> result = await updatePropertyImage(params);

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success && _currentPropertyId != null) {
          // إعادة تحميل الصور للحصول على البيانات المحدثة
          add(LoadPropertyImagesEvent(propertyId: _currentPropertyId!));
        } else {
          emit(PropertyImageUpdated(
            updatedImages: _currentImages,
          ));
        }
      },
    );
  }

  Future<void> _onDeletePropertyImage(
    DeletePropertyImageEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    emit(PropertyImageDeleting(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final Either<Failure, bool> result =
        await deletePropertyImage(event.imageId);

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          _currentImages.removeWhere((image) => image.id == event.imageId);
          _selectedImageIds.remove(event.imageId);
          emit(PropertyImageDeleted(
            remainingImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onDeleteMultipleImages(
    DeleteMultipleImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    emit(const PropertyImagesLoading(message: 'Deleting selected images...'));

    final Either<Failure, bool> result =
        await deleteMultipleImages(event.imageIds);

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          _currentImages
              .removeWhere((image) => event.imageIds.contains(image.id));
          _selectedImageIds.clear();
          emit(MultipleImagesDeleted(
            remainingImages: List.from(_currentImages),
            deletedCount: event.imageIds.length,
          ));
        }
      },
    );
  }

  Future<void> _onReorderImages(
    ReorderImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    emit(ImagesReordering(currentImages: _currentImages));

    final params = ReorderImagesParams(
      propertyId: event.propertyId,
      tempKey: event.tempKey,
      imageIds: event.imageIds,
    );

    final Either<Failure, bool> result = await reorderImages(params);

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          // إعادة ترتيب الصور محلياً
          final Map<String, PropertyImage> imageMap = {
            for (var image in _currentImages) image.id: image
          };
          _currentImages = event.imageIds
              .map((id) => imageMap[id])
              .whereType<PropertyImage>()
              .toList();

          emit(ImagesReordered(
            reorderedImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onSetPrimaryImage(
    SetPrimaryImageEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    emit(const PropertyImagesLoading(message: 'Setting primary image...'));

    final params = SetPrimaryImageParams(
      propertyId: event.propertyId,
      tempKey: event.tempKey,
      imageId: event.imageId,
    );

    final Either<Failure, bool> result = await setPrimaryImage(params);

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          // تحديث الصور محلياً
          for (var image in _currentImages) {
            if (image.id == event.imageId) {
              // نحتاج لتحديث isPrimary هنا
              // قد نحتاج لإعادة تحميل الصور من الخادم
            }
          }

          // إعادة تحميل الصور للحصول على البيانات المحدثة (يجب تمرير tempKey إن وُجد)
          add(LoadPropertyImagesEvent(
              propertyId: event.propertyId, tempKey: event.tempKey));
        }
      },
    );
  }

  void _onClearPropertyImages(
    ClearPropertyImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) {
    _currentImages = [];
    _selectedImageIds = {};
    _currentPropertyId = null;
    emit(const PropertyImagesInitial());
  }

  Future<void> _onRefreshPropertyImages(
    RefreshPropertyImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) async {
    // لا نظهر loading state عند التحديث
    final Either<Failure, List<PropertyImage>> result = await getPropertyImages(
        GetImagesParams(propertyId: event.propertyId, tempKey: event.tempKey));

    result.fold(
      (failure) => emit(PropertyImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentPropertyId = event.propertyId;
        emit(PropertyImagesLoaded(
          images: images,
          currentPropertyId: event.propertyId,
          selectedImageIds: _selectedImageIds,
          isSelectionMode: _selectedImageIds.isNotEmpty,
        ));
      },
    );
  }

  void _onToggleImageSelection(
    ToggleImageSelectionEvent event,
    Emitter<PropertyImagesState> emit,
  ) {
    if (_selectedImageIds.contains(event.imageId)) {
      _selectedImageIds.remove(event.imageId);
    } else {
      _selectedImageIds.add(event.imageId);
    }

    emit(PropertyImagesLoaded(
      images: _currentImages,
      currentPropertyId: _currentPropertyId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: _selectedImageIds.isNotEmpty,
    ));
  }

  void _onSelectAllImages(
    SelectAllImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) {
    _selectedImageIds = _currentImages.map((image) => image.id).toSet();

    emit(PropertyImagesLoaded(
      images: _currentImages,
      currentPropertyId: _currentPropertyId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: true,
    ));
  }

  void _onDeselectAllImages(
    DeselectAllImagesEvent event,
    Emitter<PropertyImagesState> emit,
  ) {
    _selectedImageIds.clear();

    emit(PropertyImagesLoaded(
      images: _currentImages,
      currentPropertyId: _currentPropertyId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: false,
    ));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message ?? 'Server Error';
      case NetworkFailure:
        return 'Network connection error. Please check your internet connection.';
      case CacheFailure:
        return 'Cache Error';
      default:
        return 'Unexpected error occurred';
    }
  }

  @override
  Future<void> close() {
    _currentImages = [];
    _selectedImageIds = {};
    _currentPropertyId = null;
    return super.close();
  }
}
