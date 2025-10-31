// lib/features/admin_services/presentation/pages/create_service_page.dart

import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/features/admin_services/domain/entities/money.dart';
import 'package:bookn_cp_app/features/admin_services/domain/entities/pricing_model.dart';
import 'package:bookn_cp_app/features/admin_services/presentation/bloc/services_bloc.dart';
import 'package:bookn_cp_app/features/admin_services/presentation/bloc/services_event.dart';
import 'package:bookn_cp_app/features/admin_services/presentation/bloc/services_state.dart';
import 'package:bookn_cp_app/features/admin_services/presentation/widgets/service_icon_picker.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:bookn_cp_app/features/admin_currencies/domain/usecases/get_currencies_usecase.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import 'package:bookn_cp_app/core/constants/storage_constants.dart';

class CreateServicePage extends StatefulWidget {
  final String? initialPropertyId;
  const CreateServicePage({super.key, this.initialPropertyId});

  @override
  State<CreateServicePage> createState() => _CreateServicePageState();
}

class _CreateServicePageState extends State<CreateServicePage>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Free toggle
  bool _isFree = false;

  // State
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  String _selectedIcon = 'room_service';
  String _selectedCurrency = 'SAR';
  PricingModel _selectedPricingModel = PricingModel.perBooking;
  int _currentStep = 0;
  bool _hidePropertySelector = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectedPropertyId = widget.initialPropertyId;
    _prefillOwnerContextIfNeeded();
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

  void _prefillOwnerContextIfNeeded() {
    try {
      final storage = di.sl<LocalStorageService>();
      final role = storage.getData(StorageConstants.accountRole)?.toString() ?? '';
      final isAdmin = role.toLowerCase() == 'admin';
      _hidePropertySelector = !isAdmin;
      if (!isAdmin) {
        final pid = storage.getData(StorageConstants.propertyId)?.toString() ?? '';
        final pname = storage.getData(StorageConstants.propertyName)?.toString() ?? '';
        if ((_selectedPropertyId == null || _selectedPropertyId!.isEmpty) && pid.isNotEmpty) {
          _selectedPropertyId = pid;
          _selectedPropertyName = pname.isNotEmpty ? pname : null;
        }
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServicesBloc, ServicesState>(
      listener: (context, state) {
        if (state is ServiceOperationSuccess) {
          _showSuccessMessage('تم إنشاء الخدمة بنجاح');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.pop({
                'refresh': true,
                'propertyId': _selectedPropertyId,
              });
            }
          });
        } else if (state is ServicesError) {
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
            painter: _CreateServiceBackgroundPainter(
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
                    'إضافة خدمة جديدة',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بملء البيانات المطلوبة لإضافة الخدمة',
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
    final steps = ['المعلومات الأساسية', 'التسعير', 'المراجعة'];

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
    return Form(
      key: _formKey,
      child: IndexedStack(
        index: _currentStep,
        children: [
          _buildBasicInfoStep(),
          _buildPricingStep(),
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
          // Service Name
          _buildInputField(
            controller: _nameController,
            label: 'اسم الخدمة',
            hint: 'أدخل اسم الخدمة',
            icon: Icons.label_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال اسم الخدمة';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Property Selector
          if (!_hidePropertySelector) _buildPropertySelector(),

          const SizedBox(height: 20),

          // Icon Selector
          _buildIconSelector(),

          const SizedBox(height: 20),

          // Description
          _buildInputField(
            controller: _descriptionController,
            label: 'الوصف',
            hint: 'أدخل وصف الخدمة',
            icon: Icons.description_rounded,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال وصف الخدمة';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pricing Section
          Text(
            'التسعير',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInputField(
                  controller: _amountController,
                  label: 'السعر',
                  hint: _isFree ? '0' : 'أدخل السعر',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isFree) return null;
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال السعر';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'السعر غير صحيح';
                    }
                    final regex = RegExp(r'^\d+\.?\d{0,2}$');
                    if (!regex.hasMatch(value)) {
                      return 'يسمح بحد أقصى رقمين بعد الفاصلة';
                    }
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CurrencyDropdown(
                  value: _selectedCurrency,
                  onChanged: (v) => setState(() => _selectedCurrency = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Switch(
                value: _isFree,
                onChanged: (val) {
                  setState(() {
                    _isFree = val;
                    if (val) _amountController.text = '0';
                  });
                },
                activeThumbColor: AppTheme.success,
              ),
              const SizedBox(width: 8),
              Text('خدمة مجانية',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppTheme.textWhite)),
            ],
          ),

          const SizedBox(height: 20),

          // Pricing Model Selector
          _buildPricingModelSelector(),

          const SizedBox(height: 30),
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
            items: [
              {'label': 'الاسم', 'value': _nameController.text},
              {'label': 'العقار', 'value': _selectedPropertyName ?? 'غير محدد'},
              {'label': 'الأيقونة', 'value': _selectedIcon},
              {'label': 'الوصف', 'value': _descriptionController.text},
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'التسعير',
            items: [
              {
                'label': 'السعر',
                'value': '${_amountController.text} $_selectedCurrency'
              },
              {'label': 'نموذج التسعير', 'value': _selectedPricingModel.label},
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySelector() {
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

  Widget _buildIconSelector() {
    return GestureDetector(
      onTap: _showIconPicker,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(_selectedIcon),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أيقونة الخدمة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    'Icons.$_selectedIcon',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => ServiceIconPicker(
        selectedIcon: _selectedIcon,
        onIconSelected: (icon) {
          setState(() => _selectedIcon = icon);
        },
      ),
    );
  }

  Widget _buildPricingModelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نموذج التسعير',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: PricingModel.values.map((model) {
            final isSelected = _selectedPricingModel == model;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedPricingModel = model);
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
                  model.label,
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
    List<TextInputFormatter>? inputFormatters,
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
            inputFormatters: inputFormatters,
          ),
        ),
      ],
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
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
                  color: AppTheme.primaryBlue,
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
                  child: BlocBuilder<ServicesBloc, ServicesState>(
                    builder: (context, state) {
                      if (state is ServiceOperationInProgress) {
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
                        _currentStep < 2 ? 'التالي' : 'إضافة الخدمة',
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
        isValid = _validatePricing();
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
        _descriptionController.text.isEmpty) {
      _showErrorMessage('الرجاء ملء جميع الحقول المطلوبة');
      return false;
    }
    return true;
  }

  bool _validatePricing() {
    if (_isFree) return true;
    if (_amountController.text.isEmpty) {
      _showErrorMessage('الرجاء إدخال السعر');
      return false;
    }
    final price = double.tryParse(_amountController.text);
    if (price == null || price < 0) {
      _showErrorMessage('السعر غير صحيح');
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

      final price = Money(
        amount: double.tryParse(_amountController.text) ?? 0,
        currency: _selectedCurrency,
      );

      context.read<ServicesBloc>().add(
            CreateServiceEvent(
              propertyId: _selectedPropertyId!,
              name: _nameController.text,
              price: price,
              pricingModel: _selectedPricingModel,
              icon: _selectedIcon,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            ),
          );
    }
  }

  IconData _getIconData(String iconName) {
    // Convert string icon name to IconData
    // This is simplified - you might want to use a more comprehensive mapping
    switch (iconName) {
      case 'room_service':
        return Icons.room_service;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      default:
        return Icons.miscellaneous_services;
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
}

// Background Painter
class _CreateServiceBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _CreateServiceBackgroundPainter({required this.glowIntensity});

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

// Keep Currency Dropdown as is
class _CurrencyDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CurrencyDropdown({required this.value, required this.onChanged});

  @override
  State<_CurrencyDropdown> createState() => _CurrencyDropdownState();
}

class _CurrencyDropdownState extends State<_CurrencyDropdown> {
  List<String> _codes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final usecase = di.sl<GetCurrenciesUseCase>();
      final result = await usecase(NoParams());
      result.fold(
        (f) => setState(() {
          _error = f.message;
          _loading = false;
        }),
        (list) => setState(() {
          _codes = list.map((c) => c.code).toList();
          _loading = false;
          if (_codes.isNotEmpty && !_codes.contains(widget.value)) {
            widget.onChanged(_codes.first);
          }
        }),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText: 'العملة',
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.darkSurface.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
    if (_loading) {
      return InputDecorator(
        decoration: decoration,
        child: Row(children: [
          const SizedBox(width: 4, height: 4),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 8),
          Text('جاري تحميل العملات...',
              style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted)),
        ]),
      );
    }
    if (_error != null) {
      return DropdownButtonFormField<String>(
        initialValue: _codes.contains(widget.value) ? widget.value : null,
        decoration: decoration.copyWith(errorText: _error),
        items: _codes
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          if (v != null) widget.onChanged(v);
        },
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _codes.contains(widget.value) ? widget.value : null,
      decoration: decoration,
      dropdownColor: AppTheme.darkCard,
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      items: _codes
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) {
        if (v != null) widget.onChanged(v);
      },
    );
  }
}
