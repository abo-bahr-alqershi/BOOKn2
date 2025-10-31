// lib/features/admin_policies/presentation/pages/edit_policy_page.dart

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/local_storage_service.dart';
import '../../domain/entities/policy.dart';
import '../bloc/policies_bloc.dart';
import '../bloc/policies_event.dart';
import '../bloc/policies_state.dart';

class EditPolicyPage extends StatefulWidget {
  final String policyId;
  final Policy? initialPolicy;

  const EditPolicyPage({
    super.key,
    required this.policyId,
    this.initialPolicy,
  });

  @override
  State<EditPolicyPage> createState() => _EditPolicyPageState();
}

class _EditPolicyPageState extends State<EditPolicyPage>
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
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _cancellationWindowController = TextEditingController(text: '0');
  final _depositPercentageController = TextEditingController(text: '0');
  final _minHoursController = TextEditingController(text: '0');
  final _storage = GetIt.I<LocalStorageService>();

  // State
  PolicyType _selectedType = PolicyType.cancellation;
  bool _requireFullPayment = false;
  String? _propertyId;
  String? _propertyName;
  int _currentStep = 0;

  // Edit specific state
  Policy? _originalPolicy;
  bool _isDataLoaded = false;
  bool _hasChanges = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkUserRole();
    _prefillOrLoad();
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

  void _checkUserRole() {
    final role = _storage.getAccountRole();
    setState(() {
      _isAdmin = role.toLowerCase() == 'admin';
    });
  }

  void _prefillOrLoad() {
    final initial = widget.initialPolicy;
    if (initial != null) {
      _populateFormWithPolicyData(initial);
    } else {
      context.read<PoliciesBloc>().add(LoadPolicyByIdEvent(policyId: widget.policyId));
    }
  }

  void _populateFormWithPolicyData(Policy policy) {
    if (_isDataLoaded) return;

    setState(() {
      _originalPolicy = policy;
      _isDataLoaded = true;

      // Populate controllers
      _selectedType = policy.type;
      _descriptionController.text = policy.description;
      _rulesController.text = policy.rules;
      _propertyId = policy.propertyId;
      _propertyName = policy.propertyName;

      // Type-specific fields
      _cancellationWindowController.text =
          policy.cancellationWindowDays.toString() ?? '0';
      _requireFullPayment =
          policy.requireFullPaymentBeforeConfirmation ?? false;
      _depositPercentageController.text =
          policy.minimumDepositPercentage.toString() ?? '0';
      _minHoursController.text = policy.minHoursBeforeCheckIn.toString() ?? '0';
    });

    // Start animation after data is loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _loadingAnimationController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _cancellationWindowController.dispose();
    _depositPercentageController.dispose();
    _minHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocListener<PoliciesBloc, PoliciesState>(
        listener: (context, state) {
          if (state is PolicyOperationSuccess) {
            _showSuccessMessage('تم تحديث السياسة بنجاح');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop({'refresh': true});
              }
            });
          } else if (state is PolicyOperationFailure) {
            _showErrorMessage(state.message);
          } else if (state is PolicyDetailsLoaded && widget.initialPolicy == null) {
            _populateFormWithPolicyData(state.policy);
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
            painter: _EditPolicyBackgroundPainter(
              glowIntensity: _glowController.value,
              policyType: _selectedType,
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
                        _getPolicyTypeColor(_selectedType).withOpacity(0.3),
                        AppTheme.primaryPurple.withOpacity(0.2),
                        _getPolicyTypeColor(_selectedType).withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _getPolicyTypeColor(_selectedType).withOpacity(0.3),
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
                          Icons.policy_rounded,
                          color: _getPolicyTypeColor(_selectedType),
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
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                _getPolicyTypeColor(_selectedType),
                _getPolicyTypeColor(_selectedType).withOpacity(0.7),
              ],
            ).createShader(bounds),
            child: Text(
              'جاري تحميل بيانات السياسة...',
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
            color: _getPolicyTypeColor(_selectedType).withOpacity(0.3),
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
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.7),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'تعديل السياسة',
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
                  _originalPolicy?.type.displayName ??
                      'قم بتحديث بيانات السياسة',
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
    final steps = ['المعلومات الأساسية', 'الإعدادات', 'المراجعة'];

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
                    gradient: isActive
                        ? LinearGradient(
                            colors: isModified
                                ? [
                                    AppTheme.warning,
                                    AppTheme.warning.withOpacity(0.7)
                                  ]
                                : [
                                    _getPolicyTypeColor(_selectedType),
                                    _getPolicyTypeColor(_selectedType)
                                        .withOpacity(0.7),
                                  ],
                          )
                        : null,
                    color: !isActive
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isModified
                          ? AppTheme.warning.withOpacity(0.5)
                          : isActive
                              ? _getPolicyTypeColor(_selectedType)
                                  .withOpacity(0.5)
                              : AppTheme.darkBorder.withOpacity(0.3),
                      width: isModified ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: isModified
                                  ? AppTheme.warning.withOpacity(0.3)
                                  : _getPolicyTypeColor(_selectedType)
                                      .withOpacity(0.3),
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
                                : LinearGradient(colors: [
                                    _getPolicyTypeColor(_selectedType),
                                    _getPolicyTypeColor(_selectedType)
                                        .withOpacity(0.5)
                                  ])
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
          _buildBasicInfoStep(),
          _buildSettingsStep(),
          _buildReviewStep(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Display (Read-only)
          _buildReadOnlyField(
            label: 'نوع السياسة',
            value: _selectedType.displayName,
            icon: _getPolicyIcon(_selectedType),
            color: _getPolicyTypeColor(_selectedType),
          ),

          const SizedBox(height: 20),

          // Property (Read-only)
          if (_isAdmin)
            _buildReadOnlyField(
              label: 'العقار',
              value: _propertyName ?? 'غير محدد',
              icon: Icons.apartment_rounded,
              color: AppTheme.primaryPurple,
            ),

          const SizedBox(height: 20),

          // Original value indicator for description
          if (_originalPolicy != null)
            _buildOriginalValueIndicator(
              'الوصف الأصلي',
              _originalPolicy!.description,
              _descriptionController.text != _originalPolicy!.description,
            ),

          // Description
          _buildInputField(
            controller: _descriptionController,
            label: 'الوصف',
            hint: 'أدخل وصف السياسة',
            icon: Icons.description_rounded,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال الوصف';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Rules
          _buildInputField(
            controller: _rulesController,
            label: 'القواعد (JSON)',
            hint: '{"rule1": "value1"}',
            icon: Icons.rule_rounded,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال القواعد';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPolicyTypeColor(_selectedType).withOpacity(0.1),
                  _getPolicyTypeColor(_selectedType).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasChangesInStep(1)
                    ? AppTheme.warning.withOpacity(0.3)
                    : _getPolicyTypeColor(_selectedType).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _hasChangesInStep(1)
                            ? AppTheme.warning
                            : _getPolicyTypeColor(_selectedType),
                        (_hasChangesInStep(1)
                                ? AppTheme.warning
                                : _getPolicyTypeColor(_selectedType))
                            .withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getPolicyIcon(_selectedType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات ${_selectedType.displayName}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _hasChangesInStep(1)
                            ? 'تم التعديل على الإعدادات'
                            : 'قم بتكوين الإعدادات الخاصة بالسياسة',
                        style: AppTextStyles.caption.copyWith(
                          color: _hasChangesInStep(1)
                              ? AppTheme.warning
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasChangesInStep(1))
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
            ),
          ),

          const SizedBox(height: 24),

          // Type-specific fields with original values
          _buildTypeSpecificFields(),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
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
            color: _getPolicyTypeColor(_selectedType),
            items: [
              {
                'label': 'النوع',
                'value': _selectedType.displayName,
                'changed': false
              },
              {
                'label': 'العقار',
                'value': _propertyName ?? 'غير محدد',
                'changed': false
              },
              {
                'label': 'الوصف',
                'value': _descriptionController.text,
                'changed':
                    _descriptionController.text != _originalPolicy?.description
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'القواعد',
            color: AppTheme.primaryPurple,
            items: [
              {
                'label': 'JSON',
                'value': _rulesController.text,
                'changed': _rulesController.text != _originalPolicy?.rules
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'الإعدادات الخاصة',
            color: _getPolicyTypeColor(_selectedType),
            items: _getTypeSpecificReviewItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case PolicyType.cancellation:
        if (_originalPolicy != null &&
            int.tryParse(_cancellationWindowController.text) !=
                _originalPolicy!.cancellationWindowDays) {
          _buildOriginalValueIndicator(
            'نافذة الإلغاء الأصلية',
            '${_originalPolicy!.cancellationWindowDays ?? 0} يوم',
            true,
          );
        }
        return _buildInputField(
          controller: _cancellationWindowController,
          label: 'نافذة الإلغاء (بالأيام)',
          hint: 'عدد الأيام المسموح فيها بالإلغاء',
          icon: Icons.event_busy_rounded,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final number = int.tryParse(value);
              if (number == null || number < 0) {
                return 'يجب إدخال رقم صحيح';
              }
            }
            return null;
          },
        );

      case PolicyType.payment:
        return Column(
          children: [
            if (_originalPolicy != null &&
                _requireFullPayment !=
                    _originalPolicy!.requireFullPaymentBeforeConfirmation)
              _buildOriginalValueIndicator(
                'الدفع الكامل',
                _originalPolicy!.requireFullPaymentBeforeConfirmation == true
                    ? 'نعم'
                    : 'لا',
                true,
              ),
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
                  color: _requireFullPayment !=
                          _originalPolicy?.requireFullPaymentBeforeConfirmation
                      ? AppTheme.warning.withOpacity(0.3)
                      : _requireFullPayment
                          ? AppTheme.success.withOpacity(0.3)
                          : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _requireFullPayment
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.darkSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payment_rounded,
                        size: 16,
                        color: _requireFullPayment
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'يتطلب الدفع الكامل',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'يجب دفع المبلغ كاملاً قبل التأكيد',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_requireFullPayment !=
                        _originalPolicy?.requireFullPaymentBeforeConfirmation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                ),
                value: _requireFullPayment,
                onChanged: (value) {
                  setState(() {
                    _requireFullPayment = value;
                    _hasChanges = _checkForChanges();
                  });
                },
                activeThumbColor: AppTheme.success,
                activeTrackColor: AppTheme.success.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            if (_originalPolicy != null &&
                double.tryParse(_depositPercentageController.text) !=
                    _originalPolicy!.minimumDepositPercentage)
              _buildOriginalValueIndicator(
                'نسبة الدفعة المقدمة الأصلية',
                '${_originalPolicy!.minimumDepositPercentage ?? 0}%',
                true,
              ),
            _buildInputField(
              controller: _depositPercentageController,
              label: 'نسبة الدفعة المقدمة (%)',
              hint: 'النسبة المئوية المطلوبة (0-100)',
              icon: Icons.percent_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final number = double.tryParse(value);
                  if (number == null || number < 0 || number > 100) {
                    return 'يجب إدخال نسبة بين 0 و 100';
                  }
                }
                return null;
              },
            ),
          ],
        );

      case PolicyType.checkIn:
      case PolicyType.modification:
        if (_originalPolicy != null &&
            int.tryParse(_minHoursController.text) !=
                _originalPolicy!.minHoursBeforeCheckIn) {
          _buildOriginalValueIndicator(
            'الحد الأدنى للساعات الأصلي',
            '${_originalPolicy!.minHoursBeforeCheckIn} ساعة',
            true,
          );
        }
        return _buildInputField(
          controller: _minHoursController,
          label: 'الحد الأدنى للساعات قبل تسجيل الوصول',
          hint: 'عدد الساعات المطلوبة قبل الوصول',
          icon: Icons.access_time_rounded,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final number = int.tryParse(value);
              if (number == null || number < 0) {
                return 'يجب إدخال رقم صحيح';
              }
            }
            return null;
          },
        );

      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getPolicyTypeColor(_selectedType).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'لا توجد إعدادات خاصة لهذا النوع',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        );
    }
  }

  List<Map<String, dynamic>> _getTypeSpecificReviewItems() {
    switch (_selectedType) {
      case PolicyType.cancellation:
        return [
          {
            'label': 'نافذة الإلغاء',
            'value': '${_cancellationWindowController.text} يوم',
            'changed': int.tryParse(_cancellationWindowController.text) !=
                _originalPolicy?.cancellationWindowDays
          },
        ];
      case PolicyType.payment:
        return [
          {
            'label': 'يتطلب الدفع الكامل',
            'value': _requireFullPayment ? 'نعم' : 'لا',
            'changed': _requireFullPayment !=
                _originalPolicy?.requireFullPaymentBeforeConfirmation
          },
          {
            'label': 'نسبة الدفعة المقدمة',
            'value': '${_depositPercentageController.text}%',
            'changed': double.tryParse(_depositPercentageController.text) !=
                _originalPolicy?.minimumDepositPercentage
          },
        ];
      case PolicyType.checkIn:
      case PolicyType.modification:
        return [
          {
            'label': 'الحد الأدنى للساعات',
            'value': '${_minHoursController.text} ساعة',
            'changed': int.tryParse(_minHoursController.text) !=
                _originalPolicy?.minHoursBeforeCheckIn
          },
        ];
      default:
        return [];
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
    required Color color,
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
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
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

  Widget _buildReviewCard({
    required String title,
    required Color color,
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
              : color.withOpacity(0.3),
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
                    colors: [
                      hasChanges ? AppTheme.warning : color,
                      (hasChanges ? AppTheme.warning : color).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasChanges ? AppTheme.warning : color,
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
                      color:
                          _getPolicyTypeColor(_selectedType).withOpacity(0.7),
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
              onTap: _currentStep < 2 ? _nextStep : _submitForm,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: _hasChanges
                      ? LinearGradient(colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.8)
                        ])
                      : LinearGradient(colors: [
                          _getPolicyTypeColor(_selectedType),
                          _getPolicyTypeColor(_selectedType).withOpacity(0.8)
                        ]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _hasChanges
                          ? AppTheme.warning.withOpacity(0.3)
                          : _getPolicyTypeColor(_selectedType).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: BlocBuilder<PoliciesBloc, PoliciesState>(
                    builder: (context, state) {
                      if (state is PolicyOperationInProgress) {
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
                          if (_currentStep == 2 && _hasChanges)
                            const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          if (_currentStep == 2 && _hasChanges)
                            const SizedBox(width: 8),
                          Text(
                            _currentStep < 2
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

  // Helper Methods
  bool _checkForChanges() {
    if (_originalPolicy == null) return false;

    return _descriptionController.text != _originalPolicy!.description ||
        _rulesController.text != _originalPolicy!.rules ||
        int.tryParse(_cancellationWindowController.text) !=
            _originalPolicy!.cancellationWindowDays ||
        _requireFullPayment !=
            _originalPolicy!.requireFullPaymentBeforeConfirmation ||
        double.tryParse(_depositPercentageController.text) !=
            _originalPolicy!.minimumDepositPercentage ||
        int.tryParse(_minHoursController.text) !=
            _originalPolicy!.minHoursBeforeCheckIn;
  }

  bool _hasChangesInStep(int step) {
    if (_originalPolicy == null) return false;

    switch (step) {
      case 0: // Basic Info
        return _descriptionController.text != _originalPolicy!.description ||
            _rulesController.text != _originalPolicy!.rules;
      case 1: // Settings
        switch (_selectedType) {
          case PolicyType.cancellation:
            return int.tryParse(_cancellationWindowController.text) !=
                _originalPolicy!.cancellationWindowDays;
          case PolicyType.payment:
            return _requireFullPayment !=
                    _originalPolicy!.requireFullPaymentBeforeConfirmation ||
                double.tryParse(_depositPercentageController.text) !=
                    _originalPolicy!.minimumDepositPercentage;
          case PolicyType.checkIn:
          case PolicyType.modification:
            return int.tryParse(_minHoursController.text) !=
                _originalPolicy!.minHoursBeforeCheckIn;
          default:
            return false;
        }
      default:
        return _checkForChanges();
    }
  }

  List<Map<String, String>> _getChangedFields() {
    final changes = <Map<String, String>>[];
    if (_originalPolicy == null) return changes;

    if (_descriptionController.text != _originalPolicy!.description) {
      changes.add({
        'field': 'الوصف',
        'oldValue': _originalPolicy!.description,
        'newValue': _descriptionController.text,
      });
    }

    if (_rulesController.text != _originalPolicy!.rules) {
      changes.add({
        'field': 'القواعد',
        'oldValue': _originalPolicy!.rules,
        'newValue': _rulesController.text,
      });
    }

    // Type-specific changes
    switch (_selectedType) {
      case PolicyType.cancellation:
        if (int.tryParse(_cancellationWindowController.text) !=
            _originalPolicy!.cancellationWindowDays) {
          changes.add({
            'field': 'نافذة الإلغاء',
            'oldValue': '${_originalPolicy!.cancellationWindowDays ?? 0} يوم',
            'newValue': '${_cancellationWindowController.text} يوم',
          });
        }
        break;
      case PolicyType.payment:
        if (_requireFullPayment !=
            _originalPolicy!.requireFullPaymentBeforeConfirmation) {
          changes.add({
            'field': 'يتطلب الدفع الكامل',
            'oldValue':
                _originalPolicy!.requireFullPaymentBeforeConfirmation == true
                    ? 'نعم'
                    : 'لا',
            'newValue': _requireFullPayment ? 'نعم' : 'لا',
          });
        }
        if (double.tryParse(_depositPercentageController.text) !=
            _originalPolicy!.minimumDepositPercentage) {
          changes.add({
            'field': 'نسبة الدفعة المقدمة',
            'oldValue': '${_originalPolicy!.minimumDepositPercentage ?? 0}%',
            'newValue': '${_depositPercentageController.text}%',
          });
        }
        break;
      case PolicyType.checkIn:
      case PolicyType.modification:
        if (int.tryParse(_minHoursController.text) !=
            _originalPolicy!.minHoursBeforeCheckIn) {
          changes.add({
            'field': 'الحد الأدنى للساعات',
            'oldValue': '${_originalPolicy!.minHoursBeforeCheckIn ?? 0} ساعة',
            'newValue': '${_minHoursController.text} ساعة',
          });
        }
        break;
      default:
        break;
    }

    return changes;
  }

  void _resetChanges() {
    if (_originalPolicy == null) return;

    showDialog(
      context: context,
      builder: (context) => _ResetConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);

          setState(() {
            _descriptionController.text = _originalPolicy!.description;
            _rulesController.text = _originalPolicy!.rules;
            _cancellationWindowController.text =
                _originalPolicy!.cancellationWindowDays.toString() ?? '0';
            _requireFullPayment =
                _originalPolicy!.requireFullPaymentBeforeConfirmation ?? false;
            _depositPercentageController.text =
                _originalPolicy!.minimumDepositPercentage.toString() ?? '0';
            _minHoursController.text =
                _originalPolicy!.minHoursBeforeCheckIn.toString() ?? '0';
            _hasChanges = false;
          });

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
    if (_currentStep < 2) {
      bool isValid = true;

      if (_currentStep == 0) {
        isValid = _validateBasicInfo();
      } else if (_currentStep == 1) {
        isValid = _validateSettings();
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    if (_descriptionController.text.isEmpty) {
      _showErrorMessage('الرجاء إدخال الوصف');
      return false;
    }
    if (_rulesController.text.isEmpty) {
      _showErrorMessage('الرجاء إدخال القواعد');
      return false;
    }
    return true;
  }

  bool _validateSettings() {
    // Validation based on policy type
    switch (_selectedType) {
      case PolicyType.cancellation:
        final days = int.tryParse(_cancellationWindowController.text);
        if (days == null || days < 0) {
          _showErrorMessage('نافذة الإلغاء غير صحيحة');
          return false;
        }
        break;
      case PolicyType.payment:
        final percentage = double.tryParse(_depositPercentageController.text);
        if (percentage == null || percentage < 0 || percentage > 100) {
          _showErrorMessage('نسبة الدفعة المقدمة غير صحيحة');
          return false;
        }
        break;
      case PolicyType.checkIn:
      case PolicyType.modification:
        final hours = int.tryParse(_minHoursController.text);
        if (hours == null || hours < 0) {
          _showErrorMessage('عدد الساعات غير صحيح');
          return false;
        }
        break;
      default:
        break;
    }
    return true;
  }

  void _submitForm() {
    if (!_hasChanges) {
      _showInfoMessage('لا توجد تغييرات للحفظ');
      return;
    }

    if (_formKey.currentState!.validate()) {
      context.read<PoliciesBloc>().add(
            UpdatePolicyEvent(
              policyId: widget.policyId,
              type: _selectedType,
              description: _descriptionController.text,
              rules: _rulesController.text,
              cancellationWindowDays:
                  int.tryParse(_cancellationWindowController.text),
              requireFullPaymentBeforeConfirmation: _requireFullPayment,
              minimumDepositPercentage:
                  double.tryParse(_depositPercentageController.text),
              minHoursBeforeCheckIn: int.tryParse(_minHoursController.text),
            ),
          );
    }
  }

  IconData _getPolicyIcon(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return Icons.event_busy_rounded;
      case PolicyType.checkIn:
        return Icons.login_rounded;
      case PolicyType.children:
        return Icons.child_care_rounded;
      case PolicyType.pets:
        return Icons.pets_rounded;
      case PolicyType.payment:
        return Icons.payment_rounded;
      case PolicyType.modification:
        return Icons.edit_calendar_rounded;
    }
  }

  Color _getPolicyTypeColor(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return AppTheme.error;
      case PolicyType.checkIn:
        return AppTheme.primaryBlue;
      case PolicyType.children:
        return AppTheme.warning;
      case PolicyType.pets:
        return AppTheme.primaryViolet;
      case PolicyType.payment:
        return AppTheme.success;
      case PolicyType.modification:
        return AppTheme.primaryPurple;
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
            Expanded(child: Text(message)),
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
            Expanded(child: Text(message)),
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
}

// Dialogs for Edit Page
class _ResetConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _ResetConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
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

class _EditPolicyBackgroundPainter extends CustomPainter {
  final double glowIntensity;
  final PolicyType policyType;

  _EditPolicyBackgroundPainter({
    required this.glowIntensity,
    required this.policyType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final typeColor = _getTypeColor();

    // Draw glowing orbs with policy type theme
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
        typeColor.withOpacity(0.1 * glowIntensity),
        typeColor.withOpacity(0.05 * glowIntensity),
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

  Color _getTypeColor() {
    switch (policyType) {
      case PolicyType.cancellation:
        return AppTheme.error;
      case PolicyType.checkIn:
        return AppTheme.primaryBlue;
      case PolicyType.children:
        return AppTheme.warning;
      case PolicyType.pets:
        return AppTheme.primaryViolet;
      case PolicyType.payment:
        return AppTheme.success;
      case PolicyType.modification:
        return AppTheme.primaryPurple;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
