// lib/features/home/presentation/widgets/sections/neuro_morphic_grid/neuro_premium_property_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';

class NeuroMorphicPropertyGrid extends StatelessWidget {
  final List<dynamic> items;
  final Function(String)? onItemTap;
  final bool isUnitView;

  const NeuroMorphicPropertyGrid({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  // Safe getters
  String _getItemId(dynamic item) {
    if (item is SectionPropertyItemModel) return item.id;
    if (item is SectionUnitItemModel) return item.id;
    return '';
  }

  String _getItemName(dynamic item) {
    if (item is SectionPropertyItemModel) return item.name;
    if (item is SectionUnitItemModel) return item.name;
    return '';
  }

  String? _getItemImage(dynamic item) {
    if (item is SectionPropertyItemModel) return item.imageUrl;
    if (item is SectionUnitItemModel) return item.imageUrl;
    return null;
  }

  String? _getItemLocation(dynamic item) {
    if (item is SectionPropertyItemModel) return item.location;
    return null;
  }

  double _getItemPrice(dynamic item) {
    if (item is SectionPropertyItemModel) return item.price ?? item.minPrice;
    if (item is SectionUnitItemModel) return item.price ?? item.minPrice;
    return 0.0;
  }

  double? _getItemRating(dynamic item) {
    if (item is SectionPropertyItemModel) return item.rating;
    return null;
  }

  int? _getItemDiscount(dynamic item) {
    if (item is SectionPropertyItemModel) return item.discount;
    if (item is SectionUnitItemModel) return item.discount;
    return null;
  }

  int? _getItemBedrooms(dynamic item) {
    if (item is SectionPropertyItemModel) return item.bedrooms;
    return null;
  }

  int? _getItemBathrooms(dynamic item) {
    if (item is SectionPropertyItemModel) return item.bathrooms;
    return null;
  }

  double? _getItemArea(dynamic item) {
    if (item is SectionPropertyItemModel) return item.area;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
      ),
      child: Column(
        children: [
          // Neuro Header
          _buildNeuroHeader(),

          const SizedBox(height: 24),

          // Staggered Grid Layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                (items.length / 2).ceil(),
                (rowIndex) {
                  final firstIndex = rowIndex * 2;
                  final secondIndex = firstIndex + 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        // First Card
                        Expanded(
                          child: _NeuroPropertyCard(
                            name: _getItemName(items[firstIndex]),
                            imageUrl: _getItemImage(items[firstIndex]),
                            location: _getItemLocation(items[firstIndex]),
                            price: _getItemPrice(items[firstIndex]),
                            rating: _getItemRating(items[firstIndex]),
                            discount: _getItemDiscount(items[firstIndex]),
                            bedrooms: _getItemBedrooms(items[firstIndex]),
                            bathrooms: _getItemBathrooms(items[firstIndex]),
                            area: _getItemArea(items[firstIndex]),
                            index: firstIndex,
                            isLeft: true,
                            onTap: () {
                              final id = _getItemId(items[firstIndex]);
                              if (id.isNotEmpty) {
                                HapticFeedback.lightImpact();
                                onItemTap?.call(id);
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Second Card (if exists)
                        if (secondIndex < items.length)
                          Expanded(
                            child: _NeuroPropertyCard(
                              name: _getItemName(items[secondIndex]),
                              imageUrl: _getItemImage(items[secondIndex]),
                              location: _getItemLocation(items[secondIndex]),
                              price: _getItemPrice(items[secondIndex]),
                              rating: _getItemRating(items[secondIndex]),
                              discount: _getItemDiscount(items[secondIndex]),
                              bedrooms: _getItemBedrooms(items[secondIndex]),
                              bathrooms: _getItemBathrooms(items[secondIndex]),
                              area: _getItemArea(items[secondIndex]),
                              index: secondIndex,
                              isLeft: false,
                              onTap: () {
                                final id = _getItemId(items[secondIndex]);
                                if (id.isNotEmpty) {
                                  HapticFeedback.lightImpact();
                                  onItemTap?.call(id);
                                }
                              },
                            ),
                          )
                        else
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNeuroHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryCyan.withOpacity(0.05),
            AppTheme.primaryPurple.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Circuit Pattern Background
          CustomPaint(
            painter: _CircuitPatternPainter(),
            size: Size.infinite,
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Neuro Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryCyan.withOpacity(0.1),
                        AppTheme.primaryCyan.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryCyan.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          color: AppTheme.primaryCyan,
                          size: 28,
                        ),
                        // Neural dots
                        ...List.generate(4, (index) {
                          final angle = (index * math.pi / 2);
                          return Transform.translate(
                            offset: Offset(
                              math.cos(angle) * 20,
                              math.sin(angle) * 20,
                            ),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NEURO COLLECTION',
                        style: AppTextStyles.overline.copyWith(
                          color: AppTheme.primaryCyan.withOpacity(0.8),
                          letterSpacing: 2,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'عقارات ذكية',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${items.length} عقار متاح',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.primaryCyan,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Indicators
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusIndicator('نشط', true),
                    const SizedBox(height: 8),
                    _buildStatusIndicator('متزامن', false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.neonGreen.withOpacity(0.1)
            : AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? AppTheme.neonGreen.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppTheme.neonGreen : AppTheme.textMuted,
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppTheme.neonGreen,
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppTheme.neonGreen : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Unique Neuro Card Design
class _NeuroPropertyCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final String? location;
  final double price;
  final double? rating;
  final int? discount;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final int index;
  final bool isLeft;
  final VoidCallback onTap;

  const _NeuroPropertyCard({
    required this.name,
    required this.imageUrl,
    required this.location,
    required this.price,
    required this.rating,
    required this.discount,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.index,
    required this.isLeft,
    required this.onTap,
  });

  @override
  State<_NeuroPropertyCard> createState() => _NeuroPropertyCardState();
}

class _NeuroPropertyCardState extends State<_NeuroPropertyCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _isPressed ? 0.97 : 1.0,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.isLeft ? Alignment.topLeft : Alignment.topRight,
              end: widget.isLeft ? Alignment.bottomRight : Alignment.bottomLeft,
              colors: [
                AppTheme.darkCard,
                AppTheme.darkCard.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Image Section with Overlay Info
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      if (widget.imageUrl != null &&
                          widget.imageUrl!.isNotEmpty)
                        CachedImageWidget(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.darkBackground2.withOpacity(0.5),
                                AppTheme.darkBackground3.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.architecture_rounded,
                              size: 36,
                              color: AppTheme.textMuted.withOpacity(0.2),
                            ),
                          ),
                        ),

                      // Dark gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.darkBackground.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),

                      // Overlays
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildNeuroChip(
                          Icons.auto_awesome_rounded,
                          'ID: ${widget.index + 1}',
                        ),
                      ),

                      if (widget.discount != null && widget.discount! > 0)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.discount}%',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Bottom Info Bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground.withOpacity(0.9),
                          ),
                          child: Row(
                            children: [
                              if (widget.bedrooms != null)
                                _buildMiniSpec(
                                  Icons.bed_outlined,
                                  '${widget.bedrooms}',
                                ),
                              if (widget.bathrooms != null)
                                _buildMiniSpec(
                                  Icons.bathroom_outlined,
                                  '${widget.bathrooms}',
                                ),
                              if (widget.area != null)
                                _buildMiniSpec(
                                  Icons.square_foot_outlined,
                                  '${widget.area?.toStringAsFixed(0)}',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name
                        Text(
                          widget.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Location Row
                        if (widget.location != null)
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.navigation_rounded,
                                    size: 10,
                                    color: AppTheme.primaryCyan,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.location!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        // Bottom Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryCyan.withOpacity(0.1),
                                    AppTheme.primaryPurple.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.payments_rounded,
                                    size: 14,
                                    color: AppTheme.primaryCyan,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.price.toStringAsFixed(0),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppTheme.primaryCyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'ريال',
                                    style: AppTextStyles.caption.copyWith(
                                      color:
                                          AppTheme.primaryCyan.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Rating or Action
                            if (widget.rating != null && widget.rating! > 0)
                              _buildRatingBar()
                            else
                              Icon(
                                Icons.arrow_circle_left_outlined,
                                color: AppTheme.primaryCyan,
                                size: 28,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Progress Indicator
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryCyan,
                        AppTheme.primaryPurple,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeuroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.primaryCyan,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryCyan,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSpec(IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.textLight.withOpacity(0.7),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar() {
    final rating = widget.rating ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 12,
              color: AppTheme.warning,
            );
          }),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// Circuit Pattern Painter
class _CircuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = AppTheme.primaryCyan.withOpacity(0.05);

    // Draw circuit lines
    for (double y = 20; y < size.height; y += 30) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    for (double x = 30; x < size.width; x += 40) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );

      // Draw nodes
      if (x.toInt() % 80 == 30) {
        canvas.drawCircle(
          Offset(x, size.height / 2),
          3,
          paint..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
