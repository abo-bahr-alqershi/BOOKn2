import 'package:bookn_cp_app/features/property_types/presentation/widgets/futuristic_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/property_types/property_types_bloc.dart';
import '../bloc/property_types/property_types_event.dart';
import '../bloc/property_types/property_types_state.dart';
import '../bloc/unit_types/unit_types_bloc.dart';
import '../bloc/unit_types/unit_types_event.dart';
import '../bloc/unit_types/unit_types_state.dart';
import '../bloc/unit_type_fields/unit_type_fields_bloc.dart';
import '../bloc/unit_type_fields/unit_type_fields_event.dart';
import '../bloc/unit_type_fields/unit_type_fields_state.dart';
import '../widgets/property_type_card.dart';
import '../widgets/unit_type_card.dart';
import '../widgets/unit_type_field_card.dart';
import '../widgets/property_type_modal.dart';
import '../widgets/unit_type_modal.dart';
import '../widgets/unit_type_field_modal.dart';
import 'package:flutter/src/painting/edge_insets.dart';
import 'package:bookn_cp_app/core/widgets/loading_widget.dart';

class AdminPropertyTypesPage extends StatefulWidget {
  const AdminPropertyTypesPage({super.key});

  @override
  State<AdminPropertyTypesPage> createState() => _AdminPropertyTypesPageState();
}

class _AdminPropertyTypesPageState extends State<AdminPropertyTypesPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;

  final ScrollController _propertyTypesScrollController = ScrollController();
  final ScrollController _unitTypesScrollController = ScrollController();
  final ScrollController _fieldsScrollController = ScrollController();

  String? _selectedPropertyTypeId;
  String? _selectedUnitTypeId;
  String _searchFieldsQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _backgroundRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _loadInitialData() {
    context.read<PropertyTypesBloc>().add(const LoadPropertyTypesEvent());
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _propertyTypesScrollController.dispose();
    _unitTypesScrollController.dispose();
    _fieldsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStatsSection(),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundRotation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.8),
                AppTheme.darkBackground3.withOpacity(0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _FuturisticBackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'إدارة أنواع الكيانات والوحدات',
                  style: AppTextStyles.heading1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'إدارة شاملة لأنواع الكيانات وأنواع الوحدات والحقول الديناميكية',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth > 600
              ? (constraints.maxWidth - 36) / 3
              : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                BlocBuilder<PropertyTypesBloc, PropertyTypesState>(
                  builder: (context, state) {
                    final count = state is PropertyTypesLoaded
                        ? state.propertyTypes.length
                        : 0;
                    return SizedBox(
                      width: cardWidth,
                      child: FuturisticStatsCard(
                        title: 'أنواع الكيانات',
                        value: count.toString(),
                        icon: Icons.business_rounded,
                        color: AppTheme.primaryBlue,
                        glowAnimation: _glowAnimation,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                BlocBuilder<UnitTypesBloc, UnitTypesState>(
                  builder: (context, state) {
                    final count =
                        state is UnitTypesLoaded ? state.unitTypes.length : 0;
                    return SizedBox(
                      width: cardWidth,
                      child: FuturisticStatsCard(
                        title: 'أنواع الوحدات',
                        value: count.toString(),
                        icon: Icons.home_rounded,
                        color: AppTheme.neonGreen,
                        glowAnimation: _glowAnimation,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                BlocBuilder<UnitTypeFieldsBloc, UnitTypeFieldsState>(
                  builder: (context, state) {
                    final count =
                        state is UnitTypeFieldsLoaded ? state.fields.length : 0;
                    return SizedBox(
                      width: cardWidth,
                      child: FuturisticStatsCard(
                        title: 'الحقول الديناميكية',
                        value: count.toString(),
                        icon: Icons.text_fields_rounded,
                        color: AppTheme.primaryPurple,
                        glowAnimation: _glowAnimation,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 768) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return PageView(
      children: [
        _buildPropertyTypesColumn(expanded: true),
        if (_selectedPropertyTypeId != null)
          _buildUnitTypesColumn(expanded: true),
        if (_selectedUnitTypeId != null) _buildFieldsColumn(expanded: true),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildPropertyTypesColumn(),
        ),
        if (_selectedPropertyTypeId != null)
          Expanded(
            flex: 3,
            child: _buildUnitTypesColumn(),
          ),
        if (_selectedUnitTypeId != null)
          Expanded(
            flex: 4,
            child: _buildFieldsColumn(),
          ),
      ],
    );
  }

  Widget _buildPropertyTypesColumn({bool expanded = false}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildColumnHeader(
                title: 'أنواع الكيانات',
                icon: Icons.business_rounded,
                color: AppTheme.primaryBlue,
                onAdd: () => _showPropertyTypeModal(),
              ),
              Expanded(
                child: BlocBuilder<PropertyTypesBloc, PropertyTypesState>(
                  builder: (context, state) {
                    if (state is PropertyTypesLoading) {
                      return _buildLoadingState();
                    }

                    if (state is PropertyTypesError) {
                      return _buildErrorState(state.message);
                    }

                    if (state is PropertyTypesLoaded) {
                      if (state.propertyTypes.isEmpty) {
                        return _buildEmptyState(
                          icon: Icons.business_rounded,
                          message: 'لا توجد أنواع كيانات',
                        );
                      }

                      return ListView.builder(
                        controller: _propertyTypesScrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: state.propertyTypes.length,
                        itemBuilder: (context, index) {
                          final propertyType = state.propertyTypes[index];
                          return PropertyTypeCard(
                            propertyType: propertyType,
                            isSelected:
                                _selectedPropertyTypeId == propertyType.id,
                            onTap: () {
                              setState(() {
                                _selectedPropertyTypeId = propertyType.id;
                                _selectedUnitTypeId = null;
                              });
                              context.read<PropertyTypesBloc>().add(
                                    SelectPropertyTypeEvent(
                                        propertyTypeId: propertyType.id),
                                  );
                              context.read<UnitTypesBloc>().add(
                                    LoadUnitTypesEvent(
                                        propertyTypeId: propertyType.id),
                                  );
                            },
                            onEdit: () => _showPropertyTypeModal(
                                propertyType: propertyType),
                            onDelete: () => _confirmDelete(
                              title: 'حذف نوع الكيان',
                              message:
                                  'هل أنت متأكد من حذف نوع الكيان "${propertyType.name}"؟',
                              onConfirm: () {
                                context.read<PropertyTypesBloc>().add(
                                      DeletePropertyTypeEvent(
                                          propertyTypeId: propertyType.id),
                                    );
                              },
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitTypesColumn({bool expanded = false}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildColumnHeader(
                title: 'أنواع الوحدات',
                icon: Icons.home_rounded,
                color: AppTheme.neonGreen,
                onAdd: () => _showUnitTypeModal(),
              ),
              Expanded(
                child: BlocBuilder<UnitTypesBloc, UnitTypesState>(
                  builder: (context, state) {
                    if (state is UnitTypesLoading) {
                      return _buildLoadingState();
                    }

                    if (state is UnitTypesError) {
                      return _buildErrorState(state.message);
                    }

                    if (state is UnitTypesLoaded) {
                      if (state.unitTypes.isEmpty) {
                        return _buildEmptyState(
                          icon: Icons.home_rounded,
                          message: 'لا توجد أنواع وحدات',
                        );
                      }

                      return ListView.builder(
                        controller: _unitTypesScrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: state.unitTypes.length,
                        itemBuilder: (context, index) {
                          final unitType = state.unitTypes[index];
                          return UnitTypeCard(
                            unitType: unitType,
                            isSelected: _selectedUnitTypeId == unitType.id,
                            onTap: () {
                              setState(() {
                                _selectedUnitTypeId = unitType.id;
                              });
                              context.read<UnitTypesBloc>().add(
                                    SelectUnitTypeEvent(
                                        unitTypeId: unitType.id),
                                  );
                              context.read<UnitTypeFieldsBloc>().add(
                                    LoadUnitTypeFieldsEvent(
                                        unitTypeId: unitType.id),
                                  );
                            },
                            onEdit: () =>
                                _showUnitTypeModal(unitType: unitType),
                            onDelete: () => _confirmDelete(
                              title: 'حذف نوع الوحدة',
                              message:
                                  'هل أنت متأكد من حذف نوع الوحدة "${unitType.name}"؟',
                              onConfirm: () {
                                context.read<UnitTypesBloc>().add(
                                      DeleteUnitTypeEvent(
                                          unitTypeId: unitType.id),
                                    );
                              },
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsColumn({bool expanded = false}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildColumnHeader(
                title: 'الحقول الديناميكية',
                icon: Icons.text_fields_rounded,
                color: AppTheme.primaryPurple,
                onAdd: () => _showFieldModal(),
                showSearch: true,
                onSearch: (query) {
                  setState(() => _searchFieldsQuery = query);
                  context.read<UnitTypeFieldsBloc>().add(
                        SearchFieldsEvent(searchTerm: query),
                      );
                },
              ),
              Expanded(
                child: BlocBuilder<UnitTypeFieldsBloc, UnitTypeFieldsState>(
                  builder: (context, state) {
                    if (state is UnitTypeFieldsLoading) {
                      return _buildLoadingState();
                    }

                    if (state is UnitTypeFieldsError) {
                      return _buildErrorState(state.message);
                    }

                    if (state is UnitTypeFieldsLoaded) {
                      final fields = state.filteredFields;

                      if (fields.isEmpty) {
                        return _buildEmptyState(
                          icon: Icons.text_fields_rounded,
                          message: _searchFieldsQuery.isNotEmpty
                              ? 'لا توجد نتائج للبحث'
                              : 'لا توجد حقول ديناميكية',
                        );
                      }

                      return ListView.builder(
                        controller: _fieldsScrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: fields.length,
                        itemBuilder: (context, index) {
                          final field = fields[index];
                          return UnitTypeFieldCard(
                            field: field,
                            onEdit: () => _showFieldModal(field: field),
                            onDelete: () => _confirmDelete(
                              title: 'حذف الحقل',
                              message:
                                  'هل أنت متأكد من حذف الحقل "${field.displayName}"؟',
                              onConfirm: () {
                                context.read<UnitTypeFieldsBloc>().add(
                                      DeleteFieldEvent(fieldId: field.fieldId),
                                    );
                              },
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onAdd,
    bool showSearch = false,
    Function(String)? onSearch,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAdd();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'إضافة',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 8),
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                onChanged: onSearch,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'البحث في الحقول...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.textMuted.withOpacity(0.5),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري التحميل...',
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkSurface.withOpacity(0.5),
                  AppTheme.darkSurface.withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showPropertyTypeModal({dynamic propertyType}) {
    final parentContext = context;
    showDialog(
      fullscreenDialog: true,
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (context) => PropertyTypeModal(
        propertyType: propertyType,
        onSave: (data) {
          if (propertyType != null) {
            parentContext.read<PropertyTypesBloc>().add(
                  UpdatePropertyTypeEvent(
                    propertyTypeId: propertyType.id,
                    name: data['name'],
                    description: data['description'],
                    defaultAmenities: data['defaultAmenities'],
                    icon: data['icon'],
                  ),
                );
          } else {
            parentContext.read<PropertyTypesBloc>().add(
                  CreatePropertyTypeEvent(
                    name: data['name'],
                    description: data['description'],
                    defaultAmenities: data['defaultAmenities'],
                    icon: data['icon'],
                  ),
                );
          }
        },
      ),
    );
  }

  void _showUnitTypeModal({dynamic unitType}) {
    if (_selectedPropertyTypeId == null) {
      _showErrorMessage('يرجى اختيار نوع كيان أولاً');
      return;
    }

    final parentContext = context;
    showDialog(
      fullscreenDialog: true,
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (context) => UnitTypeModal(
        unitType: unitType,
        propertyTypeId: _selectedPropertyTypeId!,
        onSave: (data) {
          if (unitType != null) {
            parentContext.read<UnitTypesBloc>().add(
                  UpdateUnitTypeEvent(
                    unitTypeId: unitType.id,
                    name: data['name'],
                    maxCapacity: data['maxCapacity'],
                    icon: data['icon'],
                    systemCommissionRate: data['systemCommissionRate'],
                    isHasAdults: data['isHasAdults'],
                    isHasChildren: data['isHasChildren'],
                    isMultiDays: data['isMultiDays'],
                    isRequiredToDetermineTheHour:
                        data['isRequiredToDetermineTheHour'],
                  ),
                );
          } else {
            parentContext.read<UnitTypesBloc>().add(
                  CreateUnitTypeEvent(
                    propertyTypeId: _selectedPropertyTypeId!,
                    name: data['name'],
                    maxCapacity: data['maxCapacity'],
                    icon: data['icon'],
                    systemCommissionRate: data['systemCommissionRate'],
                    isHasAdults: data['isHasAdults'],
                    isHasChildren: data['isHasChildren'],
                    isMultiDays: data['isMultiDays'],
                    isRequiredToDetermineTheHour:
                        data['isRequiredToDetermineTheHour'],
                  ),
                );
          }
        },
      ),
    );
  }

  void _showFieldModal({dynamic field}) {
    if (_selectedUnitTypeId == null) {
      _showErrorMessage('يرجى اختيار نوع وحدة أولاً');
      return;
    }

    final parentContext = context;
    showDialog(
      fullscreenDialog: true,
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (context) => UnitTypeFieldModal(
        field: field,
        unitTypeId: _selectedUnitTypeId!,
        onSave: (data) {
          if (field != null) {
            parentContext.read<UnitTypeFieldsBloc>().add(
                  UpdateFieldEvent(
                    fieldId: field.fieldId,
                    fieldData: data,
                  ),
                );
          } else {
            parentContext.read<UnitTypeFieldsBloc>().add(
                  CreateFieldEvent(
                    unitTypeId: _selectedUnitTypeId!,
                    fieldData: data,
                  ),
                );
          }
        },
      ),
    );
  }

  void _confirmDelete({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      useRootNavigator: false,
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
                  title,
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
                          onConfirm();
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _FuturisticBackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;

  _FuturisticBackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    paint.color = AppTheme.primaryBlue.withOpacity(0.05);
    const spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    final center = Offset(size.width / 2, size.height / 2);
    paint.color = AppTheme.primaryBlue.withOpacity(0.03 * glowIntensity);

    for (int i = 0; i < 3; i++) {
      final radius = 200.0 + i * 100;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation + i * 0.5);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawCircle(center, radius, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
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
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.darkBorder.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.error,
                            AppTheme.error.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
