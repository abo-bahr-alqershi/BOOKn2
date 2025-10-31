// lib/core/models/section_item_dto.dart

/// DTOs used with Sections endpoints for item management

class AssignSectionItemsDto {
  final List<String> propertyIds;
  final List<String> unitIds;

  const AssignSectionItemsDto({
    this.propertyIds = const [],
    this.unitIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (propertyIds.isNotEmpty) 'propertyIds': propertyIds,
      if (unitIds.isNotEmpty) 'unitIds': unitIds,
    };
  }
}

class AddItemsToSectionDto {
  final List<String> propertyIds;
  final List<String> unitIds;

  const AddItemsToSectionDto({
    this.propertyIds = const [],
    this.unitIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (propertyIds.isNotEmpty) 'propertyIds': propertyIds,
      if (unitIds.isNotEmpty) 'unitIds': unitIds,
    };
  }
}

class RemoveItemsFromSectionDto {
  final List<String> itemIds;

  const RemoveItemsFromSectionDto({this.itemIds = const []});

  Map<String, dynamic> toJson() {
    return {
      'itemIds': itemIds,
    };
  }
}

class UpdateItemOrderDto {
  final List<ItemOrderDto> orders;

  const UpdateItemOrderDto({this.orders = const []});

  Map<String, dynamic> toJson() => {
        'orders': orders.map((e) => e.toJson()).toList(),
      };
}

class ItemOrderDto {
  final String itemId;
  final int sortOrder;

  const ItemOrderDto({required this.itemId, required this.sortOrder});

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'sortOrder': sortOrder,
      };
}

