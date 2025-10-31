// lib/features/admin_units/presentation/widgets/futuristic_unit_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'package:bookn_cp_app/core/theme/app_dimensions.dart';
import '../../domain/entities/unit.dart';
import 'package:intl/intl.dart';

class FuturisticUnitCard extends StatefulWidget {
  final Unit unit;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;
  final int index;

  const FuturisticUnitCard({
    super.key,
    required this.unit,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
    this.index = 0,
  });

  @override
  State<FuturisticUnitCard> createState() => _FuturisticUnitCardState();
}

class _FuturisticUnitCardState extends State<FuturisticUnitCard>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _glowController;
  late AnimationController _entranceController;
  late AnimationController _sparkleController;

  // Animations
  late Animation<double> _hoverScale;
  late Animation<double> _pressScale;
  late Animation<double> _glowAnimation;
  late Animation<double> _entranceAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleAnimation;

  // State
  bool _isHovered = false;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntranceAnimation();
  }

  void _initializeAnimations() {
    // Hover Animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverScale = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    // Press Animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    // Glow Animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Entrance Animation
    _entranceController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    ));

    // Sparkle Animation
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _sparkleAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_sparkleController);
  }

  void _startEntranceAnimation() {
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _entranceAnimation,
        child: ScaleTransition(
          scale: _entranceAnimation,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            onTapDown: (_) {
              _pressController.forward();
            },
            onTapUp: (_) {
              _pressController.reverse();
            },
            onTapCancel: () {
              _pressController.reverse();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              setState(() => _showActions = !_showActions);
            },
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovered = true);
                _hoverController.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _hoverController.reverse();
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _hoverController,
                  _pressController,
                  _glowController,
                  _sparkleController,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pressScale.value * _hoverScale.value,
                    child: Container(
                      margin: const EdgeInsets.all(AppDimensions.paddingSmall),
                      child: Stack(
                        children: [
                          // Main Card
                          _buildMainCard(),

                          // Sparkle Effect
                          if (widget.isSelected || _isHovered)
                            _buildSparkleEffect(),

                          // Action Overlay
                          if (_showActions) _buildActionOverlay(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: [
          // Main shadow
          BoxShadow(
            color: widget.isSelected || _isHovered
                ? AppTheme.primaryBlue.withOpacity(0.3 * _glowAnimation.value)
                : Colors.black.withOpacity(0.2),
            blurRadius: widget.isSelected || _isHovered ? 30 : 20,
            offset: const Offset(0, 10),
            spreadRadius: widget.isSelected ? 2 : 0,
          ),
          // Inner glow
          if (widget.isSelected || _isHovered)
            BoxShadow(
              color: AppTheme.primaryPurple
                  .withOpacity(0.2 * _glowAnimation.value),
              blurRadius: 20,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isSelected
                    ? [
                        AppTheme.primaryBlue.withOpacity(0.2),
                        AppTheme.primaryPurple.withOpacity(0.15),
                        AppTheme.primaryViolet.withOpacity(0.1),
                      ]
                    : _isHovered
                        ? [
                            AppTheme.primaryBlue.withOpacity(0.12),
                            AppTheme.primaryPurple.withOpacity(0.08),
                            AppTheme.darkCard.withOpacity(0.9),
                          ]
                        : [
                            AppTheme.darkCard.withOpacity(0.95),
                            AppTheme.darkCard.withOpacity(0.9),
                            AppTheme.darkCard.withOpacity(0.85),
                          ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
              border: Border.all(
                color: widget.isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.6)
                    : _isHovered
                        ? AppTheme.primaryBlue.withOpacity(0.3)
                        : AppTheme.darkBorder.withOpacity(0.2),
                width: widget.isSelected ? 2 : 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxH = constraints.maxHeight;
                final bool isUltraCompact = maxH < 240;
                final bool isCompact = !isUltraCompact && maxH < 360;
                final double imageHeight = isUltraCompact
                    ? 80
                    : (isCompact ? 110 : 140);
                final int maxFields = isUltraCompact ? 1 : (isCompact ? 2 : 3);
                final EdgeInsets footerPadding = isCompact || isUltraCompact
                    ? const EdgeInsets.all(10)
                    : const EdgeInsets.all(12);
                final bool useGradientPrice = !isUltraCompact;

                return Stack(
                  children: [
                    // Background Pattern
                    if (widget.isSelected || _isHovered)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _AdvancedPatternPainter(
                            color: AppTheme.primaryBlue.withOpacity(0.03),
                            animation: _sparkleAnimation.value,
                          ),
                        ),
                      ),

                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image Section
                        _buildImageSection(imageHeight: imageHeight),

                        // Info Section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                AppDimensions.paddingMedium),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(
                                    height: AppDimensions.spaceSmall),
                                // منطقة قابلة للتمرير لملاءمة المحتوى دون فيض
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetails(),
                                        if (_getFilterFields().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          _buildDynamicFields(
                                              maxFields: maxFields),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildFooter(
                                  padding: footerPadding,
                                  useGradientPrice: useGradientPrice,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Status Badge
                    _buildStatusBadge(),

                    // Quick Actions
                    if (!_showActions) _buildQuickActions(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // دالة جديدة لبناء قسم الحقول الديناميكية
  Widget _buildDynamicFields({int maxFields = 3}) {
    final filterFields = _getFilterFields();

    if (filterFields.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleFields = filterFields.take(maxFields).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.3),
            AppTheme.darkSurface.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم مع أيقونة مميزة للفلاتر الأساسية
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonPurple.withOpacity(0.8),
                      AppTheme.neonGreen.withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.filter_list_rounded, // أيقونة الفلتر
                  size: 10,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'المعلومات الأساسية', // تغيير النص ليعكس أنها معلومات أساسية
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.neonPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // عرض الحقول في صفوف منظمة
          Column(
            children: visibleFields.map((fieldData) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildDynamicFieldRow(
                  displayName: fieldData['displayName'],
                  value: fieldData['value'],
                  fieldType: fieldData['fieldTypeId'],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // دالة محدثة للحصول على الحقول المناسبة للعرض
  List<Map<String, dynamic>> _getFilterFields() {
    final List<Map<String, dynamic>> filterFields = [];

    // أولوية: الحقول التي isPrimaryFilter = true (تُعرض حتى لو كانت القيم فارغة)
    for (final fieldValue in widget.unit.fieldValues) {
      if (fieldValue.isPrimaryFilter == true) {
        filterFields.add({
          'displayName':
              fieldValue.displayName ?? fieldValue.fieldName ?? 'حقل',
          'value': fieldValue.fieldValue,
          'fieldTypeId': fieldValue.fieldTypeId ?? 'text',
        });
      }
    }
    for (final group in widget.unit.dynamicFields) {
      for (final field in group.fieldValues) {
        if (field.isPrimaryFilter == true) {
          filterFields.add({
            'displayName': field.displayName ?? field.fieldName ?? 'حقل',
            'value': field.fieldValue,
            'fieldTypeId': field.fieldTypeId ?? 'text',
          });
        }
      }
    }

    if (filterFields.isNotEmpty) {
      return filterFields;
    }

    // بديل: إذا لم تكن هناك حقول أساسية، اعرض أول 3 حقول ذات قيمة
    final List<Map<String, dynamic>> fallback = [];
    for (final fieldValue in widget.unit.fieldValues) {
      if (fieldValue.fieldValue.isNotEmpty) {
        fallback.add({
          'displayName':
              fieldValue.displayName ?? fieldValue.fieldName ?? 'حقل',
          'value': fieldValue.fieldValue,
          'fieldTypeId': fieldValue.fieldTypeId ?? 'text',
        });
      }
    }
    for (final group in widget.unit.dynamicFields) {
      for (final field in group.fieldValues) {
        if (field.fieldValue.isNotEmpty) {
          fallback.add({
            'displayName': field.displayName ?? field.fieldName ?? 'حقل',
            'value': field.fieldValue,
            'fieldTypeId': field.fieldTypeId ?? 'text',
          });
        }
      }
    }

    return fallback;
  }

  // دالة جديدة لعرض الحقل في صف منظم
  Widget _buildDynamicFieldRow({
    required String displayName,
    required dynamic value,
    required String fieldType,
  }) {
    final formattedValue = _formatDynamicFieldValue(value, fieldType);
    final icon = _getFieldTypeIcon(fieldType);
    final color = _getFieldTypeColor(fieldType);

    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          '$displayName:',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            formattedValue,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // دالة لتنسيق قيمة الحقل حسب نوعه
  String _formatDynamicFieldValue(dynamic value, String fieldType) {
    if (value == null || value.toString().isEmpty) {
      return 'غير محدد';
    }

    switch (fieldType) {
      case 'boolean':
        final boolValue = value.toString().toLowerCase();
        return (boolValue == 'true' || boolValue == '1' || boolValue == 'yes')
            ? 'نعم'
            : 'لا';

      case 'currency':
        if (value is num) {
          return '${value.toStringAsFixed(0)} ريال';
        }
        final numValue = double.tryParse(value.toString());
        if (numValue != null) {
          return '${numValue.toStringAsFixed(0)} ريال';
        }
        return '$value ريال';

      case 'date':
        try {
          DateTime date;
          if (value is DateTime) {
            date = value;
          } else {
            date = DateTime.parse(value.toString());
          }
          return DateFormat('dd/MM/yyyy').format(date);
        } catch (_) {
          return value.toString();
        }

      case 'number':
        if (value is num) {
          return value.toStringAsFixed(value is int ? 0 : 1);
        }
        return value.toString();

      case 'select':
      case 'text':
      case 'textarea':
        final strValue = value.toString();
        return strValue.length > 15
            ? '${strValue.substring(0, 15)}...'
            : strValue;

      case 'multiselect':
        if (value is List) {
          final items = value.take(2).join(', ');
          if (value.length > 2) {
            return '$items +${value.length - 2}';
          }
          return items;
        }
        return value.toString();

      case 'phone':
        final phone = value.toString();
        if (phone.length == 10) {
          return '${phone.substring(0, 4)} ${phone.substring(4)}';
        }
        return phone;

      case 'email':
        final email = value.toString();
        if (email.length > 20) {
          final parts = email.split('@');
          if (parts.length == 2) {
            final username = parts[0].length > 10
                ? '${parts[0].substring(0, 10)}...'
                : parts[0];
            return '$username@${parts[1]}';
          }
        }
        return email;

      case 'file':
      case 'image':
        return 'ملف مرفق';

      default:
        final strValue = value.toString();
        return strValue.length > 15
            ? '${strValue.substring(0, 15)}...'
            : strValue;
    }
  }

  // دالة للحصول على أيقونة حسب نوع الحقل
  IconData _getFieldTypeIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields_rounded;
      case 'textarea':
        return Icons.notes_rounded;
      case 'number':
        return Icons.numbers_rounded;
      case 'currency':
        return Icons.attach_money_rounded;
      case 'boolean':
        return Icons.toggle_on_rounded;
      case 'select':
        return Icons.arrow_drop_down_circle_rounded;
      case 'multiselect':
        return Icons.checklist_rounded;
      case 'date':
        return Icons.calendar_today_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'file':
        return Icons.attach_file_rounded;
      case 'image':
        return Icons.image_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // دالة للحصول على لون حسب نوع الحقل
  Color _getFieldTypeColor(String fieldType) {
    switch (fieldType) {
      case 'boolean':
        return AppTheme.info;
      case 'currency':
      case 'number':
        return AppTheme.success;
      case 'date':
        return AppTheme.primaryPurple;
      case 'select':
      case 'multiselect':
        return AppTheme.neonPurple;
      case 'email':
        return AppTheme.primaryBlue;
      case 'phone':
        return AppTheme.primaryCyan;
      case 'file':
      case 'image':
        return AppTheme.warning;
      default:
        return AppTheme.primaryBlue;
    }
  }

  Widget _buildImageSection({required double imageHeight}) {
    return Container(
      height: imageHeight,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or Placeholder
          widget.unit.images?.isNotEmpty == true
              ? Hero(
                  tag: 'unit-image-${widget.unit.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusXLarge),
                    ),
                    child: Image.network(
                      widget.unit.images!.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    ),
                  ),
                )
              : _buildImagePlaceholder(),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXLarge),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.darkBackground.withOpacity(0.7),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // View & Booking Stats
          Positioned(
            bottom: 8,
            left: 12,
            child: _buildStatsChips(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.primaryPurple.withOpacity(0.15),
            AppTheme.primaryViolet.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.glassLight.withOpacity(0.3),
                AppTheme.glassDark.withOpacity(0.2),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.apartment_rounded,
            size: 40,
            color: AppTheme.primaryBlue.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsChips() {
    return Row(
      children: [
        _buildStatChip(
          Icons.visibility_rounded,
          '${widget.unit.viewCount}',
          AppTheme.primaryCyan,
        ),
        const SizedBox(width: AppDimensions.spaceXSmall),
        _buildStatChip(
          Icons.calendar_today_rounded,
          '${widget.unit.bookingCount}',
          AppTheme.primaryPurple,
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit Name with Shimmer Effect
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: AppTextStyles.heading3.copyWith(
            color: widget.isSelected || _isHovered
                ? AppTheme.primaryBlue
                : AppTheme.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: widget.isSelected || _isHovered ? 18 : 16,
          ),
          child: Text(
            widget.unit.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 4),

        // Unit Type & Property
        Row(
          children: [
            // Unit Type
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryBlue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.apartment_rounded,
                    size: 11,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.unit.unitTypeName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property Name
        Row(
          children: [
            Icon(
              Icons.location_city_rounded,
              size: 14,
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.unit.propertyName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textLight,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Capacity & Features
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Capacity
            if (widget.unit.capacityDisplay.isNotEmpty)
              _buildFeatureChip(
                Icons.people_rounded,
                widget.unit.capacityDisplay,
                AppTheme.primaryCyan,
              ),

            // Top Features (max 2)
            ...widget.unit.featuresList.take(2).map(
                  (feature) => _buildFeatureChip(
                    _getFeatureIcon(feature),
                    feature,
                    AppTheme.primaryPurple,
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({EdgeInsets padding = const EdgeInsets.all(12), bool useGradientPrice = true}) {
    return Column(
      children: [
        // Price Section
        Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.primaryPurple.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      useGradientPrice
                          ? ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient
                                      .createShader(bounds),
                              child: Text(
                                widget.unit.basePrice.displayAmount,
                                style: AppTextStyles.heading3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              widget.unit.basePrice.displayAmount,
                              style: AppTextStyles.heading3.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          widget.unit.basePrice.currency,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.unit.discountPercentage > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'خصم ${widget.unit.discountPercentage}%',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                ],
              ),

              // Pricing Method
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.2),
                      AppTheme.primaryViolet.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.unit.pricingMethod.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.unit.pricingMethod.arabicLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // باقي الدوال كما هي...
  Widget _buildStatusBadge() {
    return Positioned(
      top: 12,
      right: 12,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.unit.isAvailable
                ? [
                    AppTheme.success,
                    AppTheme.success.withOpacity(0.8),
                  ]
                : [
                    AppTheme.warning,
                    AppTheme.warning.withOpacity(0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.unit.isAvailable
                  ? AppTheme.success.withOpacity(0.4)
                  : AppTheme.warning.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.unit.isAvailable ? 'متاحة' : 'محجوزة',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    if (widget.onEdit == null && widget.onDelete == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 12,
      left: 12,
      child: AnimatedOpacity(
        opacity: _isHovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: _isHovered ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              if (widget.onEdit != null)
                _buildActionIconButton(
                  Icons.edit_rounded,
                  AppTheme.primaryBlue,
                  widget.onEdit!,
                ),
              if (widget.onEdit != null && widget.onDelete != null)
                const SizedBox(width: 8),
              if (widget.onDelete != null)
                _buildActionIconButton(
                  Icons.delete_rounded,
                  AppTheme.error,
                  widget.onDelete!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildActionOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppTheme.overlayDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.onEdit != null)
                      _buildOverlayActionButton(
                        Icons.edit_rounded,
                        'تعديل',
                        AppTheme.primaryBlue,
                        widget.onEdit!,
                      ),
                    if (widget.onEdit != null && widget.onDelete != null)
                      const SizedBox(width: 16),
                    if (widget.onDelete != null)
                      _buildOverlayActionButton(
                        Icons.delete_rounded,
                        'حذف',
                        AppTheme.error,
                        widget.onDelete!,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setState(() => _showActions = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.darkBorder.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
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

  Widget _buildOverlayActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _showActions = false);
        onTap();
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkleEffect() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _SparklePainter(
                progress: _sparkleAnimation.value,
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getFeatureIcon(String feature) {
    final featureLower = feature.toLowerCase();
    if (featureLower.contains('واي فاي') || featureLower.contains('wifi')) {
      return Icons.wifi_rounded;
    } else if (featureLower.contains('تكييف') || featureLower.contains('ac')) {
      return Icons.ac_unit_rounded;
    } else if (featureLower.contains('مطبخ')) {
      return Icons.kitchen_rounded;
    } else if (featureLower.contains('موقف') ||
        featureLower.contains('parking')) {
      return Icons.local_parking_rounded;
    } else if (featureLower.contains('مسبح') || featureLower.contains('pool')) {
      return Icons.pool_rounded;
    } else {
      return Icons.star_rounded;
    }
  }
}

// Advanced Pattern Painter
class _AdvancedPatternPainter extends CustomPainter {
  final Color color;
  final double animation;

  _AdvancedPatternPainter({
    required this.color,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Hexagonal pattern
    const double hexSize = 15;
    final double hexHeight = hexSize * math.sqrt(3);

    for (double y = 0; y < size.height + hexHeight; y += hexHeight * 0.75) {
      for (double x = 0; x < size.width + hexSize * 2; x += hexSize * 3) {
        final offset = (y ~/ (hexHeight * 0.75)).isEven ? 0.0 : hexSize * 1.5;

        // Animated opacity based on position
        final distance = math.sqrt(
          math.pow(x + offset - size.width / 2, 2) +
              math.pow(y - size.height / 2, 2),
        );
        final maxDistance = math.sqrt(
          math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2),
        );
        final normalizedDistance = distance / maxDistance;
        final opacity =
            (math.sin(animation + normalizedDistance * math.pi) + 1) / 2;

        paint.color = color.withOpacity(color.opacity * opacity * 0.5);

        _drawHexagon(
          canvas,
          Offset(x + offset, y),
          hexSize * 0.5,
          paint,
        );
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Sparkle Painter
class _SparklePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SparklePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent sparkles

    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final sparkleProgress = (progress + i * 0.2) % 1.0;
      final opacity = math.sin(sparkleProgress * math.pi);
      final sparkleSize = 2 + opacity * 2;

      paint.color = color.withOpacity(color.opacity * opacity);

      // Draw sparkle
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 2 * math.pi);

      // Draw cross
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: sparkleSize * 3,
          height: sparkleSize * 0.5,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: sparkleSize * 0.5,
          height: sparkleSize * 3,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
