// lib/features/admin_units/presentation/pages/create_unit_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/money.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/pricing_method.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/unit_type.dart';
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
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/widgets/unit_image_gallery.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_images/unit_images_bloc.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_images/unit_images_event.dart'
    hide UpdateUnitImageEvent;
import 'package:get_it/get_it.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:bookn_cp_app/features/auth/domain/entities/user.dart' as domain;
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/properties/get_property_details_usecase.dart'
    as ap_uc_prop_details;

class CreateUnitPage extends StatefulWidget {
  const CreateUnitPage({super.key});

  @override
  State<CreateUnitPage> createState() => _CreateUnitPageState();
}

class _CreateUnitPageState extends State<CreateUnitPage>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _featuresController = TextEditingController();

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
  String? _selectedPropertyName;
  final GlobalKey<UnitImageGalleryState> _galleryKey = GlobalKey();
  List<String> _selectedLocalImages = [];
  String? _tempKey;
  bool _allowsCancellation = true;
  final _cancellationDaysController = TextEditingController();
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
    // Generate a temp key to allow pre-save image uploads
    _tempKey = DateTime.now().millisecondsSinceEpoch.toString();
    // Re-initialize form with tempKey
    context.read<UnitFormBloc>().add(InitializeFormEvent(tempKey: _tempKey));
    // Apply owner context (auto select property) if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyOwnerContextIfAny();
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

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  void _loadInitialData() {
    // Initialize form without unitId for create mode
    context.read<UnitFormBloc>().add(const InitializeFormEvent());
  }

  Future<void> _applyOwnerContextIfAny() async {
    final authState = context.read<AuthBloc>().state;
    domain.User? user;
    if (authState is AuthAuthenticated) user = authState.user;
    if (authState is AuthLoginSuccess) user = authState.user;
    if (authState is AuthProfileUpdateSuccess) user = authState.user;

    if (user == null) return;
    final isOwner = user.isOwner;
    final ownerPropId = user.propertyId;
    if (!isOwner || ownerPropId == null || ownerPropId.isEmpty) return;
    final u = user!;
    setState(() {
      _isOwner = true;
      _selectedPropertyId = ownerPropId;
      _selectedPropertyName = u.propertyName;
    });

    try {
      // Load property details to get property type id for unit types
      final getDetails =
          GetIt.instance<ap_uc_prop_details.GetPropertyDetailsUseCase>();
      final res = await getDetails(ap_uc_prop_details.GetPropertyDetailsParams(
        propertyId: ownerPropId,
        includeUnits: false,
      ));
      res.fold((_) {}, (prop) {
        context.read<UnitFormBloc>().add(
              PropertySelectedEvent(
                propertyId: ownerPropId,
                propertyTypeId: prop.typeId,
              ),
            );
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    // Purge temp images if user leaves without saving
    if (_tempKey != null) {
      try {
        GetIt.instance<ApiClient>().delete('/api/images/purge-temp',
            queryParameters: {'tempKey': _tempKey});
      } catch (_) {}
    }
    _animationController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _featuresController.dispose();
    _cancellationDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UnitFormBloc, UnitFormState>(
      listener: (context, state) {
        if (state is UnitFormSubmitted) {
          // If we have local images and unitId, trigger upload then pop
          final unitId = state.unitId;
          if (unitId != null && _selectedLocalImages.isNotEmpty) {
            try {
              // Use gallery helper to upload queued images
              _galleryKey.currentState?.uploadLocalImages(unitId);
            } catch (_) {}
          }
          // clear tempKey since entity is saved
          _tempKey = null;
          _showSuccessMessage('تم إنشاء الوحدة بنجاح');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.pop();
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

            // Main Content
            SafeArea(
              child: Column(
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
            painter: _CreateUnitBackgroundPainter(
              glowIntensity: _glowController.value,
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
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'إضافة وحدة جديدة',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بملء البيانات المطلوبة لإضافة الوحدة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
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
      'المميزات',
      'المراجعة'
    ];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

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
                      color: isActive
                          ? AppTheme.primaryBlue.withOpacity(0.5)
                          : AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
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
                        gradient: isCompleted ? AppTheme.primaryGradient : null,
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
            onChanged: (value) => _updateUnitName(), // أضف هذا
          ),

          const SizedBox(height: 20),

          // Property Selector (hidden for owners)
          if (!_isOwner) _buildPropertySelector(state),

          const SizedBox(height: 20),

          // Unit Type Selector
          _buildUnitTypeSelector(state),

          const SizedBox(height: 20),

          // Description
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
            onChanged: (value) => _updateDescription(), // أضف هذا
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
                    if (!v) _cancellationDaysController.text = '';
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
                  if (value == null || value.isEmpty) return null; // optional
                  final v = int.tryParse(value);
                  if (v == null || v < 0) return 'أدخل رقم صالح (0 أو أكثر)';
                  return null;
                },
                onChanged: (_) => _updateCancellationPolicy(),
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
            unitId: null,
            tempKey: _tempKey,
            maxImages: 10,
            onLocalImagesChanged: (paths) {
              setState(() {
                _selectedLocalImages = paths;
                _updateUnitImage();
              });
            },
          ),

          // Dynamic Fields Section - استخدام الويدجت المحدثة
          if (state is UnitFormReady && state.unitTypeFields.isNotEmpty) ...[
            const SizedBox(height: 30),
            DynamicFieldsWidget(
              fields: state.unitTypeFields,
              values: _dynamicFieldValues,
              onChanged: (values) {
                setState(() {
                  _dynamicFieldValues = values;
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
          Text(
            'مراجعة البيانات',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildReviewCard(
            title: 'المعلومات الأساسية',
            items: [
              {'label': 'الاسم', 'value': _nameController.text},
              {'label': 'العقار', 'value': _getPropertyName(state)},
              {'label': 'النوع', 'value': _getUnitTypeName(state)},
            ],
          ),

          const SizedBox(height: 16),

          if (_isHasAdults || _isHasChildren) ...[
            _buildReviewCard(
              title: 'السعة والتسعير',
              items: [
                if (_isHasAdults)
                  {'label': 'البالغين', 'value': '$_adultCapacity'},
                if (_isHasChildren)
                  {'label': 'الأطفال', 'value': '$_childrenCapacity'},
                {'label': 'السعر', 'value': '${_priceController.text} ريال'},
                {'label': 'طريقة التسعير', 'value': _getPricingMethodText()},
              ],
            ),
          ] else ...[
            _buildReviewCard(
              title: 'التسعير',
              items: [
                {'label': 'السعر', 'value': '${_priceController.text} ريال'},
                {'label': 'طريقة التسعير', 'value': _getPricingMethodText()},
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Cancellation policy review
          _buildReviewCard(
            title: 'سياسة الإلغاء',
            items: [
              {
                'label': 'السماح بإلغاء الحجز',
                'value': _allowsCancellation ? 'نعم' : 'لا',
              },
              {
                'label': 'نافذة الإلغاء (أيام)',
                'value': _allowsCancellation
                    ? (_cancellationDaysController.text.isEmpty
                        ? 'غير محدد'
                        : _cancellationDaysController.text)
                    : 'غير متاح',
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'المميزات',
            items: [
              {
                'label': 'المميزات',
                'value': _featuresController.text.isEmpty
                    ? 'لا توجد'
                    : _featuresController.text
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'الوصف',
            items: [
              {'label': 'الوصف', 'value': _descriptionController.text},
            ],
          ),

          // عرض الصور إذا وجدت
          if (_selectedLocalImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImagesReviewCard(),
          ],

          // عرض الحقول الديناميكية
          if (state is UnitFormReady &&
              state.unitTypeFields.isNotEmpty &&
              _dynamicFieldValues.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDynamicFieldsReviewCard(state.unitTypeFields),
          ],
        ],
      ),
    );
  }

  // إضافة دالة جديدة لعرض الحقول الديناميكية في المراجعة
  Widget _buildDynamicFieldsReviewCard(List<UnitTypeField> fields) {
    // فلترة الحقول التي لها قيم فقط
    final fieldsWithValues = fields.where((field) {
      final value = _dynamicFieldValues[field.fieldId];
      return value != null && value.toString().isNotEmpty;
    }).toList();

    if (fieldsWithValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
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
                'معلومات إضافية',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fieldsWithValues.map((field) {
            final value = _dynamicFieldValues[field.fieldId];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(
                          _getFieldIcon(field.fieldTypeId),
                          size: 14,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            field.displayName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatFieldValue(field, value),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  // إضافة دالة لعرض الصور في المراجعة
  Widget _buildImagesReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.info, AppTheme.info.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الصور',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                size: 14,
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'عدد الصور',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedLocalImages.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
  String _formatFieldValue(UnitTypeField field, dynamic value) {
    if (value == null) return 'غير محدد';

    switch (field.fieldTypeId) {
      case 'boolean':
        return value == true ? 'نعم' : 'لا';

      case 'currency':
        if (value is num) {
          return '${value.toStringAsFixed(2)} ريال';
        }
        return '$value ريال';

      case 'date':
        if (value is String) {
          try {
            final date = DateTime.parse(value);
            return '${date.day}/${date.month}/${date.year}';
          } catch (_) {
            return value;
          }
        } else if (value is DateTime) {
          return '${value.day}/${value.month}/${value.year}';
        }
        return value.toString();

      case 'multiselect':
        if (value is List) {
          return value.join('، ');
        }
        return value.toString();

      case 'select':
        return value.toString();

      case 'number':
        return value.toString();

      case 'phone':
        final phone = value.toString();
        if (phone.length == 10) {
          return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
        }
        return phone;

      case 'email':
        return value.toString().toLowerCase();

      case 'file':
      case 'image':
        if (value is String && value.isNotEmpty) {
          final fileName = value.split('/').last;
          return fileName.length > 20
              ? '...${fileName.substring(fileName.length - 20)}'
              : fileName;
        }
        return 'ملف مرفق';

      default:
        return value.toString();
    }
  }

  Widget _buildPropertySelector(UnitFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العقار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            context.push(
              '/helpers/search/properties',
              extra: {
                'allowMultiSelect': false,
                'onPropertySelected': (Property property) {
                  setState(() {
                    _selectedPropertyId = property.id;
                    _selectedPropertyName = property.name;
                    _selectedUnitTypeId = null;
                  });
                  context.read<UnitFormBloc>().add(
                        PropertySelectedEvent(
                            propertyId: property.id,
                            propertyTypeId: property.typeId),
                      );
                },
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Row(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  color: AppTheme.primaryBlue.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedPropertyName ?? 'اختر العقار',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _selectedPropertyName == null
                          ? AppTheme.textMuted.withOpacity(0.5)
                          : AppTheme.textWhite,
                    ),
                  ),
                ),
                Icon(
                  Icons.search,
                  color: AppTheme.primaryBlue.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildUnitTypeSelector(UnitFormState state) {
  //   List<DropdownMenuItem<String>> items = [];

  //   if (state is UnitFormReady && state.availableUnitTypes.isNotEmpty) {
  //     items = state.availableUnitTypes.map((unitType) {
  //       _isHasAdults = unitType.isHasAdults;
  //       _isHasChildren = unitType.isHasChildren;
  //       _adultCapacity = _isHasAdults ? 2 : 0;
  //       return DropdownMenuItem<String>(
  //         value: unitType.id,
  //         child: Text(unitType.name),
  //       );
  //     }).toList();
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'نوع الوحدة',
  //         style: AppTextStyles.bodyMedium.copyWith(
  //           color: AppTheme.textWhite,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [
  //               AppTheme.darkCard.withOpacity(0.5),
  //               AppTheme.darkCard.withOpacity(0.3),
  //             ],
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: AppTheme.darkBorder.withOpacity(0.3),
  //             width: 1,
  //           ),
  //         ),
  //         child: DropdownButtonHideUnderline(
  //           child: DropdownButton<String>(
  //             value: _selectedUnitTypeId,
  //             isExpanded: true,
  //             dropdownColor: AppTheme.darkCard,
  //             icon: Icon(
  //               Icons.arrow_drop_down_rounded,
  //               color: AppTheme.primaryBlue.withOpacity(0.7),
  //             ),
  //             style: AppTextStyles.bodyMedium.copyWith(
  //               color: AppTheme.textWhite,
  //             ),
  //             hint: Text(
  //               'اختر نوع الوحدة',
  //               style: AppTextStyles.bodyMedium.copyWith(
  //                 color: AppTheme.textMuted.withOpacity(0.5),
  //               ),
  //             ),
  //             items: items,
  //             onChanged: _selectedPropertyId == null
  //                 ? null
  //                 : (value) {
  //                     setState(() {
  //                       _selectedUnitTypeId = value;
  //                     });
  //                     if (value != null) {
  //                       context.read<UnitFormBloc>().add(
  //                         UnitTypeSelectedEvent(unitTypeId: value),
  //                       );
  //                     }
  //                   },
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _buildUnitTypeSelector(UnitFormState state) {
    List<DropdownMenuItem<String>> items = [];
    bool isLoadingUnitTypes = false;

    if (state is UnitFormReady) {
      isLoadingUnitTypes = state.isLoadingUnitTypes;

      if (state.availableUnitTypes.isNotEmpty) {
        items = state.availableUnitTypes.map((unitType) {
          _isHasAdults = unitType.isHasAdults;
          _isHasChildren = unitType.isHasChildren;
          _adultCapacity = _isHasAdults ? 2 : 0;
          return DropdownMenuItem<String>(
            value: unitType.id,
            child: Text(unitType.name),
          );
        }).toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'نوع الوحدة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isLoadingUnitTypes) ...[
              const SizedBox(width: 8),
              // Animated Loading Dots
              _buildLoadingDots(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(isLoadingUnitTypes ? 0.3 : 0.5),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLoadingUnitTypes
                  ? AppTheme.primaryBlue.withOpacity(0.3)
                  : AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUnitTypeId,
                  isExpanded: true,
                  dropdownColor: AppTheme.darkCard,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isLoadingUnitTypes
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryBlue.withOpacity(0.7),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.arrow_drop_down_rounded,
                            key: const ValueKey('dropdown_icon'),
                            color: AppTheme.primaryBlue.withOpacity(0.7),
                          ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                  hint: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isLoadingUnitTypes
                          ? 'جاري تحميل أنواع الوحدات...'
                          : 'اختر نوع الوحدة',
                      key: ValueKey(isLoadingUnitTypes),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.5),
                      ),
                    ),
                  ),
                  items: items,
                  onChanged: (_selectedPropertyId == null || isLoadingUnitTypes)
                      ? null
                      : (value) {
                          setState(() {
                            _selectedUnitTypeId = value;
                          });
                          if (value != null) {
                            context.read<UnitFormBloc>().add(
                                  UnitTypeSelectedEvent(unitTypeId: value),
                                );
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// أضف هذه الدالة المساعدة بعد دالة _buildUnitTypeSelector
  Widget _buildLoadingDots() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final opacity =
                ((value - delay).clamp(0.0, 1.0) * 2 - 1).clamp(0.0, 1.0);

            return AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 300),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
      onEnd: () {},
    );
  }

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
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.darkCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
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

  Widget _buildDynamicFields(List<dynamic> fields) {
    return Column(
      children: fields.map((field) {
        final controller = TextEditingController(
          text: _dynamicFieldValues[field.fieldId]?.toString() ?? '',
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildInputField(
            controller: controller,
            label: field.displayName,
            hint: field.description ?? 'أدخل ${field.displayName}',
            icon: Icons.info_rounded,
            onChanged: (value) {
              _dynamicFieldValues[field.fieldId] = value;
              _updateDynamicFields();
            },
          ),
        );
      }).toList(),
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

  Widget _buildCapacityCounter({
    required String label,
    required int value,
    required IconData icon,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
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
                  color: AppTheme.textWhite,
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
    required List<Map<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['label']!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['value']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
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
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
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
                      return Text(
                        _currentStep < 3 ? 'التالي' : 'إضافة الوحدة',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

  // Helper Methods
  void _updateCapacity() {
    context.read<UnitFormBloc>().add(
          UpdateCapacityEvent(
            adultCapacity: _adultCapacity,
            childrenCapacity: _childrenCapacity,
          ),
        );
  }

  // Helper Methods
  void _updateUnitImage() {
    context.read<UnitFormBloc>().add(
          UpdateUnitImageEvent(
            images: _selectedLocalImages,
          ),
        );
  }

  void _updatePricing() {
    if (_priceController.text.isNotEmpty) {
      final price = double.tryParse(_priceController.text);
      if (price != null && price > 0) {
        // إنشاء Money و PricingMethod objects
        final money = Money(
          amount: price,
          currency: 'YER', // أو العملة المناسبة
          formattedAmount: price.toString(),
        );

        // استخدام قيم enum بدلاً من constructor
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
    if (_featuresController.text.isNotEmpty) {
      context.read<UnitFormBloc>().add(
            UpdateFeaturesEvent(features: _featuresController.text),
          );
    }
  }

  void _updateUnitName() {
    // if (_nameController.text.isNotEmpty) {
    context.read<UnitFormBloc>().add(
          UpdateUnitNameEvent(name: _nameController.text),
        );
    // }
  }

  void _updateDescription() {
    // if (_descriptionController.text.isNotEmpty) {
    context.read<UnitFormBloc>().add(
          UpdateDescriptionEvent(description: _descriptionController.text),
        );
    // }
  }

  void _updateDynamicFields() {
    context.read<UnitFormBloc>().add(
          UpdateDynamicFieldsEvent(values: _dynamicFieldValues),
        );
  }

  String _getPropertyName(UnitFormState state) {
    if (_selectedPropertyName != null) {
      return _selectedPropertyName!;
    }
    return 'غير محدد';
  }

  String _getUnitTypeName(UnitFormState state) {
    if (state is UnitFormReady && state.selectedUnitType != null) {
      return state.selectedUnitType!.name;
    }
    return 'غير محدد';
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
      context.pop();
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
      // Validate current step
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
    if (_nameController.text.isEmpty ||
        _selectedPropertyId == null ||
        _selectedUnitTypeId == null ||
        _descriptionController.text.isEmpty) {
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
    if (_formKey.currentState!.validate()) {
      // تأكد من تحديث جميع البيانات قبل الإرسال
      _updateUnitName();
      _updateDescription();
      _updatePricing();
      _updateFeatures();
      _updateCapacity();
      _updateUnitImage();
      _updateCancellationPolicy();

      // انتظر قليلاً للتأكد من تحديث البلوك
      Future.delayed(const Duration(milliseconds: 100), () {
        context.read<UnitFormBloc>().add(SubmitFormEvent());
      });
    }
  }

  void _updateCancellationPolicy() {
    final daysText = _cancellationDaysController.text.trim();
    final days = daysText.isEmpty ? null : int.tryParse(daysText);
    context.read<UnitFormBloc>().add(
          UpdateCancellationPolicyEvent(
            allowsCancellation: _allowsCancellation,
            cancellationWindowDays: days,
          ),
        );
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
}

class _CreateUnitBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _CreateUnitBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw glowing orbs
    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryBlue.withOpacity(0.1 * glowIntensity),
        AppTheme.primaryBlue.withOpacity(0.05 * glowIntensity),
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
