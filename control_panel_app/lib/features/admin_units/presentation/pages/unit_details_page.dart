// lib/features/admin_units/presentation/pages/unit_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../bloc/unit_details/unit_details_bloc.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_field_value.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/pricing_method.dart';
import '../widgets/unit_image_gallery.dart';

class UnitDetailsPage extends StatefulWidget {
  final String unitId;

  const UnitDetailsPage({
    super.key,
    required this.unitId,
  });

  @override
  State<UnitDetailsPage> createState() => _UnitDetailsPageState();
}

class _UnitDetailsPageState extends State<UnitDetailsPage>
    with SingleTickerProviderStateMixin {
  // Animation Controller - واحد فقط للحركات الأساسية
  late AnimationController _animationController;

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // Tab Controller
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _setupScrollListener();
    _loadUnitDetails();
  }

  // جمع الحقول الأساسية من المصدرين
  List<Map<String, dynamic>> _collectPrimaryFilterFields(Unit unit) {
    final List<Map<String, dynamic>> fields = [];
    for (final fv in unit.fieldValues) {
      if (fv.isPrimaryFilter == true) {
        fields.add({
          'displayName': fv.displayName ?? fv.fieldName ?? 'حقل',
          'value': fv.fieldValue,
          'fieldTypeId': fv.fieldTypeId ?? 'text',
        });
      }
    }
    for (final group in unit.dynamicFields) {
      for (final f in group.fieldValues) {
        if (f.isPrimaryFilter == true) {
          fields.add({
            'displayName': f.displayName ?? f.fieldName ?? 'حقل',
            'value': f.fieldValue,
            'fieldTypeId': f.fieldTypeId ?? 'text',
          });
        }
      }
    }
    // بديل إن لم توجد أساسية
    if (fields.isEmpty) {
      for (final fv in unit.fieldValues) {
        if (fv.fieldValue.isNotEmpty) {
          fields.add({
            'displayName': fv.displayName ?? fv.fieldName ?? 'حقل',
            'value': fv.fieldValue,
            'fieldTypeId': fv.fieldTypeId ?? 'text',
          });
        }
      }
      for (final group in unit.dynamicFields) {
        for (final f in group.fieldValues) {
          if (f.fieldValue.isNotEmpty) {
            fields.add({
              'displayName': f.displayName ?? f.fieldName ?? 'حقل',
              'value': f.fieldValue,
              'fieldTypeId': f.fieldTypeId ?? 'text',
            });
          }
        }
      }
    }
    return fields;
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  void _loadUnitDetails() {
    context.read<UnitDetailsBloc>().add(
          LoadUnitDetailsEvent(unitId: widget.unitId),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocConsumer<UnitDetailsBloc, UnitDetailsState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          if (state is UnitDetailsLoaded) {
            return _buildLoadedContent(state.unit);
          } else if (state is UnitDetailsLoading) {
            return _buildLoadingState();
          } else if (state is UnitDetailsError) {
            return _buildErrorState(state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedContent(Unit unit) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Header
            _buildSliverHeader(unit),

            // Unit Info
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _animationController,
                child: _buildContent(unit),
              ),
            ),
          ],
        ),

        // Floating Header (appears on scroll)
        if (_scrollOffset > 300) _buildFloatingHeader(unit),

        // Floating Actions
        _buildFloatingActions(unit),
      ],
    );
  }

  Widget _buildSliverHeader(Unit unit) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: false,
      leadingWidth: 40,
      toolbarHeight: 40,
      backgroundColor: Colors.transparent,
      leading: _buildBackButton(),
      actions: [
        _buildActionButton(
          icon: Icons.share,
          onTap: () => _shareUnit(unit),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (unit.images?.isNotEmpty ?? false)
              Hero(
                tag: 'unit-${unit.id}',
                child: CachedImageWidget(
                  imageUrl: unit.images!.first,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.3),
                      AppTheme.primaryPurple.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.photo,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.4, 0.6, 1.0],
                ),
              ),
            ),

            // Unit Info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildHeaderInfo(unit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(Unit unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unit Name
        Text(
          unit.name,
          style: AppTextStyles.heading1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Property Name
        Row(
          children: [
            Icon(
              CupertinoIcons.building_2_fill,
              size: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              '${unit.propertyName} • ${unit.unitTypeName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Price & Status
        Row(
          children: [
            _buildPriceTag(unit.basePrice, unit.pricingMethod),
            const SizedBox(width: 12),
            _buildStatusBadge(unit.isAvailable),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(Unit unit) {
    return Column(
      children: [
        // Stats Cards
        _buildStatsSection(unit),

        // Tab Bar
        _buildTabBar(),

        // Tab Content
        _buildTabContent(unit),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStatsSection(Unit unit) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _buildStatCard(
                icon: CupertinoIcons.eye,
                label: 'المشاهدات',
                value: unit.viewCount.toString(),
                color: AppTheme.primaryBlue,
              ),
              _buildStatCard(
                icon: CupertinoIcons.calendar,
                label: 'الحجوزات',
                value: unit.bookingCount.toString(),
                color: AppTheme.primaryPurple,
              ),
              _buildStatCard(
                icon: CupertinoIcons.star_fill,
                label: 'التقييم',
                value: '4.8',
                color: AppTheme.warning,
              ),
              _buildStatCard(
                icon: CupertinoIcons.person_2,
                label: 'السعة',
                value: unit.maxCapacity.toString(),
                color: AppTheme.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // مهم: لجعل Column تأخذ أقل مساحة ممكنة
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['معلومات', 'الصور', 'المميزات', 'التوفر'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(Unit unit) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getTabContent(unit),
      ),
    );
  }

  Widget _getTabContent(Unit unit) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildInfoTab(unit);
      case 1:
        return _buildGalleryTab(unit);
      case 2:
        return _buildFeaturesTab(unit);
      case 3:
        return _buildAvailabilityTab(unit);
      default:
        return _buildInfoTab(unit);
    }
  }

  Widget _buildInfoTab(Unit unit) {
    return Container(
      key: const ValueKey('info'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('معلومات عامة'),
          const SizedBox(height: 16),
          _buildInfoRow('الكود', unit.name),
          _buildInfoRow('النوع', unit.unitTypeName),
          _buildInfoRow('العقار', unit.propertyName),
          _buildInfoRow('السعة', '${unit.maxCapacity} أشخاص'),
          // الحقول الأساسية (Primary Filters)
          if (unit.dynamicFields.isNotEmpty || unit.fieldValues.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('المعلومات الأساسية'),
            const SizedBox(height: 12),
            _buildAllDynamicFields(unit),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryTab(Unit unit) {
    return SizedBox(
      key: const ValueKey('gallery'),
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: UnitImageGallery(
          unitId: widget.unitId,
          isReadOnly: true,
          maxImages: 20,
        ),
      ),
    );
  }

  Widget _buildFeaturesTab(Unit unit) {
    return Container(
      key: const ValueKey('features'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: unit.featuresList.isEmpty
          ? Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 48,
                    color: AppTheme.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد مميزات مضافة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: unit.featuresList.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFeatureIcon(feature),
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAvailabilityTab(Unit unit) {
    return Container(
      key: const ValueKey('availability'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 48,
            color: AppTheme.primaryBlue.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'التقويم قيد التطوير',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض جدول التوفر والحجوزات هنا',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFields(List<FieldGroupWithValues> fieldGroups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fieldGroups.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.displayName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...group.fieldValues.map((field) {
                final value = field.fieldValue;
                return _buildInfoRow(
                  field.displayName ?? field.fieldName ?? '',
                  _formatFieldValue(value, field.fieldTypeId ?? 'text'),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  // جمع الحقول من المصدرين وعرض غير المكررات
  Widget _buildAllDynamicFields(Unit unit) {
    final grouped = unit.dynamicFields;
    final groupedFieldIds = <String>{
      for (final g in grouped)
        for (final f in g.fieldValues) f.fieldId,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grouped.isNotEmpty) _buildDynamicFields(grouped),
        ...unit.fieldValues
            .where((fv) => !groupedFieldIds.contains(fv.fieldId))
            .map((fv) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInfoRow(
                    fv.displayName ?? fv.fieldName ?? 'حقل',
                    _formatFieldValue(fv.fieldValue, fv.fieldTypeId ?? 'text'),
                  ),
                )),
      ],
    );
  }

  // منسق بسيط للقيم مثل الكارد
  String _formatFieldValue(dynamic value, String fieldType) {
    if (value == null || value.toString().isEmpty) return 'غير محدد';
    switch (fieldType) {
      case 'boolean':
        final v = value.toString().toLowerCase();
        return (v == 'true' || v == '1' || v == 'yes') ? 'نعم' : 'لا';
      case 'currency':
        final num? n = value is num ? value : num.tryParse(value.toString());
        return n != null ? '${n.toStringAsFixed(0)} ريال' : '$value ريال';
      case 'date':
        try {
          final d =
              value is DateTime ? value : DateTime.parse(value.toString());
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        } catch (_) {
          return value.toString();
        }
      case 'number':
        if (value is num) return value.toString();
        return value.toString();
      case 'multiselect':
        if (value is List) return value.join(', ');
        return value.toString();
      default:
        return value.toString();
    }
  }

  Widget _buildFloatingHeader(Unit unit) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.arrow_back,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          unit.propertyName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPriceTag(unit.basePrice, unit.pricingMethod),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(Unit unit) {
    return Positioned(
      bottom: 32,
      right: 20,
      child: Column(
        children: [
          _buildFloatingButton(
            icon: CupertinoIcons.pencil,
            color: AppTheme.primaryBlue,
            onTap: () => _navigateToEdit(unit),
          ),
          const SizedBox(height: 12),
          _buildFloatingButton(
            icon: CupertinoIcons.trash,
            color: AppTheme.error,
            onTap: () => _showDeleteConfirmation(unit),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pop();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTag(Money price, PricingMethod method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            price.displayAmount,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            method.arabicLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryBlue.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppTheme.success.withValues(alpha: 0.2)
            : AppTheme.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAvailable ? AppTheme.success : AppTheme.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'متاحة' : 'محجوزة',
            style: AppTextStyles.caption.copyWith(
              color: isAvailable ? AppTheme.success : AppTheme.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // State Builders
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CupertinoActivityIndicator(
              color: AppTheme.primaryBlue,
              radius: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _loadUnitDetails();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  IconData _getFeatureIcon(String feature) {
    final featureLower = feature.toLowerCase();
    if (featureLower.contains('واي فاي') || featureLower.contains('wifi')) {
      return CupertinoIcons.wifi;
    } else if (featureLower.contains('تكييف') || featureLower.contains('ac')) {
      return CupertinoIcons.snow;
    } else if (featureLower.contains('مطبخ')) {
      return CupertinoIcons.flame;
    } else if (featureLower.contains('موقف')) {
      return CupertinoIcons.car;
    } else if (featureLower.contains('مسبح')) {
      return CupertinoIcons.drop;
    } else {
      return CupertinoIcons.checkmark_circle;
    }
  }

  void _handleStateChanges(BuildContext context, UnitDetailsState state) {
    if (state is UnitDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حذف الوحدة بنجاح'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
    } else if (state is UnitDetailsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _navigateToEdit(Unit unit) {
    context.push('/admin/units/${unit.id}/edit');
  }

  void _shareUnit(Unit unit) {
    // Implement share functionality
  }

  void _showDeleteConfirmation(Unit unit) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.error.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'حذف الوحدة؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا يمكن التراجع عن هذا الإجراء',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<UnitDetailsBloc>().add(
                                DeleteUnitDetailsEvent(unitId: unit.id),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
