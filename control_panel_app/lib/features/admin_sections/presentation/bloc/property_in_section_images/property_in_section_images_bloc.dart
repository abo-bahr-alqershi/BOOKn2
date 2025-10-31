// lib/features/admin_sections/presentation/bloc/property_in_section_images/property_in_section_images_bloc.dart

import 'dart:async';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../domain/entities/section_image.dart';
import '../../../domain/usecases/property_in_section_images/usecases.dart';
import 'property_in_section_images_event.dart';
import 'property_in_section_images_state.dart';

class PropertyInSectionImagesBloc
    extends Bloc<PropertyInSectionImagesEvent, PropertyInSectionImagesState> {
  final UploadPropertyInSectionImageUseCase uploadImage;
  final UploadMultiplePropertyInSectionImagesUseCase uploadMultipleImages;
  final GetPropertyInSectionImagesUseCase getImages;
  final UpdatePropertyInSectionImageUseCase updateImage;
  final DeletePropertyInSectionImageUseCase deleteImage;
  final DeleteMultiplePropertyInSectionImagesUseCase deleteMultipleImages;
  final ReorderPropertyInSectionImagesUseCase reorderImages;
  final SetPrimaryPropertyInSectionImageUseCase setPrimaryImage;

  List<SectionImage> _current = [];
  Set<String> _selected = {};
  String? _propertyInSectionId;

  PropertyInSectionImagesBloc({
    required this.uploadImage,
    required this.uploadMultipleImages,
    required this.getImages,
    required this.updateImage,
    required this.deleteImage,
    required this.deleteMultipleImages,
    required this.reorderImages,
    required this.setPrimaryImage,
  }) : super(const PropertyInSectionImagesInitial()) {
    on<LoadPropertyInSectionImagesEvent>(_onLoad);
    on<UploadPropertyInSectionImageEvent>(_onUpload);
    on<UploadMultiplePropertyInSectionImagesEvent>(_onUploadMultiple);
    on<UpdatePropertyInSectionImageEvent>(_onUpdate);
    on<DeletePropertyInSectionImageEvent>(_onDelete);
    on<DeleteMultiplePropertyInSectionImagesEvent>(_onDeleteMultiple);
    on<ReorderPropertyInSectionImagesEvent>(_onReorder);
    on<SetPrimaryPropertyInSectionImageEvent>(_onSetPrimary);
    on<ToggleSelectPropertyInSectionImageEvent>(_onToggleSelect);
    on<SelectAllPropertyInSectionImagesEvent>(_onSelectAll);
    on<ClearPropertyInSectionSelectionEvent>(_onClearSelection);
    on<ClearPropertyInSectionImagesEvent>(_onClearImages);
    on<RefreshPropertyInSectionImagesEvent>(_onRefresh);
  }

  Future<void> _onLoad(LoadPropertyInSectionImagesEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    // منع جلب الصور إذا لم يكن هناك propertyInSectionId أو tempKey
    if ((e.propertyInSectionId == null || e.propertyInSectionId == '') &&
        (e.tempKey == null || e.tempKey == '')) {
      emit(const PropertyInSectionImagesLoaded(images: []));
      return;
    }

    _propertyInSectionId = e.propertyInSectionId;
    emit(const PropertyInSectionImagesLoading());

    final Either<Failure, List<SectionImage>> res = await getImages(
      GetPropertyInSectionImagesParams(
        propertyInSectionId: e.propertyInSectionId,
        tempKey: e.tempKey,
      ),
    );

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (list) {
        _current = list;
        emit(PropertyInSectionImagesLoaded(
          images: list,
          propertyInSectionId: e.propertyInSectionId,
        ));
      },
    );
  }

  Future<void> _onUpload(UploadPropertyInSectionImageEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    // require propertyInSectionId or tempKey
    if ((e.propertyInSectionId == null || e.propertyInSectionId == '') &&
        (e.tempKey == null || e.tempKey == '')) {
      emit(PropertyInSectionImagesError(
        'لا يمكن رفع الصور بدون معرف العقار في القسم أو tempKey',
        previousImages: _current,
      ));
      return;
    }

    emit(PropertyInSectionImageUploading(
      current: _current,
      fileName: e.filePath.split('/').last,
    ));

    final res = await uploadImage(UploadPropertyInSectionImageParams(
      propertyInSectionId: e.propertyInSectionId,
      tempKey: e.tempKey,
      filePath: e.filePath,
      category: e.category,
      alt: e.alt,
      isPrimary: e.isPrimary,
      order: e.order,
      tags: e.tags,
      onSendProgress: (sent, total) {
        if (total > 0) {
          emit(PropertyInSectionImageUploading(
            current: _current,
            fileName: e.filePath.split('/').last,
            progress: sent / total,
          ));
        }
      },
    ));

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (img) {
        _current.add(img);
        emit(PropertyInSectionImageUploaded(
          uploaded: img,
          all: List.from(_current),
        ));
      },
    );
  }

  Future<void> _onUploadMultiple(UploadMultiplePropertyInSectionImagesEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    emit(PropertyInSectionImageUploading(
      current: _current,
      total: e.filePaths.length,
      index: 0,
    ));

    final res =
        await uploadMultipleImages(UploadMultiplePropertyInSectionImagesParams(
      propertyInSectionId: e.propertyInSectionId,
      tempKey: e.tempKey,
      filePaths: e.filePaths,
      category: e.category,
      tags: e.tags,
      onProgress: (path, sent, total) {
        if (total > 0) {
          emit(PropertyInSectionImageUploading(
            current: _current,
            fileName: path.split('/').last,
            progress: sent / total,
            total: e.filePaths.length,
          ));
        }
      },
    ));

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (list) {
        _current.addAll(list);
        emit(MultiplePropertyInSectionImagesUploaded(
          uploadedImages: list,
          allImages: List.from(_current),
          successCount: list.length,
          failedCount: e.filePaths.length - list.length,
        ));
        // بعد ثانية واحدة، عرض قائمة الصور المحدثة
        Future.delayed(const Duration(seconds: 1), () {
          add(LoadPropertyInSectionImagesEvent(
            propertyInSectionId: e.propertyInSectionId,
            tempKey: e.tempKey,
          ));
        });
      },
    );
  }

  Future<void> _onUpdate(UpdatePropertyInSectionImageEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    emit(PropertyInSectionImageUpdating(
      current: _current,
      imageId: e.imageId,
    ));

    final res = await updateImage(UpdatePropertyInSectionImageParams(
      imageId: e.imageId,
      data: e.data,
    ));

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (_) {
        if (_propertyInSectionId != null) {
          add(LoadPropertyInSectionImagesEvent(
              propertyInSectionId: _propertyInSectionId!));
        }
      },
    );
  }

  Future<void> _onDelete(DeletePropertyInSectionImageEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    emit(PropertyInSectionImageDeleting(
      current: _current,
      imageId: e.imageId,
    ));

    final res = await deleteImage(e.imageId);

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (ok) {
        if (ok) {
          _current.removeWhere((x) => x.id == e.imageId);
          emit(PropertyInSectionImageDeleted(remaining: List.from(_current)));
        }
      },
    );
  }

  Future<void> _onDeleteMultiple(DeleteMultiplePropertyInSectionImagesEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    emit(const PropertyInSectionImagesLoading());

    final res = await deleteMultipleImages(e.imageIds);

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (ok) {
        if (ok) {
          _current.removeWhere((x) => e.imageIds.contains(x.id));
          _selected.clear();
          emit(MultiplePropertyInSectionImagesDeleted(
              remaining: List.from(_current)));
        }
      },
    );
  }

  Future<void> _onReorder(ReorderPropertyInSectionImagesEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    emit(PropertyInSectionImagesReordering(current: _current));

    final res = await reorderImages(ReorderPropertyInSectionImagesParams(
      propertyInSectionId: e.propertyInSectionId,
      tempKey: e.tempKey,
      imageIds: e.imageIds,
    ));

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (ok) {
        if (ok) {
          final map = {for (final i in _current) i.id: i};
          _current = e.imageIds
              .map((id) => map[id])
              .whereType<SectionImage>()
              .toList();
          emit(
              PropertyInSectionImagesReordered(reordered: List.from(_current)));
        }
      },
    );
  }

  Future<void> _onSetPrimary(SetPrimaryPropertyInSectionImageEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    emit(const PropertyInSectionImagesLoading());

    final res = await setPrimaryImage(SetPrimaryPropertyInSectionImageParams(
      propertyInSectionId: e.propertyInSectionId,
      tempKey: e.tempKey,
      imageId: e.imageId,
    ));

    res.fold(
      (f) => emit(PropertyInSectionImagesError(_msg(f))),
      (_) {
        add(LoadPropertyInSectionImagesEvent(
          propertyInSectionId: e.propertyInSectionId,
          tempKey: e.tempKey,
        ));
      },
    );
  }

  void _onToggleSelect(ToggleSelectPropertyInSectionImageEvent e,
      Emitter<PropertyInSectionImagesState> emit) {
    if (_selected.contains(e.imageId)) {
      _selected.remove(e.imageId);
    } else {
      _selected.add(e.imageId);
    }

    emit(PropertyInSectionImagesLoaded(
      images: _current,
      propertyInSectionId: _propertyInSectionId,
      selected: Set.from(_selected),
      isSelectionMode: _selected.isNotEmpty,
    ));
  }

  void _onSelectAll(SelectAllPropertyInSectionImagesEvent e,
      Emitter<PropertyInSectionImagesState> emit) {
    _selected = _current.map((x) => x.id).toSet();

    emit(PropertyInSectionImagesLoaded(
      images: _current,
      propertyInSectionId: _propertyInSectionId,
      selected: Set.from(_selected),
      isSelectionMode: true,
    ));
  }

  void _onClearSelection(ClearPropertyInSectionSelectionEvent e,
      Emitter<PropertyInSectionImagesState> emit) {
    _selected.clear();

    emit(PropertyInSectionImagesLoaded(
      images: _current,
      propertyInSectionId: _propertyInSectionId,
      selected: Set.from(_selected),
      isSelectionMode: false,
    ));
  }

  void _onClearImages(ClearPropertyInSectionImagesEvent e,
      Emitter<PropertyInSectionImagesState> emit) {
    _current = [];
    _selected = {};
    _propertyInSectionId = null;
    emit(const PropertyInSectionImagesInitial());
  }

  Future<void> _onRefresh(RefreshPropertyInSectionImagesEvent e,
      Emitter<PropertyInSectionImagesState> emit) async {
    final Either<Failure, List<SectionImage>> res = await getImages(
      GetPropertyInSectionImagesParams(
        propertyInSectionId: e.propertyInSectionId,
        tempKey: e.tempKey,
      ),
    );

    res.fold(
      (f) =>
          emit(PropertyInSectionImagesError(_msg(f), previousImages: _current)),
      (list) {
        _current = list;
        _propertyInSectionId = e.propertyInSectionId;
        emit(PropertyInSectionImagesLoaded(
          images: list,
          propertyInSectionId: e.propertyInSectionId,
          selected: _selected,
          isSelectionMode: _selected.isNotEmpty,
        ));
      },
    );
  }

  String _msg(Failure f) {
    if (f is ServerFailure) return f.message ?? 'Server Error';
    if (f is NetworkFailure) return 'Network error';
    return 'Unexpected error';
  }
}

class _ProgressEvent extends PropertyInSectionImagesEvent {
  final String propertyInSectionId;
  final double progress;
  const _ProgressEvent(this.propertyInSectionId, this.progress);
}
