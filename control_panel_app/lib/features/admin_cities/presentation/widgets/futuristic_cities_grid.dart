// lib/features/admin_cities/presentation/widgets/futuristic_cities_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../domain/entities/city.dart';
import 'futuristic_city_card.dart';

class FuturisticCitiesGrid extends StatelessWidget {
  final List<City> cities;
  final bool isGridView;
  final Function(City) onCityTap;
  final Function(City) onCityEdit;
  final Function(City) onCityDelete;

  const FuturisticCitiesGrid({
    super.key,
    required this.cities,
    required this.isGridView,
    required this.onCityTap,
    required this.onCityEdit,
    required this.onCityDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: _getAspectRatio(context),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final city = cities[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: _getCrossAxisCount(context),
              child: ScaleAnimation(
                scale: 0.95,
                child: FadeInAnimation(
                  child: FuturisticCityCard(
                    city: city,
                    onTap: () => onCityTap(city),
                    onEdit: () => onCityEdit(city),
                    onDelete: () => onCityDelete(city),
                  ),
                ),
              ),
            );
          },
          childCount: cities.length,
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final city = cities[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FuturisticCityCard(
                      city: city,
                      isCompact: true,
                      onTap: () => onCityTap(city),
                      onEdit: () => onCityEdit(city),
                      onDelete: () => onCityDelete(city),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: cities.length,
        ),
      );
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1.5;
    if (width < 600) return 1.2;
    return 1.0;
  }
}
