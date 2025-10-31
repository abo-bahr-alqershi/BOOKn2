// lib/features/admin_policies/presentation/pages/create_policy_page.dart

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/local_storage_service.dart';
import '../../../admin_properties/domain/entities/property.dart';
import '../../domain/entities/policy.dart';
import '../bloc/policies_bloc.dart';
import '../bloc/policies_event.dart';
import '../bloc/policies_state.dart';

class CreatePolicyPage extends StatefulWidget {
  final String? initialPropertyId;
  const CreatePolicyPage({super.key, this.initialPropertyId});

  @override
  State<CreatePolicyPage> createState() => _CreatePolicyPageState();
}

class _CreatePolicyPageState extends State<CreatePolicyPage>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  bool _isAdmin = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkUserRole();
    _selectedPropertyId = widget.initialPropertyId;
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

  void _checkUserRole() {
    final role = _storage.getAccountRole();
    setState(() {
      _isAdmin = role.toLowerCase() == 'admin';
      if (!_isAdmin) {
        _selectedPropertyId = _storage.getPropertyId();
        _selectedPropertyName = _storage.getPropertyName();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _cancellationWindowController.dispose();
    _depositPercentageController.dispose();
    _minHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoliciesBloc, PoliciesState>(
      listener: (context, state) {
        if (state is PolicyOperationSuccess) {
          _showSuccessMessage('تم إنشاء السياسة بنجاح');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.pop({
                'refresh': true,
                'propertyId': _selectedPropertyId,
              });
            }
          });
        } else if (state is PolicyOperationFailure) {
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
            painter: _CreatePolicyBackgroundPainter(
              glowIntensity: _glowController.value,
              policyType: _selectedType,
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
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      _getPolicyTypeColor(_selectedType),
                      _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'إضافة سياسة جديدة',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بملء البيانات المطلوبة لإضافة السياسة',
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
    final steps = ['المعلومات الأساسية', 'الإعدادات', 'المراجعة'];

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
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
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
                      color: isActive
                          ? _getPolicyTypeColor(_selectedType).withOpacity(0.5)
                          : AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _getPolicyTypeColor(_selectedType)
                                  .withOpacity(0.3),
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
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  _getPolicyTypeColor(_selectedType),
                                  _getPolicyTypeColor(_selectedType)
                                      .withOpacity(0.5),
                                ],
                              )
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
          // Policy Type Selector
          _buildTypeSelector(),

          const SizedBox(height: 20),

          // Property Selector
          _buildPropertySelector(),

          const SizedBox(height: 20),

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
                color: _getPolicyTypeColor(_selectedType).withOpacity(0.3),
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
                        _getPolicyTypeColor(_selectedType),
                        _getPolicyTypeColor(_selectedType).withOpacity(0.7),
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
                        'قم بتكوين الإعدادات الخاصة بالسياسة',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Type-specific fields
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
            color: _getPolicyTypeColor(_selectedType),
            items: [
              {'label': 'النوع', 'value': _selectedType.displayName},
              {'label': 'العقار', 'value': _selectedPropertyName ?? 'غير محدد'},
              {'label': 'الوصف', 'value': _descriptionController.text},
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'القواعد',
            color: AppTheme.primaryPurple,
            items: [
              {'label': 'JSON', 'value': _rulesController.text},
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

  Widget _buildTypeSelector() {
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
            'نوع السياسة',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PolicyType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedType = type);
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              _getPolicyTypeColor(type),
                              _getPolicyTypeColor(type).withOpacity(0.7),
                            ],
                          )
                        : null,
                    color:
                        isSelected ? null : AppTheme.darkCard.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getPolicyTypeColor(type).withOpacity(0.5)
                          : AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _getPolicyTypeColor(type).withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPolicyIcon(type),
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.displayName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySelector() {
    // للـ Admin: اختيار العقار
    if (_isAdmin) {
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
                    });
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
                  color: _selectedPropertyId != null
                      ? _getPolicyTypeColor(_selectedType).withOpacity(0.3)
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.apartment_rounded,
                    color: _selectedPropertyId != null
                        ? _getPolicyTypeColor(_selectedType)
                        : AppTheme.textMuted.withOpacity(0.5),
                    size: 20,
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
                    color: _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // للـ Owner/Staff: إخفاء حقل اختيار/عرض العقار تماماً
    return const SizedBox.shrink();
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case PolicyType.cancellation:
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
                  color: _requireFullPayment
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
                  ],
                ),
                value: _requireFullPayment,
                onChanged: (value) {
                  setState(() {
                    _requireFullPayment = value;
                  });
                },
                activeThumbColor: AppTheme.success,
                activeTrackColor: AppTheme.success.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
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
        return _buildInputField(
          controller: _minHoursController,
          label: 'الحد الأدنى للساعات قبل تسجيل الوصول',
          hint: 'عدد الساعات المطلوبة',
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
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
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
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String title,
    required Color color,
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
          color: color.withOpacity(0.3),
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
                    colors: [color, color.withOpacity(0.7)],
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
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['label']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
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
              onTap: _currentStep < 2 ? _nextStep : _submitForm,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPolicyTypeColor(_selectedType),
                      _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _getPolicyTypeColor(_selectedType).withOpacity(0.3),
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
                      return Text(
                        _currentStep < 2 ? 'التالي' : 'إضافة السياسة',
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
    if (_currentStep < 2) {
      bool isValid = true;

      if (_currentStep == 0) {
        isValid = _validateBasicInfo();
      } else if (_currentStep == 1) {
        isValid = true; // Settings are optional
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    if (_selectedPropertyId == null) {
      _showErrorMessage('الرجاء اختيار العقار');
      return false;
    }
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        _showErrorMessage('الرجاء اختيار العقار');
        return;
      }

      context.read<PoliciesBloc>().add(
            CreatePolicyEvent(
              propertyId: _selectedPropertyId!,
              type: _selectedType,
              description: _descriptionController.text,
              rules: _rulesController.text,
              cancellationWindowDays:
                  int.tryParse(_cancellationWindowController.text) ?? 0,
              requireFullPaymentBeforeConfirmation: _requireFullPayment,
              minimumDepositPercentage:
                  double.tryParse(_depositPercentageController.text) ?? 0,
              minHoursBeforeCheckIn:
                  int.tryParse(_minHoursController.text) ?? 0,
            ),
          );
    }
  }

  List<Map<String, String>> _getTypeSpecificReviewItems() {
    final items = <Map<String, String>>[];

    switch (_selectedType) {
      case PolicyType.cancellation:
        items.add({
          'label': 'نافذة الإلغاء',
          'value': '${_cancellationWindowController.text} يوم',
        });
        break;
      case PolicyType.payment:
        items.add({
          'label': 'دفع كامل مطلوب',
          'value': _requireFullPayment ? 'نعم' : 'لا',
        });
        items.add({
          'label': 'نسبة الدفعة المقدمة',
          'value': '${_depositPercentageController.text}%',
        });
        break;
      case PolicyType.checkIn:
      case PolicyType.modification:
        items.add({
          'label': 'الحد الأدنى للساعات',
          'value': '${_minHoursController.text} ساعة',
        });
        break;
      default:
        items.add({
          'label': 'إعدادات افتراضية',
          'value': 'لا توجد إعدادات خاصة',
        });
    }

    return items;
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

  IconData _getPolicyIcon(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return Icons.cancel_rounded;
      case PolicyType.checkIn:
        return Icons.login_rounded;
      case PolicyType.children:
        return Icons.child_care_rounded;
      case PolicyType.pets:
        return Icons.pets_rounded;
      case PolicyType.payment:
        return Icons.payment_rounded;
      case PolicyType.modification:
        return Icons.edit_rounded;
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
}

// Background Painter
class _CreatePolicyBackgroundPainter extends CustomPainter {
  final double glowIntensity;
  final PolicyType policyType;

  _CreatePolicyBackgroundPainter({
    required this.glowIntensity,
    required this.policyType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Get policy color
    final color = _getColor(policyType);

    // Draw glowing orbs
    paint.shader = RadialGradient(
      colors: [
        color.withOpacity(0.1 * glowIntensity),
        color.withOpacity(0.05 * glowIntensity),
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

  Color _getColor(PolicyType type) {
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
