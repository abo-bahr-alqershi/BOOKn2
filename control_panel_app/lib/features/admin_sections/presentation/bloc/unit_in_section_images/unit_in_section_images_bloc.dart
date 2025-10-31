// lib/features/admin_sections/presentation/bloc/unit_in_section_images/unit_in_section_images_bloc.dart

import 'dart:async';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../domain/entities/section_image.dart';
import '../../../domain/usecases/unit_in_section_images/usecases.dart';
import 'unit_in_section_images_event.dart';
import 'unit_in_section_images_state.dart';

class UnitInSectionImagesBloc
    extends Bloc<UnitInSectionImagesEvent, UnitInSectionImagesState> {
  final UploadUnitInSectionImageUseCase uploadImage;
  final UploadMultipleUnitInSectionImagesUseCase uploadMultipleImages;
  final GetUnitInSectionImagesUseCase getImages;
  final UpdateUnitInSectionImageUseCase updateImage;
  final DeleteUnitInSectionImageUseCase deleteImage;
  final DeleteMultipleUnitInSectionImagesUseCase deleteMultipleImages;
  final ReorderUnitInSectionImagesUseCase reorderImages;
  final SetPrimaryUnitInSectionImageUseCase setPrimaryImage;

  List<SectionImage> _current = [];
  Set<String> _selected = {};
  String? _unitInSectionId;

  UnitInSectionImagesBloc({
    required this.uploadImage,
    required this.uploadMultipleImages,
    required this.getImages,
    required this.updateImage,
    required this.deleteImage,
    required this.deleteMultipleImages,
    required this.reorderImages,
    required this.setPrimaryImage,
  }) : super(const UnitInSectionImagesInitial()) {
    on<LoadUnitInSectionImagesEvent>(_onLoad);
    on<UploadUnitInSectionImageEvent>(_onUpload);
    on<UploadMultipleUnitInSectionImagesEvent>(_onUploadMultiple);
    on<UpdateUnitInSectionImageEvent>(_onUpdate);
    on<DeleteUnitInSectionImageEvent>(_onDelete);
    on<DeleteMultipleUnitInSectionImagesEvent>(_onDeleteMultiple);
    on<ReorderUnitInSectionImagesEvent>(_onReorder);
    on<SetPrimaryUnitInSectionImageEvent>(_onSetPrimary);
    on<ToggleSelectUnitInSectionImageEvent>(_onToggleSelect);
    on<SelectAllUnitInSectionImagesEvent>(_onSelectAll);
    on<ClearUnitInSectionSelectionEvent>(_onClearSelection);
  }

  Future<void> _onLoad(LoadUnitInSectionImagesEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    _unitInSectionId = e.unitInSectionId;
    emit(const UnitInSectionImagesLoading());

    final Either<Failure, List<SectionImage>> res = await getImages(
      GetUnitInSectionImagesParams(
        unitInSectionId: e.unitInSectionId,
        tempKey: e.tempKey,
      ),
    );

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (list) {
        _current = list;
        emit(UnitInSectionImagesLoaded(
          images: list,
          unitInSectionId: e.unitInSectionId,
        ));
      },
    );
  }

  Future<void> _onUpload(UploadUnitInSectionImageEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    emit(UnitInSectionImageUploading(
      current: _current,
      fileName: e.filePath.split('/').last,
    ));

    final res = await uploadImage(UploadUnitInSectionImageParams(
      unitInSectionId: e.unitInSectionId,
      tempKey: e.tempKey,
      filePath: e.filePath,
      category: e.category,
      alt: e.alt,
      isPrimary: e.isPrimary,
      order: e.order,
      tags: e.tags,
      onSendProgress: (sent, total) {
        if (total > 0) {
          add(_ProgressEvent(e.unitInSectionId ?? '', sent / total));
        }
      },
    ));

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (img) {
        _current.add(img);
        emit(UnitInSectionImageUploaded(
          uploaded: img,
          all: List.from(_current),
        ));
      },
    );
  }

  Future<void> _onUploadMultiple(UploadMultipleUnitInSectionImagesEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    emit(UnitInSectionImageUploading(
      current: _current,
      total: e.filePaths.length,
      index: 0,
    ));

    final res =
        await uploadMultipleImages(UploadMultipleUnitInSectionImagesParams(
      unitInSectionId: e.unitInSectionId,
      tempKey: e.tempKey,
      filePaths: e.filePaths,
      category: e.category,
      tags: e.tags,
      onProgress: (path, sent, total) {
        if (total > 0) {
          add(_ProgressEvent(e.unitInSectionId ?? '', sent / total));
        }
      },
    ));

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (list) {
        _current.addAll(list);
        emit(MultipleUnitInSectionImagesUploaded(
          uploadedImages: list,
          allImages: List.from(_current),
          successCount: list.length,
          failedCount: e.filePaths.length - list.length,
        ));
      },
    );
  }

  Future<void> _onUpdate(UpdateUnitInSectionImageEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    emit(UnitInSectionImageUpdating(current: _current, imageId: e.imageId));

    final res = await updateImage(UpdateUnitInSectionImageParams(
      imageId: e.imageId,
      data: e.data,
    ));

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (_) {
        if (_unitInSectionId != null) {
          add(LoadUnitInSectionImagesEvent(unitInSectionId: _unitInSectionId!));
        }
      },
    );
  }

  Future<void> _onDelete(DeleteUnitInSectionImageEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    emit(UnitInSectionImageDeleting(current: _current, imageId: e.imageId));

    final res = await deleteImage(e.imageId);

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (ok) {
        if (ok) {
          _current.removeWhere((x) => x.id == e.imageId);
          emit(UnitInSectionImageDeleted(remaining: List.from(_current)));
        }
      },
    );
  }

  Future<void> _onDeleteMultiple(DeleteMultipleUnitInSectionImagesEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    emit(const UnitInSectionImagesLoading());

    final res = await deleteMultipleImages(e.imageIds);

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (ok) {
        if (ok) {
          _current.removeWhere((x) => e.imageIds.contains(x.id));
          _selected.clear();
          emit(MultipleUnitInSectionImagesDeleted(
              remaining: List.from(_current)));
        }
      },
    );
  }

  Future<void> _onReorder(ReorderUnitInSectionImagesEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    emit(UnitInSectionImagesReordering(current: _current));

    final res = await reorderImages(ReorderUnitInSectionImagesParams(
      unitInSectionId: e.unitInSectionId,
      tempKey: e.tempKey,
      imageIds: e.imageIds,
    ));

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (ok) {
        if (ok) {
          final map = {for (final i in _current) i.id: i};
          _current = e.imageIds
              .map((id) => map[id])
              .whereType<SectionImage>()
              .toList();
          emit(UnitInSectionImagesReordered(reordered: List.from(_current)));
        }
      },
    );
  }

  Future<void> _onSetPrimary(SetPrimaryUnitInSectionImageEvent e,
      Emitter<UnitInSectionImagesState> emit) async {
    emit(const UnitInSectionImagesLoading());

    final res = await setPrimaryImage(SetPrimaryUnitInSectionImageParams(
      unitInSectionId: e.unitInSectionId,
      tempKey: e.tempKey,
      imageId: e.imageId,
    ));

    res.fold(
      (f) => emit(UnitInSectionImagesError(_msg(f))),
      (_) {
        if (_unitInSectionId != null) {
          add(LoadUnitInSectionImagesEvent(unitInSectionId: _unitInSectionId!));
        }
      },
    );
  }

  void _onToggleSelect(ToggleSelectUnitInSectionImageEvent e,
      Emitter<UnitInSectionImagesState> emit) {
    if (_selected.contains(e.imageId)) {
      _selected.remove(e.imageId);
    } else {
      _selected.add(e.imageId);
    }

    emit(UnitInSectionImagesLoaded(
      images: _current,
      unitInSectionId: _unitInSectionId,
      selected: Set.from(_selected),
      isSelectionMode: _selected.isNotEmpty,
    ));
  }

  void _onSelectAll(SelectAllUnitInSectionImagesEvent e,
      Emitter<UnitInSectionImagesState> emit) {
    _selected = _current.map((x) => x.id).toSet();

    emit(UnitInSectionImagesLoaded(
      images: _current,
      unitInSectionId: _unitInSectionId,
      selected: Set.from(_selected),
      isSelectionMode: true,
    ));
  }

  void _onClearSelection(ClearUnitInSectionSelectionEvent e,
      Emitter<UnitInSectionImagesState> emit) {
    _selected.clear();

    emit(UnitInSectionImagesLoaded(
      images: _current,
      unitInSectionId: _unitInSectionId,
      selected: Set.from(_selected),
      isSelectionMode: false,
    ));
  }

  void _onProgress(_ProgressEvent e, Emitter<UnitInSectionImagesState> emit) {
    emit(UnitInSectionImageUploading(
      current: _current,
      progress: e.progress,
    ));
  }

  String _msg(Failure f) {
    if (f is ServerFailure) return f.message ?? 'Server Error';
    if (f is NetworkFailure) return 'Network error';
    return 'Unexpected error';
  }
}

class _ProgressEvent extends UnitInSectionImagesEvent {
  final String unitInSectionId;
  final double progress;
  const _ProgressEvent(this.unitInSectionId, this.progress);
}
