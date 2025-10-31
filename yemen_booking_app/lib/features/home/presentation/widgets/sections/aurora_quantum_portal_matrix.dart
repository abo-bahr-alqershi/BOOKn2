// lib/features/home/presentation/widgets/sections/elegant_aurora_portal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';

class AuroraQuantumPortalMatrix extends StatefulWidget {
  final List<dynamic> items;
  final Function(String)? onItemTap;
  final bool isUnitView;

  const AuroraQuantumPortalMatrix({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  @override
  State<AuroraQuantumPortalMatrix> createState() =>
      _AuroraQuantumPortalMatrixState();
}

class _AuroraQuantumPortalMatrixState extends State<AuroraQuantumPortalMatrix>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _glowController;

  int _activeIndex = -1;
  Timer? _activeTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startActiveRotation();
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startActiveRotation() {
    _activeTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && widget.items.isNotEmpty) {
        setState(() {
          _activeIndex = (_activeIndex + 1) % widget.items.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Safe getters
  String _getItemName(dynamic item) {
    if (item is SectionPropertyItemModel) {
      return item.name ?? '';
    } else if (item is SectionUnitItemModel) {
      return item.name ?? '';
    }
    return '';
  }

  String _getItemId(dynamic item) {
    if (item is SectionPropertyItemModel) {
      return item.id ?? '';
    } else if (item is SectionUnitItemModel) {
      return item.id ?? '';
    }
    return '';
  }

  String? _getItemImage(dynamic item) {
    if (item is SectionPropertyItemModel) {
      return item.imageUrl;
    } else if (item is SectionUnitItemModel) {
      return item.imageUrl;
    }
    return null;
  }

  double _getItemPrice(dynamic item) {
    if (item is SectionPropertyItemModel) {
      return item.minPrice ?? 0.0;
    } else if (item is SectionUnitItemModel) {
      return item.price ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final itemCount = widget.items.length.clamp(0, 12);

    return Container(
      height: size.height * 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground2.withOpacity(0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle background effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SubtleAuroraPainter(
                    animation: _shimmerController.value,
                  ),
                );
              },
            ),
          ),

          // Grid Layout
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 20),

                // Grid
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index >= widget.items.length) {
                        return const SizedBox.shrink();
                      }

                      final item = widget.items[index];
                      final isActive = _activeIndex == index;

                      return _ElegantPortalCard(
                        item: item,
                        index: index,
                        isActive: isActive,
                        onTap: () => _handleItemTap(item),
                        getName: _getItemName,
                        getImage: _getItemImage,
                        getPrice: _getItemPrice,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            color: AppTheme.primaryCyan.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'استكشف العقارات',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemTap(dynamic item) {
    final id = _getItemId(item);
    if (id.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onItemTap?.call(id);
    }
  }
}

class _ElegantPortalCard extends StatefulWidget {
  final dynamic item;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  final String Function(dynamic) getName;
  final String? Function(dynamic) getImage;
  final double Function(dynamic) getPrice;

  const _ElegantPortalCard({
    required this.item,
    required this.index,
    required this.isActive,
    required this.onTap,
    required this.getName,
    required this.getImage,
    required this.getPrice,
  });

  @override
  State<_ElegantPortalCard> createState() => _ElegantPortalCardState();
}

class _ElegantPortalCardState extends State<_ElegantPortalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_ElegantPortalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scaleController.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.getName(widget.item);
    final imageUrl = widget.getImage(widget.item);
    final price = widget.getPrice(widget.item);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          final scale = 1.0 + (_scaleController.value * 0.05);

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.isActive
                        ? AppTheme.primaryCyan.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: widget.isActive ? 20 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background
                    Positioned.fill(
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedImageWidget(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.darkCard,
                                    AppTheme.darkBackground2,
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Overlay
                    Positioned.fill(
                      child: Container(
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
                    ),

                    // Content
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard.withOpacity(0.7),
                              border: Border(
                                top: BorderSide(
                                  color: widget.isActive
                                      ? AppTheme.primaryCyan.withOpacity(0.5)
                                      : AppTheme.darkBorder.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (price > 0)
                                  Text(
                                    '${price.toStringAsFixed(0)} ريال',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.primaryCyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Active indicator
                    if (widget.isActive)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonGreen,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Subtle Aurora Background Painter
class _SubtleAuroraPainter extends CustomPainter {
  final double animation;

  _SubtleAuroraPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    // Draw subtle aurora waves
    for (int i = 0; i < 2; i++) {
      final phase = animation * 2 * math.pi + (i * math.pi);
      final path = Path();

      path.moveTo(0, size.height * 0.5);

      for (double x = 0; x <= size.width; x += 30) {
        final y = size.height * 0.5 +
            math.sin((x / size.width * 2 * math.pi) + phase) * 50;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          i == 0
              ? AppTheme.primaryCyan.withOpacity(0.03)
              : AppTheme.primaryPurple.withOpacity(0.02),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
