import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/section_target.dart';
import '../../domain/entities/property_in_section.dart';
import '../../domain/entities/unit_in_section.dart';
import 'property_item_card.dart';
import 'unit_item_card.dart';
import 'item_order_drag_handle.dart';

class SectionItemsList extends StatefulWidget {
  final List<dynamic> items;
  final SectionTarget target;
  final bool isReordering;
  final Function(int, int)? onReorder;
  final Function(String)? onRemove;

  const SectionItemsList({
    super.key,
    required this.items,
    required this.target,
    this.isReordering = false,
    this.onReorder,
    this.onRemove,
  });

  @override
  State<SectionItemsList> createState() => _SectionItemsListState();
}

class _SectionItemsListState extends State<SectionItemsList> {
  late List<dynamic> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(SectionItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _items = List.from(widget.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReordering) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        onReorder: _handleReorder,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            key: ValueKey(item.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ItemOrderDragHandle(
                  index: index,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildItemCard(item),
                ),
              ],
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildItemCard(item),
        );
      },
    );
  }

  Widget _buildItemCard(dynamic item) {
    if (widget.target == SectionTarget.properties &&
        item is PropertyInSection) {
      return PropertyItemCard(
        property: item,
        onRemove: widget.onRemove != null
            ? () => widget.onRemove!(item.id)
            : null,
        isReordering: widget.isReordering,
      );
    } else if (widget.target == SectionTarget.units && item is UnitInSection) {
      return UnitItemCard(
        unit: item,
        // Backend returns UnitInSectionId separately; our model maps id from JSON['id'].
        // If ever needed, adjust here by preferring a UnitInSectionId field on the model.
        onRemove: widget.onRemove != null
            ? () => widget.onRemove!(item.id)
            : null,
        isReordering: widget.isReordering,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'عنصر غير معروف',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    widget.onReorder?.call(oldIndex, newIndex);
  }
}
