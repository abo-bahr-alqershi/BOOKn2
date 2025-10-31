// lib/features/admin_citys/presentation/bloc/city_images/city_images_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import '../../../domain/entities/city_image.dart';
import '../../../domain/usecases/city_images/upload_city_image_usecase.dart';
import '../../../domain/usecases/city_images/upload_multiple_city_images_usecase.dart';
import '../../../domain/usecases/city_images/get_city_images_usecase.dart';
import '../../../domain/usecases/city_images/update_city_image_usecase.dart';
import '../../../domain/usecases/city_images/delete_city_image_usecase.dart';
import '../../../domain/usecases/city_images/delete_multiple_city_images_usecase.dart';
import '../../../domain/usecases/city_images/reorder_city_images_usecase.dart';
import '../../../domain/usecases/city_images/set_primary_city_image_usecase.dart';
import 'city_images_event.dart';
import 'city_images_state.dart';

class CityImagesBloc extends Bloc<CityImagesEvent, CityImagesState> {
  final UploadCityImageUseCase uploadCityImage;
  final UploadMultipleCityImagesUseCase uploadMultipleImages;
  final GetCityImagesUseCase getCityImages;
  final UpdateCityImageUseCase updateCityImage;
  final DeleteCityImageUseCase deleteCityImage;
  final DeleteMultipleCityImagesUseCase deleteMultipleImages;
  final ReorderCityImagesUseCase reorderImages;
  final SetPrimaryCityImageUseCase setPrimaryImage;

  List<CityImage> _currentImages = [];
  Set<String> _selectedImageIds = {};
  String? _currentCityId;

  CityImagesBloc({
    required this.uploadCityImage,
    required this.uploadMultipleImages,
    required this.getCityImages,
    required this.updateCityImage,
    required this.deleteCityImage,
    required this.deleteMultipleImages,
    required this.reorderImages,
    required this.setPrimaryImage,
  }) : super(const CityImagesInitial()) {
    on<LoadCityImagesEvent>(_onLoadCityImages);
    on<UploadCityImageEvent>(_onUploadCityImage);
    on<UploadMultipleCityImagesEvent>(_onUploadMultipleImages);
    on<UpdateCityImageEvent>(_onUpdateCityImage);
    on<DeleteCityImageEvent>(_onDeleteCityImage);
    on<DeleteMultipleCityImagesEvent>(_onDeleteMultipleImages);
    on<ReorderCityImagesEvent>(_onReorderCityImages);
    on<SetPrimaryCityImageEvent>(_onSetPrimaryCityImage);
    on<ClearCityImagesEvent>(_onClearCityImages);
    on<RefreshCityImagesEvent>(_onRefreshCityImages);
    on<ToggleCityImageSelectionEvent>(_onToggleCityImageSelection);
    on<SelectAllCityImagesEvent>(_onSelectAllCityImages);
    on<DeselectAllCityImagesEvent>(_onDeselectAllCityImages);
  }

  Future<void> _onLoadCityImages(
    LoadCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    // منع جلب الصور إذا لم يكن هناك cityId أو tempKey
    if ((event.cityId == null || event.cityId!.isEmpty) &&
        (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(const CityImagesLoaded(images: []));
      return;
    }

    emit(const CityImagesLoading(message: 'Loading images...'));

    final Either<Failure, List<CityImage>> result = await getCityImages(
        GetCityImagesParams(cityId: event.cityId, tempKey: event.tempKey));

    result.fold(
      (failure) => emit(CityImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentCityId = event.cityId;
        emit(CityImagesLoaded(
          images: images,
          currentCityId: event.cityId,
        ));
      },
    );
  }

  Future<void> _onUploadCityImage(
    UploadCityImageEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    // تحقق من وجود cityId أو tempKey قبل الرفع
    if ((event.cityId == null || event.cityId!.isEmpty) &&
        (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(CityImagesError(
        message: 'لا يمكن رفع الصور بدون معرف الوحدة أو tempKey',
        previousImages: _currentImages,
      ));
      return;
    }

    emit(CityImageUploading(
      currentImages: _currentImages,
      uploadingFileName: event.filePath.split('/').last,
    ));

    final params = UploadImageParams(
      cityId: event.cityId,
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
          emit(CityImageUploading(
            currentImages: _currentImages,
            uploadingFileName: event.filePath.split('/').last,
            uploadProgress: progress,
          ));
        }
      },
    );

    final Either<Failure, CityImage> result = await uploadCityImage(params);

    result.fold(
      (failure) => emit(CityImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (image) {
        _currentImages.add(image);
        emit(CityImageUploaded(
          uploadedImage: image,
          allImages: List.from(_currentImages),
        ));
        // بعد ثانية واحدة، عرض قائمة الصور المحدثة
        Future.delayed(const Duration(seconds: 1), () {
          // add(LoadCityImagesEvent(cityId: event.cityId));
        });
      },
    );
  }

  Future<void> _onUploadMultipleImages(
    UploadMultipleCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    emit(CityImageUploading(
      currentImages: _currentImages,
      totalFiles: event.filePaths.length,
      currentFileIndex: 0,
    ));

    final params = UploadMultipleImagesParams(
      cityId: event.cityId,
      tempKey: event.tempKey,
      filePaths: event.filePaths,
      category: event.category,
      tags: event.tags,
      onProgress: (filePath, sent, total) {
        if (total > 0) {
          final progress = sent / total;
          emit(CityImageUploading(
            currentImages: _currentImages,
            uploadingFileName: filePath.split('/').last,
            uploadProgress: progress,
            totalFiles: event.filePaths.length,
          ));
        }
      },
    );

    final Either<Failure, List<CityImage>> result =
        await uploadMultipleImages(params);

    result.fold(
      (failure) => emit(CityImagesError(
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
          add(LoadCityImagesEvent(
              cityId: event.cityId, tempKey: event.tempKey));
        });
      },
    );
  }

  Future<void> _onUpdateCityImage(
    UpdateCityImageEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    emit(CityImageUpdating(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final params = UpdateImageParams(
      imageId: event.imageId,
      data: event.data,
    );

    final Either<Failure, bool> result = await updateCityImage(params);

    result.fold(
      (failure) => emit(CityImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success && _currentCityId != null) {
          // إعادة تحميل الصور للحصول على البيانات المحدثة
          add(LoadCityImagesEvent(cityId: _currentCityId!));
        } else {
          emit(CityImageUpdated(
            updatedImages: _currentImages,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteCityImage(
    DeleteCityImageEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    emit(CityImageDeleting(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final Either<Failure, bool> result = await deleteCityImage(event.imageId);

    result.fold(
      (failure) => emit(CityImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          _currentImages.removeWhere((image) => image.id == event.imageId);
          _selectedImageIds.remove(event.imageId);
          emit(CityImageDeleted(
            remainingImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onDeleteMultipleImages(
    DeleteMultipleCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    emit(CityImagesLoading(message: 'Deleting selected images...'));

    final Either<Failure, bool> result =
        await deleteMultipleImages(event.imageIds);

    result.fold(
      (failure) => emit(CityImagesError(
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

  Future<void> _onReorderCityImages(
    ReorderCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    emit(ImagesReordering(currentImages: _currentImages));

    final params = ReorderImagesParams(
      cityId: event.cityId,
      tempKey: event.tempKey,
      imageIds: event.imageIds,
    );

    final Either<Failure, bool> result = await reorderImages(params);

    result.fold(
      (failure) => emit(CityImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          // إعادة ترتيب الصور محلياً
          final Map<String, CityImage> imageMap = {
            for (var image in _currentImages) image.id: image
          };
          _currentImages = event.imageIds
              .map((id) => imageMap[id])
              .whereType<CityImage>()
              .toList();

          emit(ImagesReordered(
            reorderedImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onSetPrimaryCityImage(
    SetPrimaryCityImageEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    emit(CityImagesLoading(message: 'Setting primary image...'));

    final params = SetPrimaryImageParams(
      cityId: event.cityId,
      tempKey: event.tempKey,
      imageId: event.imageId,
    );

    final Either<Failure, bool> result = await setPrimaryImage(params);

    result.fold(
      (failure) => emit(CityImagesError(
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

          // إعادة تحميل الصور للحصول على البيانات المحدثة (الحفاظ على tempKey)
          add(LoadCityImagesEvent(
              cityId: event.cityId, tempKey: event.tempKey));
        }
      },
    );
  }

  void _onClearCityImages(
    ClearCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) {
    _currentImages = [];
    _selectedImageIds = {};
    _currentCityId = null;
    emit(const CityImagesInitial());
  }

  Future<void> _onRefreshCityImages(
    RefreshCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) async {
    // لا نظهر loading state عند التحديث
    final Either<Failure, List<CityImage>> result = await getCityImages(
        GetCityImagesParams(cityId: event.cityId, tempKey: event.tempKey));

    result.fold(
      (failure) => emit(CityImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentCityId = event.cityId;
        emit(CityImagesLoaded(
          images: images,
          currentCityId: event.cityId,
          selectedImageIds: _selectedImageIds,
          isSelectionMode: _selectedImageIds.isNotEmpty,
        ));
      },
    );
  }

  void _onToggleCityImageSelection(
    ToggleCityImageSelectionEvent event,
    Emitter<CityImagesState> emit,
  ) {
    if (_selectedImageIds.contains(event.imageId)) {
      _selectedImageIds.remove(event.imageId);
    } else {
      _selectedImageIds.add(event.imageId);
    }

    emit(CityImagesLoaded(
      images: _currentImages,
      currentCityId: _currentCityId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: _selectedImageIds.isNotEmpty,
    ));
  }

  void _onSelectAllCityImages(
    SelectAllCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) {
    _selectedImageIds = _currentImages.map((image) => image.id).toSet();

    emit(CityImagesLoaded(
      images: _currentImages,
      currentCityId: _currentCityId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: true,
    ));
  }

  void _onDeselectAllCityImages(
    DeselectAllCityImagesEvent event,
    Emitter<CityImagesState> emit,
  ) {
    _selectedImageIds.clear();

    emit(CityImagesLoaded(
      images: _currentImages,
      currentCityId: _currentCityId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: false,
    ));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
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
    _currentCityId = null;
    return super.close();
  }
}
