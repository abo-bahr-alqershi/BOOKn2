// lib/features/home/presentation/widgets/sections/city_cards_grid/city_cards_grid_section_widget.dart

import 'package:flutter/material.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/city_cards_grid/ClassC/city_cards_grid_widget_class_c.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/section_loading_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/section_empty_widget.dart';
import 'package:yemen_booking_app/core/models/paginated_result.dart' as core;
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/injection_container.dart';
import 'package:yemen_booking_app/features/home/domain/repositories/home_repository.dart';

class CityCardsGridSectionWidgetClassC extends StatefulWidget {
  final String sectionId;
  final core.PaginatedResult<SectionPropertyItemModel>? data;
  final Function(String)? onItemTap;

  const CityCardsGridSectionWidgetClassC({
    super.key,
    required this.sectionId,
    this.data,
    this.onItemTap,
  });

  @override
  State<CityCardsGridSectionWidgetClassC> createState() =>
      _CityCardsGridSectionWidgetClassCState();
}

class _CityCardsGridSectionWidgetClassCState
    extends State<CityCardsGridSectionWidgetClassC> {
  List<SectionPropertyItemModel> _items = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _items = widget.data?.items ?? const [];
    if (_items.isEmpty) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = sl<HomeRepository>();
    final result =
        await repo.getSectionPropertyItems(sectionId: widget.sectionId);
    result.fold((_) {}, (data) => _items = data.items);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const SectionLoadingWidget();
    if (_items.isEmpty) {
      return const SectionEmptyWidget(
        message: 'لا توجد وجهات متاحة حالياً',
        icon: Icons.location_city_rounded,
      );
    }
    return CityCardsGridWidgetClassC(
      cities: _items,
      onItemTap: widget.onItemTap,
    );
  }
}
