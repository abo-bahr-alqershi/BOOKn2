// lib/features/admin_units/presentation/pages/edit_unit_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/money.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/pricing_method.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/unit.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/widgets/dynamic_fields_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/unit_form/unit_form_bloc.dart';
import '../bloc/unit_details/unit_details_bloc.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/widgets/unit_image_gallery.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_images/unit_images_bloc.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_images/unit_images_event.dart'
    hide UpdateUnitImageEvent;
import 'package:get_it/get_it.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:intl/intl.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:bookn_cp_app/features/auth/domain/entities/user.dart' as domain;

class EditUnitPage extends StatefulWidget {
  final String unitId;

  const EditUnitPage({
    super.key,
    required this.unitId,
  });

  @override
  State<EditUnitPage> createState() => _EditUnitPageState();
}

class _EditUnitPageState extends State<EditUnitPage>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _loadingRotation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _featuresController = TextEditingController();
  final _cancellationDaysController = TextEditingController();

  // State
  String? _selectedPropertyId;
  String? _selectedUnitTypeId;
  bool _isHasAdults = false;
  bool _isHasChildren = false;
  int _currentStep = 0;
  int _adultCapacity = 0;
  int _childrenCapacity = 0;
  String _pricingMethod = 'per_night';
  Map<String, dynamic> _dynamicFieldValues = {};
  final Map<String, dynamic> _originalDynamicFieldValues =
      {}; // حفظ القيم الأصلية
  String? _selectedPropertyName;
  final GlobalKey<UnitImageGalleryState> _galleryKey = GlobalKey();
  bool _isOwner = false;

  // Edit specific state
  Unit? _originalUnit;
  bool _isDataLoaded = false;
  bool _hasChanges = false;
  List<String> _existingImages = [];
  List<String> _originalImages = []; // حفظ الصور الأصلية
  bool _imagesChanged = false; // تتبع تغييرات الصور
  bool _allowsCancellation = true;
  int? _cancellationWindowDays;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Initialize form in edit mode
    context
        .read<UnitFormBloc>()
        .add(InitializeFormEvent(unitId: widget.unitId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      domain.User? user;
      if (authState is AuthAuthenticated) user = authState.user;
      if (authState is AuthLoginSuccess) user = authState.user;
      if (authState is AuthProfileUpdateSuccess) user = authState.user;
      if (user != null && user.isOwner) {
        setState(() {
          _isOwner = true;
        });
      }
      _loadUnitData();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _loadingRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.linear,
    ));
  }

  void _loadUnitData() {
    // Load unit details first
    context
        .read<UnitDetailsBloc>()
        .add(LoadUnitDetailsEvent(unitId: widget.unitId));
  }

  void _populateFormWithUnitData(Unit unit) {
    if (_isDataLoaded) return;

    setState(() {
      _originalUnit = unit;
      _isDataLoaded = true;

      // Populate text controllers
      _nameController.text = unit.name;
      _descriptionController.text = unit.customFeatures;
      _priceController.text = unit.basePrice.amount.toString();

      // Extract features from customFeatures if it's comma-separated
      _featuresController.text = unit.customFeatures;

      // Set property and unit type
      _selectedPropertyId = unit.propertyId;
      _selectedPropertyName = unit.propertyName;
      _selectedUnitTypeId = unit.unitTypeId;

      // Set capacities
      _adultCapacity = unit.adultsCapacity ?? unit.maxCapacity;
      _childrenCapacity = unit.childrenCapacity ?? 0;
      _isHasAdults = unit.adultsCapacity != null && unit.adultsCapacity! > 0;
      _isHasChildren =
          unit.childrenCapacity != null && unit.childrenCapacity! > 0;

      // Set pricing method
      _pricingMethod = _getPricingMethodString(unit.pricingMethod);

      // تحميل قيم الحقول الديناميكية من كلا المصدرين
      _loadDynamicFieldValues(unit);

      // Set existing images
      _existingImages = List<String>.from(unit.images ?? []);
      _originalImages = List<String>.from(unit.images ?? []);
      // Cancellation
      _allowsCancellation = unit.allowsCancellation;
      _cancellationWindowDays = unit.cancellationWindowDays;
      _cancellationDaysController.text = _cancellationWindowDays != null
          ? _cancellationWindowDays.toString()
          : '';
    });

    // تحديث UnitFormBloc بجميع البيانات
    _updateFormBloc();

    // Load unit type fields
    if (unit.unitTypeId.isNotEmpty) {
      context.read<UnitFormBloc>().add(
            UnitTypeSelectedEvent(unitTypeId: unit.unitTypeId),
          );
    }

    // Start animation after data is loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  void _loadDynamicFieldValues(Unit unit) {
    // تحميل من fieldValues
    for (var fieldValue in unit.fieldValues) {
      _dynamicFieldValues[fieldValue.fieldId] = fieldValue.fieldValue;
      _originalDynamicFieldValues[fieldValue.fieldId] = fieldValue.fieldValue;
    }

    // تحميل من dynamicFields (FieldGroupWithValues)
    for (var group in unit.dynamicFields) {
      for (var field in group.fieldValues) {
        _dynamicFieldValues[field.fieldId] = field.fieldValue;
        _originalDynamicFieldValues[field.fieldId] = field.fieldValue;
      }
    }
  }

  void _updateFormBloc() {
    // تحديث جميع الحقول في البلوك
    _updateUnitName();
    _updateDescription();
    _updatePricing();
    _updateFeatures();
    _updateCapacity();
    _updateUnitImage();
    _updateDynamicFields();
    _updateCancellationPolicy();
  }

  String _getPricingMethodString(PricingMethod method) {
    switch (method) {
      case PricingMethod.daily:
        return 'daily';
      case PricingMethod.weekly:
        return 'weekly';
      case PricingMethod.monthly:
        return 'monthly';
      case PricingMethod.hourly:
        return 'hourly';
      default:
        return 'daily';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _loadingAnimationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _featuresController.dispose();
    _cancellationDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocListener<UnitDetailsBloc, UnitDetailsState>(
        listener: (context, state) {
          if (state is UnitDetailsLoaded && !_isDataLoaded) {
            _populateFormWithUnitData(state.unit);
          } else if (state is UnitDetailsError) {
            _showErrorMessage(state.message);
          }
        },
        child: BlocListener<UnitFormBloc, UnitFormState>(
          listener: (context, state) {
            if (state is UnitFormSubmitted) {
              _showSuccessMessage('تم تحديث الوحدة بنجاح');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  context.pop(true); // Return true to indicate success
                }
              });
            } else if (state is UnitFormError) {
              _showErrorMessage(state.message);
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Stack(
              children: [
                // Animated Background
                _buildAnimatedBackground(),

                // Main Content or Loading
                SafeArea(
                  child: !_isDataLoaded
                      ? _buildLoadingState()
                      : Column(
                          children: [
                            // Header
                            _buildHeader(),

                            // Progress Indicator
                            _buildProgressIndicator(),

                            // Form Content
                            Expanded(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildFormContent(),
                                ),
                              ),
                            ),

                            // Action Buttons
                            _buildActionButtons(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _glowController,
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
            painter: _EditUnitBackgroundPainter(
              glowIntensity: _glowController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingRotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingRotation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.3),
                        AppTheme.primaryPurple.withOpacity(0.2),
                        AppTheme.primaryViolet.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.darkBackground,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.home_work_rounded,
                          color: AppTheme.primaryBlue,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'جاري تحميل بيانات الوحدة...',
              style: AppTextStyles.heading3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الرجاء الانتظار',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
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
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withOpacity(0.5),
                    AppTheme.darkSurface.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'تعديل الوحدة',
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_hasChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.warning.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'محرر',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _originalUnit?.name ?? 'قم بتعديل البيانات المطلوبة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Reset Button
          if (_hasChanges)
            GestureDetector(
              onTap: _resetChanges,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.error,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = [
      'المعلومات الأساسية',
      'السعة والتسعير',
      'المميزات والصور',
      'المراجعة'
    ];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          final isModified = _hasChangesInStep(index);

          return Expanded(
            child: Row(
              children: [
                // Step Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isActive ? AppTheme.primaryGradient : null,
                    color: !isActive
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isModified
                          ? AppTheme.warning.withOpacity(0.5)
                          : isActive
                              ? AppTheme.primaryBlue.withOpacity(0.5)
                              : AppTheme.darkBorder.withOpacity(0.3),
                      width: isModified ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: isModified
                                  ? AppTheme.warning.withOpacity(0.3)
                                  : AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            isModified
                                ? Icons.edit_rounded
                                : Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  isActive ? Colors.white : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? isModified
                                ? LinearGradient(colors: [
                                    AppTheme.warning,
                                    AppTheme.warning.withOpacity(0.5)
                                  ])
                                : AppTheme.primaryGradient
                            : null,
                        color: !isCompleted
                            ? AppTheme.darkBorder.withOpacity(0.2)
                            : null,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFormContent() {
    return BlocBuilder<UnitFormBloc, UnitFormState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          onChanged: () {
            setState(() {
              _hasChanges = _checkForChanges();
            });
          },
          child: IndexedStack(
            index: _currentStep,
            children: [
              _buildBasicInfoStep(state),
              _buildCapacityPricingStep(state),
              _buildFeaturesStep(state),
              _buildReviewStep(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoStep(UnitFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Change Indicator
          if (_originalUnit != null)
            _buildOriginalValueIndicator(
              'اسم الوحدة الأصلي',
              _originalUnit!.name,
              _nameController.text != _originalUnit!.name,
            ),

          // Unit Name
          _buildInputField(
            controller: _nameController,
            label: 'اسم الوحدة',
            hint: 'أدخل اسم الوحدة',
            icon: Icons.home_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال اسم الوحدة';
              }
              return null;
            },
            onChanged: (value) => _updateUnitName(),
          ),

          const SizedBox(height: 20),

          if (!_isOwner)
            _buildReadOnlyField(
              label: 'العقار',
              value: _selectedPropertyName ?? 'غير محدد',
              icon: Icons.home_work_outlined,
            ),

          const SizedBox(height: 20),

          // Unit Type Selector (Read-only in edit mode)
          _buildReadOnlyField(
            label: 'نوع الوحدة',
            value: _originalUnit?.unitTypeName ?? 'غير محدد',
            icon: Icons.apartment_rounded,
          ),

          const SizedBox(height: 20),

          // Description
          if (_originalUnit != null &&
              _descriptionController.text != _originalUnit!.customFeatures)
            _buildOriginalValueIndicator(
              'الوصف الأصلي',
              _originalUnit!.customFeatures.isEmpty
                  ? 'لا يوجد'
                  : _originalUnit!.customFeatures,
              true,
            ),

          _buildInputField(
            controller: _descriptionController,
            label: 'الوصف',
            hint: 'أدخل وصف الوحدة',
            icon: Icons.description_rounded,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال وصف الوحدة';
              }
              return null;
            },
            onChanged: (value) => _updateDescription(),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityPricingStep(UnitFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isHasAdults || _isHasChildren) ...[
            // Capacity Section
            Text(
              'السعة الاستيعابية',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                if (_isHasAdults) ...[
                  Expanded(
                    child: _buildCapacityCounter(
                      label: 'البالغين',
                      value: _adultCapacity,
                      originalValue: _originalUnit?.adultsCapacity ??
                          _originalUnit?.maxCapacity ??
                          0,
                      icon: Icons.person,
                      onIncrement: () {
                        setState(() => _adultCapacity++);
                        _updateCapacity();
                      },
                      onDecrement: () {
                        if (_adultCapacity > 1) {
                          setState(() => _adultCapacity--);
                          _updateCapacity();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (_isHasChildren) ...[
                  Expanded(
                    child: _buildCapacityCounter(
                      label: 'الأطفال',
                      value: _childrenCapacity,
                      originalValue: _originalUnit?.childrenCapacity ?? 0,
                      icon: Icons.child_care,
                      onIncrement: () {
                        setState(() => _childrenCapacity++);
                        _updateCapacity();
                      },
                      onDecrement: () {
                        if (_childrenCapacity > 0) {
                          setState(() => _childrenCapacity--);
                          _updateCapacity();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 30),
          ],

          // Pricing Section
          Text(
            'التسعير',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_originalUnit != null &&
              double.tryParse(_priceController.text) !=
                  _originalUnit!.basePrice.amount)
            _buildOriginalValueIndicator(
              'السعر الأصلي',
              _originalUnit!.basePrice.displayAmount,
              true,
            ),

          _buildInputField(
            controller: _priceController,
            label: 'السعر الأساسي',
            hint: 'أدخل السعر الأساسي',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال السعر';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'السعر غير صحيح';
              }
              return null;
            },
            onChanged: (value) {
              _updatePricing();
            },
          ),

          const SizedBox(height: 16),

          // Pricing Method Selector
          _buildPricingMethodSelector(),

          const SizedBox(height: 24),
          // Cancellation Policy
          Text(
            'سياسة الإلغاء',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                activeThumbColor: AppTheme.success,
                value: _allowsCancellation,
                onChanged: (v) {
                  setState(() {
                    _allowsCancellation = v;
                    if (!v) {
                      _cancellationWindowDays = null;
                      _cancellationDaysController.text = '';
                    }
                    _hasChanges = _checkForChanges();
                  });
                  _updateCancellationPolicy();
                },
              ),
              const SizedBox(width: 8),
              Text(
                'السماح بإلغاء الحجز',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _allowsCancellation ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !_allowsCancellation,
              child: _buildInputField(
                controller: _cancellationDaysController,
                label: 'أيام نافذة الإلغاء قبل الوصول',
                hint: 'مثال: 2',
                icon: Icons.event_busy,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (!_allowsCancellation) return null;
                  if (value == null || value.isEmpty) return null;
                  final v = int.tryParse(value);
                  if (v == null || v < 0) return 'أدخل رقم صالح (0 أو أكثر)';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _cancellationWindowDays = int.tryParse(value);
                    _hasChanges = _checkForChanges();
                  });
                  _updateCancellationPolicy();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesStep(UnitFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المميزات',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildInputField(
            controller: _featuresController,
            label: 'المميزات المتاحة',
            hint: 'أدخل المميزات مفصولة بفاصلة (مثال: واي فاي، تكييف، مطبخ)',
            icon: Icons.stars_rounded,
            maxLines: 3,
            onChanged: (value) {
              _updateFeatures();
            },
          ),

          const SizedBox(height: 30),

          Text(
            'صور الوحدة',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          UnitImageGallery(
            key: _galleryKey,
            unitId: widget.unitId,
            maxImages: 10,
            onImagesChanged: (images) {
              setState(() {
                _existingImages = images.map((img) => img.url).toList();
                _imagesChanged =
                    !_areImagesEqual(_existingImages, _originalImages);
                _updateUnitImage();
              });
            },
          ),

          // Dynamic Fields Section - عرض الحقول الديناميكية إذا توفرت
          if (state is UnitFormReady && state.unitTypeFields.isNotEmpty) ...[
            const SizedBox(height: 30),
            DynamicFieldsWidget(
              fields: state.unitTypeFields,
              values: _dynamicFieldValues,
              onChanged: (values) {
                setState(() {
                  _dynamicFieldValues = values;
                  _hasChanges = _checkForChanges(); // تحديث حالة التغييرات
                });
                _updateDynamicFields();
              },
              isReadOnly: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewStep(UnitFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'مراجعة التغييرات',
                style: AppTextStyles.heading2.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (_hasChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning,
                        AppTheme.warning.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'يوجد تغييرات',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Changes Summary
          if (_hasChanges) _buildChangesSummary(),

          const SizedBox(height: 20),

          _buildReviewCard(
            title: 'المعلومات الأساسية',
            items: [
              {
                'label': 'الاسم',
                'value': _nameController.text,
                'changed': _nameController.text != _originalUnit?.name
              },
              {
                'label': 'العقار',
                'value': _selectedPropertyName ?? '',
                'changed': false
              },
              {
                'label': 'النوع',
                'value': _originalUnit?.unitTypeName ?? '',
                'changed': false
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'السعة والتسعير',
            items: [
              {
                'label': 'البالغين',
                'value': '$_adultCapacity',
                'changed': _adultCapacity !=
                    (_originalUnit?.adultsCapacity ??
                        _originalUnit?.maxCapacity)
              },
              {
                'label': 'الأطفال',
                'value': '$_childrenCapacity',
                'changed':
                    _childrenCapacity != (_originalUnit?.childrenCapacity ?? 0)
              },
              {
                'label': 'السعر',
                'value': '${_priceController.text} ريال',
                'changed': double.tryParse(_priceController.text) !=
                    _originalUnit?.basePrice.amount
              },
              {
                'label': 'طريقة التسعير',
                'value': _getPricingMethodText(),
                'changed': _pricingMethod !=
                    _getPricingMethodString(_originalUnit!.pricingMethod)
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'المميزات والصور',
            items: [
              {
                'label': 'المميزات',
                'value': _featuresController.text.isEmpty
                    ? 'لا توجد'
                    : _featuresController.text,
                'changed':
                    _featuresController.text != _originalUnit?.customFeatures
              },
              {
                'label': 'عدد الصور',
                'value': '${_existingImages.length} صورة',
                'changed': _imagesChanged
              },
            ],
          ),

          const SizedBox(height: 16),

          // Cancellation policy review with change highlighting
          _buildReviewCard(
            title: 'سياسة الإلغاء',
            items: [
              {
                'label': 'السماح بإلغاء الحجز',
                'value': _allowsCancellation ? 'نعم' : 'لا',
                'changed': _originalUnit == null
                    ? false
                    : (_allowsCancellation !=
                        _originalUnit!.allowsCancellation),
              },
              {
                'label': 'نافذة الإلغاء (أيام)',
                'value': _allowsCancellation
                    ? (_cancellationDaysController.text.isEmpty
                        ? 'غير محدد'
                        : _cancellationDaysController.text)
                    : 'غير متاح',
                'changed': _originalUnit == null
                    ? false
                    : ((_originalUnit!.cancellationWindowDays ?? -1)
                            .toString() !=
                        (_cancellationDaysController.text.isEmpty
                            ? '-1'
                            : _cancellationDaysController.text)),
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'الوصف',
            items: [
              {
                'label': 'الوصف',
                'value': _descriptionController.text,
                'changed':
                    _descriptionController.text != _originalUnit?.customFeatures
              },
            ],
          ),

          // عرض الحقول الديناميكية المعدلة
          if (state is UnitFormReady && state.unitTypeFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDynamicFieldsReviewCard(state.unitTypeFields),
          ],
        ],
      ),
    );
  }

  // إضافة قسم مراجعة الحقول الديناميكية
  Widget _buildDynamicFieldsReviewCard(List<dynamic> fields) {
    final changedFields = fields.where((field) {
      final currentValue = _dynamicFieldValues[field.fieldId];
      final originalValue = _originalDynamicFieldValues[field.fieldId];
      return currentValue != originalValue;
    }).toList();

    final hasChanges = changedFields.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasChanges
              ? [
                  AppTheme.warning.withOpacity(0.05),
                  AppTheme.darkCard.withOpacity(0.4),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.5),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasChanges
              ? AppTheme.warning.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: hasChanges
                      ? LinearGradient(colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.7)
                        ])
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.dynamic_form_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الحقول الإضافية',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasChanges ? AppTheme.warning : AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${changedFields.length} تغيير',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...fields.map((field) {
            final currentValue = _dynamicFieldValues[field.fieldId];
            final originalValue = _originalDynamicFieldValues[field.fieldId];
            final isChanged = currentValue != originalValue;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isChanged)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4, top: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Icon(
                        _getFieldIcon(field.fieldTypeId),
                        size: 14,
                        color: isChanged
                            ? AppTheme.warning.withOpacity(0.7)
                            : AppTheme.textMuted.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        field.displayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              isChanged ? AppTheme.warning : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatFieldValue(field, currentValue),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isChanged &&
                            originalValue != null &&
                            originalValue.toString().isNotEmpty)
                          Text(
                            'كان: ${_formatFieldValue(field, originalValue)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.7),
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                            textAlign: TextAlign.end,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // دالة مساعدة للحصول على أيقونة الحقل
  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields_rounded;
      case 'textarea':
        return Icons.subject_rounded;
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

  // دالة مساعدة لتنسيق قيمة الحقل للعرض
  String _formatFieldValue(dynamic field, dynamic value) {
    if (value == null || value.toString().isEmpty) return 'غير محدد';

    switch (field.fieldTypeId) {
      case 'boolean':
        final boolValue = value.toString().toLowerCase();
        return (boolValue == 'true' || boolValue == '1' || boolValue == 'yes')
            ? 'نعم'
            : 'لا';

      case 'currency':
        if (value is num) {
          return '${value.toStringAsFixed(2)} ريال';
        }
        return '$value ريال';

      case 'date':
        if (value is String) {
          try {
            final date = DateTime.parse(value);
            return DateFormat('dd/MM/yyyy').format(date);
          } catch (_) {
            return value;
          }
        } else if (value is DateTime) {
          return DateFormat('dd/MM/yyyy').format(value);
        }
        return value.toString();

      case 'multiselect':
        if (value is List) {
          return value.join('، ');
        }
        return value.toString();

      default:
        return value.toString();
    }
  }

  Widget _buildOriginalValueIndicator(
      String label, String value, bool isChanged) {
    if (!isChanged) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.3),
                AppTheme.darkCard.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.textMuted.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textMuted.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangesSummary() {
    final changes = _getChangedFields();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.1),
            AppTheme.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                color: AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ملخص التغييرات (${changes.length})',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...changes.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            change['field']!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'من: ${change['oldValue']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'إلى: ${change['newValue']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.success,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCapacityCounter({
    required String label,
    required int value,
    required int originalValue,
    required IconData icon,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final hasChanged = value != originalValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasChanged
              ? [
                  AppTheme.warning.withOpacity(0.1),
                  AppTheme.warning.withOpacity(0.05),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.5),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasChanged
              ? AppTheme.warning.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon,
                  color: hasChanged ? AppTheme.warning : AppTheme.primaryBlue,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              if (hasChanged) ...[
                const Spacer(),
                Text(
                  'الأصل: $originalValue',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDecrement();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ),
              ),
              Text(
                '$value',
                style: AppTextStyles.heading3.copyWith(
                  color: hasChanged ? AppTheme.warning : AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onIncrement();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    final hasChanges = items.any((item) => item['changed'] == true);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasChanges
              ? [
                  AppTheme.warning.withOpacity(0.05),
                  AppTheme.darkCard.withOpacity(0.4),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.5),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasChanges
              ? AppTheme.warning.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasChanges ? AppTheme.warning : AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'معدّل',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (item['changed'] == true)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          item['label']!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: item['changed'] == true
                                ? AppTheme.warning
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        item['value']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: item['changed'] == true
                              ? AppTheme.textWhite
                              : AppTheme.textWhite,
                          fontWeight: item['changed'] == true
                              ? FontWeight.w600
                              : FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // تحسين دالة التحقق من التغييرات
  bool _checkForChanges() {
    if (_originalUnit == null) return false;

    // التحقق من الحقول الأساسية
    final basicFieldsChanged = _nameController.text != _originalUnit!.name ||
        _descriptionController.text != _originalUnit!.customFeatures ||
        double.tryParse(_priceController.text) !=
            _originalUnit!.basePrice.amount ||
        _adultCapacity !=
            (_originalUnit!.adultsCapacity ?? _originalUnit!.maxCapacity) ||
        _childrenCapacity != (_originalUnit!.childrenCapacity ?? 0) ||
        _pricingMethod !=
            _getPricingMethodString(_originalUnit!.pricingMethod) ||
        _featuresController.text != _originalUnit!.customFeatures;

    // التحقق من تغييرات الصور
    final imagesChanged =
        _imagesChanged || !_areImagesEqual(_existingImages, _originalImages);

    // التحقق من تغييرات الحقول الديناميكية
    final dynamicFieldsChanged = _checkDynamicFieldsChanges();

    // التحقق من تغييرات سياسة الإلغاء
    final cancellationChanged =
        _allowsCancellation != _originalUnit!.allowsCancellation ||
            ((_cancellationWindowDays ?? -1) !=
                (_originalUnit!.cancellationWindowDays ?? -1));

    return basicFieldsChanged || imagesChanged || dynamicFieldsChanged || cancellationChanged;
  }

  // دالة للتحقق من تغييرات الحقول الديناميكية
  bool _checkDynamicFieldsChanges() {
    // التحقق من كل حقل ديناميكي
    for (final entry in _dynamicFieldValues.entries) {
      final originalValue = _originalDynamicFieldValues[entry.key];
      if (entry.value != originalValue) {
        return true;
      }
    }

    // التحقق من الحقول التي كانت موجودة وحذفت
    for (final entry in _originalDynamicFieldValues.entries) {
      if (!_dynamicFieldValues.containsKey(entry.key)) {
        return true;
      }
    }

    return false;
  }

  // دالة للمقارنة بين قوائم الصور
  bool _areImagesEqual(List<String> current, List<String> original) {
    if (current.length != original.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != original[i]) return false;
    }
    return true;
  }

  bool _hasChangesInStep(int step) {
    if (_originalUnit == null) return false;

    switch (step) {
      case 0: // Basic Info
        return _nameController.text != _originalUnit!.name ||
            _descriptionController.text != _originalUnit!.customFeatures;
      case 1: // Capacity & Pricing
        return double.tryParse(_priceController.text) !=
                _originalUnit!.basePrice.amount ||
            _adultCapacity !=
                (_originalUnit!.adultsCapacity ?? _originalUnit!.maxCapacity) ||
            _childrenCapacity != (_originalUnit!.childrenCapacity ?? 0) ||
            _pricingMethod !=
                _getPricingMethodString(_originalUnit!.pricingMethod) ||
            _allowsCancellation != _originalUnit!.allowsCancellation ||
            ((_cancellationWindowDays ?? -1) !=
                (_originalUnit!.cancellationWindowDays ?? -1));
      case 2: // Features, Images & Dynamic Fields
        return _featuresController.text != _originalUnit!.customFeatures ||
            _imagesChanged ||
            _checkDynamicFieldsChanges();
      default:
        return false;
    }
  }

  List<Map<String, String>> _getChangedFields() {
    final changes = <Map<String, String>>[];
    if (_originalUnit == null) return changes;

    if (_nameController.text != _originalUnit!.name) {
      changes.add({
        'field': 'اسم الوحدة',
        'oldValue': _originalUnit!.name,
        'newValue': _nameController.text,
      });
    }

    if (_descriptionController.text != _originalUnit!.customFeatures) {
      changes.add({
        'field': 'الوصف',
        'oldValue': _originalUnit!.customFeatures.isEmpty
            ? 'لا يوجد'
            : _originalUnit!.customFeatures,
        'newValue': _descriptionController.text,
      });
    }

    if (double.tryParse(_priceController.text) !=
        _originalUnit!.basePrice.amount) {
      changes.add({
        'field': 'السعر',
        'oldValue': _originalUnit!.basePrice.displayAmount,
        'newValue':
            '${_priceController.text} ${_originalUnit!.basePrice.currency}',
      });
    }

    if (_adultCapacity !=
        (_originalUnit!.adultsCapacity ?? _originalUnit!.maxCapacity)) {
      changes.add({
        'field': 'سعة البالغين',
        'oldValue':
            '${_originalUnit!.adultsCapacity ?? _originalUnit!.maxCapacity}',
        'newValue': '$_adultCapacity',
      });
    }

    if (_childrenCapacity != (_originalUnit!.childrenCapacity ?? 0)) {
      changes.add({
        'field': 'سعة الأطفال',
        'oldValue': '${_originalUnit!.childrenCapacity ?? 0}',
        'newValue': '$_childrenCapacity',
      });
    }

    if (_imagesChanged) {
      changes.add({
        'field': 'الصور',
        'oldValue': '${_originalImages.length} صورة',
        'newValue': '${_existingImages.length} صورة',
      });
    }

    // إضافة تغييرات الحقول الديناميكية
    for (final entry in _dynamicFieldValues.entries) {
      final originalValue = _originalDynamicFieldValues[entry.key];
      if (entry.value != originalValue) {
        // نحتاج للحصول على معلومات الحقل لعرض الاسم
        changes.add({
          'field': 'حقل ديناميكي',
          'oldValue': originalValue?.toString() ?? 'غير محدد',
          'newValue': entry.value?.toString() ?? 'غير محدد',
        });
      }
    }

    return changes;
  }

  void _resetChanges() {
    if (_originalUnit == null) return;

    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => _ResetConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);

          // إعادة تعيين جميع القيم
          setState(() {
            _nameController.text = _originalUnit!.name;
            _descriptionController.text = _originalUnit!.customFeatures;
            _priceController.text = _originalUnit!.basePrice.amount.toString();
            _featuresController.text = _originalUnit!.customFeatures;
            _adultCapacity =
                _originalUnit!.adultsCapacity ?? _originalUnit!.maxCapacity;
            _childrenCapacity = _originalUnit!.childrenCapacity ?? 0;
            _pricingMethod =
                _getPricingMethodString(_originalUnit!.pricingMethod);
            _existingImages = List<String>.from(_originalImages);
            _imagesChanged = false;

            // إعادة تعيين سياسة الإلغاء
            _allowsCancellation = _originalUnit!.allowsCancellation;
            _cancellationWindowDays = _originalUnit!.cancellationWindowDays;
            _cancellationDaysController.text = _cancellationWindowDays != null
                ? _cancellationWindowDays.toString()
                : '';

            // إعادة تعيين الحقول الديناميكية
            _dynamicFieldValues =
                Map<String, dynamic>.from(_originalDynamicFieldValues);

            _hasChanges = false;
          });

          // تحديث البلوك
          _updateFormBloc();

          _showSuccessMessage('تم استرجاع البيانات الأصلية');
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _UnsavedChangesDialog(),
    );

    return result ?? false;
  }

  // Keep all the other methods from original file (unchanged)
  Widget _buildPricingMethodSelector() {
    final methods = [
      {'value': 'daily', 'label': 'لليلة الواحدة'},
      {'value': 'weekly', 'label': 'للأسبوع'},
      {'value': 'monthly', 'label': 'للشهر'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة التسعير',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: methods.map((method) {
            final isSelected = _pricingMethod == method['value'];
            final originalMethod = _originalUnit != null
                ? _getPricingMethodString(_originalUnit!.pricingMethod)
                : '';
            final hasChanged = _originalUnit != null &&
                method['value'] == _pricingMethod &&
                _pricingMethod != originalMethod;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _pricingMethod = method['value']!;
                });
                _updatePricing();
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? hasChanged
                          ? LinearGradient(colors: [
                              AppTheme.warning,
                              AppTheme.warning.withOpacity(0.7)
                            ])
                          : AppTheme.primaryGradient
                      : null,
                  color: isSelected ? null : AppTheme.darkCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? hasChanged
                            ? AppTheme.warning.withOpacity(0.5)
                            : AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  method['label']!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.5),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: maxLines == 1
                  ? Icon(
                      icon,
                      color: AppTheme.primaryBlue.withOpacity(0.7),
                      size: 20,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: GestureDetector(
                onTap: _previousStep,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkSurface.withOpacity(0.5),
                        AppTheme.darkSurface.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'السابق',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next/Submit Button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: GestureDetector(
              onTap: _currentStep < 3 ? _nextStep : _submitForm,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: _hasChanges
                      ? LinearGradient(colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.8)
                        ])
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _hasChanges
                          ? AppTheme.warning.withOpacity(0.3)
                          : AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: BlocBuilder<UnitFormBloc, UnitFormState>(
                    builder: (context, state) {
                      if (state is UnitFormLoading) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentStep == 3 && _hasChanges)
                            const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          if (_currentStep == 3 && _hasChanges)
                            const SizedBox(width: 8),
                          Text(
                            _currentStep < 3
                                ? 'التالي'
                                : _hasChanges
                                    ? 'حفظ التغييرات'
                                    : 'لا توجد تغييرات',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods (same as create but with modifications for edit)
  void _updateCapacity() {
    context.read<UnitFormBloc>().add(
          UpdateCapacityEvent(
            adultCapacity: _adultCapacity,
            childrenCapacity: _childrenCapacity,
          ),
        );
  }

  void _updateUnitImage() {
    context.read<UnitFormBloc>().add(
          UpdateUnitImageEvent(
            images: _existingImages,
          ),
        );
  }

  void _updatePricing() {
    if (_priceController.text.isNotEmpty) {
      final price = double.tryParse(_priceController.text);
      if (price != null && price > 0) {
        final money = Money(
          amount: price,
          currency: _originalUnit?.basePrice.currency ?? 'YER',
          formattedAmount: price.toString(),
        );

        final pricingMethod = _getPricingMethodEnum();

        context.read<UnitFormBloc>().add(
              UpdatePricingEvent(
                basePrice: money,
                pricingMethod: pricingMethod,
              ),
            );
      }
    }
  }

  void _updateFeatures() {
    context.read<UnitFormBloc>().add(
          UpdateFeaturesEvent(features: _featuresController.text),
        );
  }

  void _updateUnitName() {
    context.read<UnitFormBloc>().add(
          UpdateUnitNameEvent(name: _nameController.text),
        );
  }

  void _updateDescription() {
    context.read<UnitFormBloc>().add(
          UpdateDescriptionEvent(description: _descriptionController.text),
        );
  }

  void _updateDynamicFields() {
    context.read<UnitFormBloc>().add(
          UpdateDynamicFieldsEvent(values: _dynamicFieldValues),
        );
  }

  String _getPricingMethodText() {
    switch (_pricingMethod) {
      case 'daily':
        return 'لليوم الواحد';
      case 'weekly':
        return 'للأسبوع';
      case 'monthly':
        return 'للشهر';
      default:
        return 'للساعة';
    }
  }

  PricingMethod _getPricingMethodEnum() {
    switch (_pricingMethod) {
      case 'daily':
        return PricingMethod.daily;
      case 'weekly':
        return PricingMethod.weekly;
      case 'monthly':
        return PricingMethod.monthly;
      default:
        return PricingMethod.hourly;
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      if (_hasChanges) {
        _onWillPop().then((canPop) {
          if (canPop) {
            context.pop();
          }
        });
      } else {
        context.pop();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      bool isValid = true;

      if (_currentStep == 0) {
        isValid = _validateBasicInfo();
      } else if (_currentStep == 1) {
        isValid = _validateCapacityPricing();
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showErrorMessage('الرجاء ملء جميع الحقول المطلوبة');
      return false;
    }
    return true;
  }

  bool _validateCapacityPricing() {
    if (_priceController.text.isEmpty) {
      _showErrorMessage('الرجاء إدخال السعر');
      return false;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showErrorMessage('السعر غير صحيح');
      return false;
    }

    return true;
  }

  void _submitForm() {
    if (!_hasChanges) {
      _showInfoMessage('لا توجد تغييرات للحفظ');
      return;
    }

    if (_formKey.currentState!.validate()) {
      // تحديث جميع البيانات في البلوك
      _updateFormBloc();

      Future.delayed(const Duration(milliseconds: 100), () {
        context.read<UnitFormBloc>().add(SubmitFormEvent());
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
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

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _updateCancellationPolicy() {
    context.read<UnitFormBloc>().add(
          UpdateCancellationPolicyEvent(
            allowsCancellation: _allowsCancellation,
            // Normalize: when not allowed -> null; when allowed and empty -> null
            cancellationWindowDays: _allowsCancellation
                ? _cancellationWindowDays
                : null,
          ),
        );
  }
}

// Additional Dialogs for Edit Page (unchanged from original)
class _ResetConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _ResetConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
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
            color: AppTheme.warning.withOpacity(0.3),
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
                    AppTheme.warning.withOpacity(0.2),
                    AppTheme.warning.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppTheme.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'استرجاع البيانات الأصلية',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم التراجع عن جميع التغييرات\nواسترجاع البيانات الأصلية',
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
                            AppTheme.warning,
                            AppTheme.warning.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'استرجاع',
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

class _UnsavedChangesDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
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
              'تغييرات غير محفوظة',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لديك تغييرات غير محفوظة.\nهل تريد الخروج بدون حفظ؟',
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
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'البقاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'خروج بدون حفظ',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.error,
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

class _EditUnitBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _EditUnitBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw glowing orbs with edit theme
    paint.shader = RadialGradient(
      colors: [
        AppTheme.warning.withOpacity(0.1 * glowIntensity),
        AppTheme.warning.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.2),
      radius: 150,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      150,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryPurple.withOpacity(0.1 * glowIntensity),
        AppTheme.primaryPurple.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.7),
      radius: 100,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      100,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
