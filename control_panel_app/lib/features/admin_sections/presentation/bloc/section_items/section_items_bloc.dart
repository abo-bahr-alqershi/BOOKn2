import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/models/section_item_dto.dart';
import '../../../../../core/enums/section_target.dart';
import '../../../domain/usecases/section_items/get_section_items_usecase.dart';
import '../../../domain/usecases/section_items/add_items_to_section_usecase.dart';
import '../../../domain/usecases/section_items/remove_items_from_section_usecase.dart';
import '../../../domain/usecases/section_items/update_item_order_usecase.dart';
import 'section_items_event.dart';
import 'section_items_state.dart';

class SectionItemsBloc extends Bloc<SectionItemsEvent, SectionItemsState> {
  final GetSectionItemsUseCase getItems;
  final AddItemsToSectionUseCase addItems;
  final RemoveItemsFromSectionUseCase removeItems;
  final UpdateItemOrderUseCase reorderItems;

  SectionItemsBloc({
    required this.getItems,
    required this.addItems,
    required this.removeItems,
    required this.reorderItems,
  }) : super(SectionItemsInitial()) {
    on<LoadSectionItemsEvent>(_onLoad);
    on<AddItemsToSectionEvent>(_onAdd);
    on<RemoveItemsFromSectionEvent>(_onRemove);
    on<ReorderSectionItemsEvent>(_onReorder);
  }

  Future<void> _onLoad(
    LoadSectionItemsEvent event,
    Emitter<SectionItemsState> emit,
  ) async {
    emit(SectionItemsLoading());
    final res = await getItems(GetSectionItemsParams(
      sectionId: event.sectionId,
      target: event.target,
      pageNumber: event.pageNumber,
      pageSize: event.pageSize,
    ));
    res.fold(
      (failure) => emit(SectionItemsError(failure.message)),
      (page) => emit(SectionItemsLoaded(page)),
    );
  }

  Future<void> _onAdd(
    AddItemsToSectionEvent event,
    Emitter<SectionItemsState> emit,
  ) async {
    final payload = AddItemsToSectionDto(
      propertyIds: event.propertyIds,
      unitIds: event.unitIds,
    );
    final res = await addItems(AddItemsToSectionParams(
      sectionId: event.sectionId,
      payload: payload,
    ));
    res.fold(
      (failure) => emit(SectionItemsError(failure.message)),
      (_) => emit(SectionItemsOperationSuccess()),
    );
  }

  Future<void> _onRemove(
    RemoveItemsFromSectionEvent event,
    Emitter<SectionItemsState> emit,
  ) async {
    final payload = RemoveItemsFromSectionDto(itemIds: event.itemIds);
    final res = await removeItems(RemoveItemsFromSectionParams(
      sectionId: event.sectionId,
      payload: payload,
    ));
    res.fold(
      (failure) => emit(SectionItemsError(failure.message)),
      (_) => emit(SectionItemsOperationSuccess()),
    );
  }

  Future<void> _onReorder(
    ReorderSectionItemsEvent event,
    Emitter<SectionItemsState> emit,
  ) async {
    final payload = UpdateItemOrderDto(orders: event.orders);
    final res = await reorderItems(UpdateItemOrderParams(
      sectionId: event.sectionId,
      payload: payload,
    ));
    res.fold(
      (failure) => emit(SectionItemsError(failure.message)),
      (_) => emit(SectionItemsOperationSuccess()),
    );
  }
}

