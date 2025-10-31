import 'package:equatable/equatable.dart';
import '../../../../../core/enums/section_target.dart';
import '../../../../../core/models/section_item_dto.dart';

abstract class SectionItemsEvent extends Equatable {
  const SectionItemsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSectionItemsEvent extends SectionItemsEvent {
  final String sectionId;
  final SectionTarget target;
  final int pageNumber;
  final int pageSize;
  const LoadSectionItemsEvent({
    required this.sectionId,
    required this.target,
    this.pageNumber = 1,
    this.pageSize = 10,
  });
}

class AddItemsToSectionEvent extends SectionItemsEvent {
  final String sectionId;
  final List<String> propertyIds;
  final List<String> unitIds;
  const AddItemsToSectionEvent({
    required this.sectionId,
    this.propertyIds = const [],
    this.unitIds = const [],
  });
}

class RemoveItemsFromSectionEvent extends SectionItemsEvent {
  final String sectionId;
  final List<String> itemIds;
  const RemoveItemsFromSectionEvent({required this.sectionId, required this.itemIds});
}

class ReorderSectionItemsEvent extends SectionItemsEvent {
  final String sectionId;
  final List<ItemOrderDto> orders;
  const ReorderSectionItemsEvent({required this.sectionId, required this.orders});
}

