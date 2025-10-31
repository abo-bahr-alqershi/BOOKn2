// lib/features/admin_units/presentation/bloc/unit_images/unit_images_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import '../../../domain/entities/unit_image.dart';
import '../../../domain/usecases/unit_images/upload_unit_image_usecase.dart';
import '../../../domain/usecases/unit_images/upload_multiple_unit_images_usecase.dart';
import '../../../domain/usecases/unit_images/get_unit_images_usecase.dart';
import '../../../domain/usecases/unit_images/update_unit_image_usecase.dart';
import '../../../domain/usecases/unit_images/delete_unit_image_usecase.dart';
import '../../../domain/usecases/unit_images/delete_multiple_unit_images_usecase.dart';
import '../../../domain/usecases/unit_images/reorder_unit_images_usecase.dart';
import '../../../domain/usecases/unit_images/set_primary_unit_image_usecase.dart';
import 'unit_images_event.dart';
import 'unit_images_state.dart';

class UnitImagesBloc extends Bloc<UnitImagesEvent, UnitImagesState> {
  final UploadUnitImageUseCase uploadUnitImage;
  final UploadMultipleUnitImagesUseCase uploadMultipleImages;
  final GetUnitImagesUseCase getUnitImages;
  final UpdateUnitImageUseCase updateUnitImage;
  final DeleteUnitImageUseCase deleteUnitImage;
  final DeleteMultipleUnitImagesUseCase deleteMultipleImages;
  final ReorderUnitImagesUseCase reorderImages;
  final SetPrimaryUnitImageUseCase setPrimaryImage;

  List<UnitImage> _currentImages = [];
  Set<String> _selectedImageIds = {};
  String? _currentUnitId;

  UnitImagesBloc({
    required this.uploadUnitImage,
    required this.uploadMultipleImages,
    required this.getUnitImages,
    required this.updateUnitImage,
    required this.deleteUnitImage,
    required this.deleteMultipleImages,
    required this.reorderImages,
    required this.setPrimaryImage,
  }) : super(const UnitImagesInitial()) {
    on<LoadUnitImagesEvent>(_onLoadUnitImages);
    on<UploadUnitImageEvent>(_onUploadUnitImage);
    on<UploadMultipleUnitImagesEvent>(_onUploadMultipleImages);
    on<UpdateUnitImageEvent>(_onUpdateUnitImage);
    on<DeleteUnitImageEvent>(_onDeleteUnitImage);
    on<DeleteMultipleUnitImagesEvent>(_onDeleteMultipleImages);
    on<ReorderUnitImagesEvent>(_onReorderUnitImages);
    on<SetPrimaryUnitImageEvent>(_onSetPrimaryUnitImage);
    on<ClearUnitImagesEvent>(_onClearUnitImages);
    on<RefreshUnitImagesEvent>(_onRefreshUnitImages);
    on<ToggleUnitImageSelectionEvent>(_onToggleUnitImageSelection);
    on<SelectAllUnitImagesEvent>(_onSelectAllUnitImages);
    on<DeselectAllUnitImagesEvent>(_onDeselectAllUnitImages);
  }

  Future<void> _onLoadUnitImages(
    LoadUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    // منع جلب الصور إذا لم يكن هناك unitId أو tempKey
    if ((event.unitId == null || event.unitId!.isEmpty) && (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(const UnitImagesLoaded(images: []));
      return;
    }

    emit(const UnitImagesLoading(message: 'Loading images...'));

    final Either<Failure, List<UnitImage>> result =
        await getUnitImages(GetUnitImagesParams(unitId: event.unitId, tempKey: event.tempKey));

    result.fold(
      (failure) => emit(UnitImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentUnitId = event.unitId;
        emit(UnitImagesLoaded(
          images: images,
          currentUnitId: event.unitId,
        ));
      },
    );
  }

  Future<void> _onUploadUnitImage(
    UploadUnitImageEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    // تحقق من وجود unitId أو tempKey قبل الرفع
    if ((event.unitId == null || event.unitId!.isEmpty) && (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(UnitImagesError(
        message: 'لا يمكن رفع الصور بدون معرف الوحدة أو tempKey',
        previousImages: _currentImages,
      ));
      return;
    }

    emit(UnitImageUploading(
      currentImages: _currentImages,
      uploadingFileName: event.filePath.split('/').last,
    ));

    final params = UploadImageParams(
      unitId: event.unitId,
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
          emit(UnitImageUploading(
            currentImages: _currentImages,
            uploadingFileName: event.filePath.split('/').last,
            uploadProgress: progress,
          ));
        }
      },
    );

    final Either<Failure, UnitImage> result = await uploadUnitImage(params);

    result.fold(
      (failure) => emit(UnitImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (image) {
        _currentImages.add(image);
        emit(UnitImageUploaded(
          uploadedImage: image,
          allImages: List.from(_currentImages),
        ));
        // بعد ثانية واحدة، عرض قائمة الصور المحدثة
        Future.delayed(const Duration(seconds: 1), () {
          // add(LoadUnitImagesEvent(unitId: event.unitId));
        });
      },
    );
  }

  Future<void> _onUploadMultipleImages(
    UploadMultipleUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    emit(UnitImageUploading(
      currentImages: _currentImages,
      totalFiles: event.filePaths.length,
      currentFileIndex: 0,
    ));

    final params = UploadMultipleImagesParams(
      unitId: event.unitId,
      tempKey: event.tempKey,
      filePaths: event.filePaths,
      category: event.category,
      tags: event.tags,
      onProgress: (filePath, sent, total) {
        if (total > 0) {
          final progress = sent / total;
          emit(UnitImageUploading(
            currentImages: _currentImages,
            uploadingFileName: filePath.split('/').last,
            uploadProgress: progress,
            totalFiles: event.filePaths.length,
          ));
        }
      },
    );

    final Either<Failure, List<UnitImage>> result =
        await uploadMultipleImages(params);

    result.fold(
      (failure) => emit(UnitImagesError(
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
          add(LoadUnitImagesEvent(unitId: event.unitId, tempKey: event.tempKey));
        });
      },
    );
  }

  Future<void> _onUpdateUnitImage(
    UpdateUnitImageEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    emit(UnitImageUpdating(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final params = UpdateImageParams(
      imageId: event.imageId,
      data: event.data,
    );

    final Either<Failure, bool> result = await updateUnitImage(params);

    result.fold(
      (failure) => emit(UnitImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success && _currentUnitId != null) {
          // إعادة تحميل الصور للحصول على البيانات المحدثة
          add(LoadUnitImagesEvent(unitId: _currentUnitId!));
        } else {
          emit(UnitImageUpdated(
            updatedImages: _currentImages,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteUnitImage(
    DeleteUnitImageEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    emit(UnitImageDeleting(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final Either<Failure, bool> result = await deleteUnitImage(event.imageId);

    result.fold(
      (failure) => emit(UnitImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          _currentImages.removeWhere((image) => image.id == event.imageId);
          _selectedImageIds.remove(event.imageId);
          emit(UnitImageDeleted(
            remainingImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onDeleteMultipleImages(
    DeleteMultipleUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    emit(UnitImagesLoading(message: 'Deleting selected images...'));

    final Either<Failure, bool> result = await deleteMultipleImages(event.imageIds);

    result.fold(
      (failure) => emit(UnitImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          _currentImages.removeWhere((image) => event.imageIds.contains(image.id));
          _selectedImageIds.clear();
          emit(MultipleImagesDeleted(
            remainingImages: List.from(_currentImages),
            deletedCount: event.imageIds.length,
          ));
        }
      },
    );
  }

  Future<void> _onReorderUnitImages(
    ReorderUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    emit(ImagesReordering(currentImages: _currentImages));

    final params = ReorderImagesParams(
      unitId: event.unitId,
      tempKey: event.tempKey,
      imageIds: event.imageIds,
    );

    final Either<Failure, bool> result = await reorderImages(params);

    result.fold(
      (failure) => emit(UnitImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          // إعادة ترتيب الصور محلياً
          final Map<String, UnitImage> imageMap = {
            for (var image in _currentImages) image.id: image
          };
          _currentImages = event.imageIds
              .map((id) => imageMap[id])
              .whereType<UnitImage>()
              .toList();

          emit(ImagesReordered(
            reorderedImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onSetPrimaryUnitImage(
    SetPrimaryUnitImageEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    emit(UnitImagesLoading(message: 'Setting primary image...'));

    final params = SetPrimaryImageParams(
      unitId: event.unitId,
      tempKey: event.tempKey,
      imageId: event.imageId,
    );

    final Either<Failure, bool> result = await setPrimaryImage(params);

    result.fold(
      (failure) => emit(UnitImagesError(
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
          add(LoadUnitImagesEvent(unitId: event.unitId, tempKey: event.tempKey));
        }
      },
    );
  }

  void _onClearUnitImages(
    ClearUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) {
    _currentImages = [];
    _selectedImageIds = {};
    _currentUnitId = null;
    emit(const UnitImagesInitial());
  }

  Future<void> _onRefreshUnitImages(
    RefreshUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) async {
    // لا نظهر loading state عند التحديث
    final Either<Failure, List<UnitImage>> result =
        await getUnitImages(GetUnitImagesParams(unitId: event.unitId, tempKey: event.tempKey));

    result.fold(
      (failure) => emit(UnitImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentUnitId = event.unitId;
        emit(UnitImagesLoaded(
          images: images,
          currentUnitId: event.unitId,
          selectedImageIds: _selectedImageIds,
          isSelectionMode: _selectedImageIds.isNotEmpty,
        ));
      },
    );
  }

  void _onToggleUnitImageSelection(
    ToggleUnitImageSelectionEvent event,
    Emitter<UnitImagesState> emit,
  ) {
    if (_selectedImageIds.contains(event.imageId)) {
      _selectedImageIds.remove(event.imageId);
    } else {
      _selectedImageIds.add(event.imageId);
    }

    emit(UnitImagesLoaded(
      images: _currentImages,
      currentUnitId: _currentUnitId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: _selectedImageIds.isNotEmpty,
    ));
  }

  void _onSelectAllUnitImages(
    SelectAllUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) {
    _selectedImageIds = _currentImages.map((image) => image.id).toSet();

    emit(UnitImagesLoaded(
      images: _currentImages,
      currentUnitId: _currentUnitId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: true,
    ));
  }

  void _onDeselectAllUnitImages(
    DeselectAllUnitImagesEvent event,
    Emitter<UnitImagesState> emit,
  ) {
    _selectedImageIds.clear();

    emit(UnitImagesLoaded(
      images: _currentImages,
      currentUnitId: _currentUnitId,
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
    _currentUnitId = null;
    return super.close();
  }
}
