// lib/features/admin_sections/presentation/bloc/section_images/section_images_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import '../../../domain/entities/section_image.dart';
import '../../../domain/usecases/section_images/usecases.dart';
import 'section_images_event.dart';
import 'section_images_state.dart';

class SectionImagesBloc extends Bloc<SectionImagesEvent, SectionImagesState> {
  final UploadSectionImageUseCase uploadSectionImage;
  final UploadMultipleSectionImagesUseCase uploadMultipleImages;
  final GetSectionImagesUseCase getSectionImages;
  final UpdateSectionImageUseCase updateSectionImage;
  final DeleteSectionImageUseCase deleteSectionImage;
  final DeleteMultipleSectionImagesUseCase deleteMultipleImages;
  final ReorderSectionImagesUseCase reorderImages;
  final SetPrimarySectionImageUseCase setPrimaryImage;

  List<SectionImage> _currentImages = [];
  Set<String> _selectedImageIds = {};
  String? _currentSectionId;

  SectionImagesBloc({
    required this.uploadSectionImage,
    required this.uploadMultipleImages,
    required this.getSectionImages,
    required this.updateSectionImage,
    required this.deleteSectionImage,
    required this.deleteMultipleImages,
    required this.reorderImages,
    required this.setPrimaryImage,
  }) : super(const SectionImagesInitial()) {
    on<LoadSectionImagesEvent>(_onLoadSectionImages);
    on<UploadSectionImageEvent>(_onUploadSectionImage);
    on<UploadMultipleSectionImagesEvent>(_onUploadMultipleImages);
    on<UpdateSectionImageEvent>(_onUpdateSectionImage);
    on<DeleteSectionImageEvent>(_onDeleteSectionImage);
    on<DeleteMultipleSectionImagesEvent>(_onDeleteMultipleImages);
    on<ReorderSectionImagesEvent>(_onReorderImages);
    on<SetPrimarySectionImageEvent>(_onSetPrimaryImage);
    on<ClearSectionImagesEvent>(_onClearSectionImages);
    on<RefreshSectionImagesEvent>(_onRefreshSectionImages);
    on<ToggleSelectSectionImageEvent>(_onToggleImageSelection);
    on<SelectAllSectionImagesEvent>(_onSelectAllImages);
    on<DeselectAllSectionImagesEvent>(_onDeselectAllImages);
  }

  Future<void> _onLoadSectionImages(
    LoadSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    // منع جلب الصور إذا لم يكن هناك sectionId أو tempKey
    if ((event.sectionId == null || event.sectionId!.isEmpty) &&
        (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(const SectionImagesLoaded(images: []));
      return;
    }

    emit(const SectionImagesLoading(message: 'Loading images...'));

    final Either<Failure, List<SectionImage>> result = await getSectionImages(
      GetSectionImagesParams(
        sectionId: event.sectionId,
        tempKey: event.tempKey,
      ),
    );

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentSectionId = event.sectionId;
        emit(SectionImagesLoaded(
          images: images,
          currentSectionId: event.sectionId,
        ));
      },
    );
  }

  Future<void> _onUploadSectionImage(
    UploadSectionImageEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    // require sectionId or tempKey
    if ((event.sectionId == null || event.sectionId!.isEmpty) &&
        (event.tempKey == null || event.tempKey!.isEmpty)) {
      emit(SectionImagesError(
        message: 'لا يمكن رفع الصور بدون معرف القسم أو tempKey',
        previousImages: _currentImages,
      ));
      return;
    }

    emit(SectionImageUploading(
      currentImages: _currentImages,
      uploadingFileName: event.filePath.split('/').last,
    ));

    final params = UploadSectionImageParams(
      sectionId: event.sectionId,
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
          emit(SectionImageUploading(
            currentImages: _currentImages,
            uploadingFileName: event.filePath.split('/').last,
            uploadProgress: progress,
          ));
        }
      },
    );

    final Either<Failure, SectionImage> result =
        await uploadSectionImage(params);

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (image) {
        _currentImages.add(image);
        emit(SectionImageUploaded(
          uploadedImage: image,
          allImages: List.from(_currentImages),
        ));
      },
    );
  }

  Future<void> _onUploadMultipleImages(
    UploadMultipleSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    emit(SectionImageUploading(
      currentImages: _currentImages,
      totalFiles: event.filePaths.length,
      currentFileIndex: 0,
    ));

    final params = UploadMultipleSectionImagesParams(
      sectionId: event.sectionId,
      tempKey: event.tempKey,
      filePaths: event.filePaths,
      category: event.category,
      tags: event.tags,
      onProgress: (filePath, sent, total) {
        if (total > 0) {
          final progress = sent / total;
          emit(SectionImageUploading(
            currentImages: _currentImages,
            uploadingFileName: filePath.split('/').last,
            uploadProgress: progress,
            totalFiles: event.filePaths.length,
          ));
        }
      },
    );

    final Either<Failure, List<SectionImage>> result =
        await uploadMultipleImages(params);

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages.addAll(images);
        emit(MultipleSectionImagesUploaded(
          uploadedImages: images,
          allImages: List.from(_currentImages),
          successCount: images.length,
          failedCount: event.filePaths.length - images.length,
        ));
        // بعد ثانية واحدة، عرض قائمة الصور المحدثة
        Future.delayed(const Duration(seconds: 1), () {
          add(LoadSectionImagesEvent(
            sectionId: event.sectionId,
            tempKey: event.tempKey,
          ));
        });
      },
    );
  }

  Future<void> _onUpdateSectionImage(
    UpdateSectionImageEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    emit(SectionImageUpdating(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final params = UpdateSectionImageParams(
      imageId: event.imageId,
      data: event.data,
    );

    final Either<Failure, bool> result = await updateSectionImage(params);

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success && _currentSectionId != null) {
          // إعادة تحميل الصور للحصول على البيانات المحدثة
          add(LoadSectionImagesEvent(sectionId: _currentSectionId!));
        } else {
          emit(SectionImageUpdated(
            updatedImages: _currentImages,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteSectionImage(
    DeleteSectionImageEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    emit(SectionImageDeleting(
      currentImages: _currentImages,
      imageId: event.imageId,
    ));

    final Either<Failure, bool> result =
        await deleteSectionImage(event.imageId);

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          _currentImages.removeWhere((image) => image.id == event.imageId);
          _selectedImageIds.remove(event.imageId);
          emit(SectionImageDeleted(
            remainingImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onDeleteMultipleImages(
    DeleteMultipleSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    emit(const SectionImagesLoading(message: 'Deleting selected images...'));

    final Either<Failure, bool> result =
        await deleteMultipleImages(event.imageIds);

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          _currentImages
              .removeWhere((image) => event.imageIds.contains(image.id));
          _selectedImageIds.clear();
          emit(MultipleSectionImagesDeleted(
            remainingImages: List.from(_currentImages),
            deletedCount: event.imageIds.length,
          ));
        }
      },
    );
  }

  Future<void> _onReorderImages(
    ReorderSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    emit(SectionImagesReordering(currentImages: _currentImages));

    final params = ReorderSectionImagesParams(
      sectionId: event.sectionId,
      tempKey: event.tempKey,
      imageIds: event.imageIds,
    );

    final Either<Failure, bool> result = await reorderImages(params);

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          // إعادة ترتيب الصور محلياً
          final Map<String, SectionImage> imageMap = {
            for (var image in _currentImages) image.id: image
          };
          _currentImages = event.imageIds
              .map((id) => imageMap[id])
              .whereType<SectionImage>()
              .toList();

          emit(SectionImagesReordered(
            reorderedImages: List.from(_currentImages),
          ));
        }
      },
    );
  }

  Future<void> _onSetPrimaryImage(
    SetPrimarySectionImageEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    emit(const SectionImagesLoading(message: 'Setting primary image...'));

    final params = SetPrimarySectionImageParams(
      sectionId: event.sectionId,
      tempKey: event.tempKey,
      imageId: event.imageId,
    );

    final Either<Failure, bool> result = await setPrimaryImage(params);

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (success) {
        if (success) {
          // إعادة تحميل الصور للحصول على البيانات المحدثة
          add(LoadSectionImagesEvent(
            sectionId: event.sectionId,
            tempKey: event.tempKey,
          ));
        }
      },
    );
  }

  void _onClearSectionImages(
    ClearSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) {
    _currentImages = [];
    _selectedImageIds = {};
    _currentSectionId = null;
    emit(const SectionImagesInitial());
  }

  Future<void> _onRefreshSectionImages(
    RefreshSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) async {
    final Either<Failure, List<SectionImage>> result = await getSectionImages(
      GetSectionImagesParams(
        sectionId: event.sectionId,
        tempKey: event.tempKey,
      ),
    );

    result.fold(
      (failure) => emit(SectionImagesError(
        message: _mapFailureToMessage(failure),
        previousImages: _currentImages,
      )),
      (images) {
        _currentImages = images;
        _currentSectionId = event.sectionId;
        emit(SectionImagesLoaded(
          images: images,
          currentSectionId: event.sectionId,
          selectedImageIds: _selectedImageIds,
          isSelectionMode: _selectedImageIds.isNotEmpty,
        ));
      },
    );
  }

  void _onToggleImageSelection(
    ToggleSelectSectionImageEvent event,
    Emitter<SectionImagesState> emit,
  ) {
    if (_selectedImageIds.contains(event.imageId)) {
      _selectedImageIds.remove(event.imageId);
    } else {
      _selectedImageIds.add(event.imageId);
    }

    emit(SectionImagesLoaded(
      images: _currentImages,
      currentSectionId: _currentSectionId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: _selectedImageIds.isNotEmpty,
    ));
  }

  void _onSelectAllImages(
    SelectAllSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) {
    _selectedImageIds = _currentImages.map((image) => image.id).toSet();

    emit(SectionImagesLoaded(
      images: _currentImages,
      currentSectionId: _currentSectionId,
      selectedImageIds: Set.from(_selectedImageIds),
      isSelectionMode: true,
    ));
  }

  void _onDeselectAllImages(
    DeselectAllSectionImagesEvent event,
    Emitter<SectionImagesState> emit,
  ) {
    _selectedImageIds.clear();

    emit(SectionImagesLoaded(
      images: _currentImages,
      currentSectionId: _currentSectionId,
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
    _currentSectionId = null;
    return super.close();
  }
}
