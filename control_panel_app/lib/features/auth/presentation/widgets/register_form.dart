// lib/features/auth/presentation/widgets/ultra_register_form.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import 'password_strength_indicator.dart';
import 'package:bookn_cp_app/injection_container.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import 'package:bookn_cp_app/features/admin_properties/data/datasources/property_types_remote_datasource.dart'
    as ap_ds_pt_remote;
import 'package:bookn_cp_app/features/admin_properties/data/models/property_type_model.dart'
    as ap_models;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart' as dio;
import '../../../../core/constants/api_constants.dart';
import '../../../../services/location_service.dart' as loc;
import 'package:async/async.dart';
import 'package:bookn_cp_app/features/admin_cities/domain/usecases/get_cities_usecase.dart'
    as ci_uc;

class RegisterForm extends StatefulWidget {
  final Function(
    String name,
    String email,
    String phone,
    String password,
    String passwordConfirmation,
    String propertyTypeId,
    String propertyName,
    String city,
    String address,
    double? latitude,
    double? longitude,
    String? description,
  ) onSubmit;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _propertyNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Focus Nodes
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _propertyNameFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _latitudeFocusNode = FocusNode();
  final _longitudeFocusNode = FocusNode();

  // State variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _showPasswordStrength = false;
  String _selectedPropertyTypeId = '';
  List<ap_models.PropertyTypeModel> _propertyTypes = const [];
  bool _loadingPropertyTypes = false;
  List<String> _cities = const [];
  bool _loadingCities = false;
  String? _selectedCity;
  String? _citiesError;
  List<_PlaceSuggestion> _addressSuggestions = const [];
  bool _loadingSuggestions = false;
  Timer? _debounce;
  String _placesSessionToken = _generatePlacesSessionToken();

  // Animation Controllers
  late AnimationController _fieldAnimationController;
  late AnimationController _checkboxAnimationController;
  late AnimationController _sectionAnimationController;
  late AnimationController _floatingAnimationController;
  late Animation<double> _floatingAnimation;

  // Page tracking
  int _currentStep = 0;
  final int _totalSteps = 2;

  @override
  void initState() {
    super.initState();

    _fieldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _checkboxAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _sectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _floatingAnimationController,
      curve: Curves.easeInOut,
    ));

    _passwordController.addListener(() {
      setState(() {
        _showPasswordStrength = _passwordController.text.isNotEmpty;
      });
    });

    // Add focus listeners
    _nameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
    _propertyNameFocusNode.addListener(() => setState(() {}));
    _cityFocusNode.addListener(() => setState(() {}));
    _addressFocusNode.addListener(() => setState(() {}));

    _loadPropertyTypes();
    _loadCities();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _propertyNameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _propertyNameFocusNode.dispose();
    _cityFocusNode.dispose();
    _addressFocusNode.dispose();
    _latitudeFocusNode.dispose();
    _longitudeFocusNode.dispose();
    _fieldAnimationController.dispose();
    _checkboxAnimationController.dispose();
    _sectionAnimationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Background decoration
            Positioned(
              top: _floatingAnimation.value,
              right: -50,
              child: _buildFloatingShape(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                size: 150,
              ),
            ),
            Positioned(
              bottom: _floatingAnimation.value * -1,
              left: -30,
              child: _buildFloatingShape(
                color: AppTheme.primaryPurple.withValues(alpha: 0.03),
                size: 120,
              ),
            ),

            // Main form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.2, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _currentStep == 0
                        ? _buildPersonalInfoStep()
                        : _buildPropertyInfoStep(),
                  ),
                  const SizedBox(height: 24),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingShape({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.1),
            AppTheme.darkCard.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isActive ? AppTheme.primaryGradient : null,
                        color: !isActive
                            ? AppTheme.darkBorder.withValues(alpha: 0.2)
                            : null,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                _buildStepCircle(index, isActive, isCompleted),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepCircle(int index, bool isActive, bool isCompleted) {
    final stepTitles = ['المعلومات الشخصية', 'بيانات الكيان'];

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isActive ? AppTheme.primaryGradient : null,
            color: !isActive ? AppTheme.darkCard.withValues(alpha: 0.3) : null,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : AppTheme.darkBorder.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                : Text(
                    '${index + 1}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isActive
                          ? Colors.white
                          : AppTheme.textMuted.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stepTitles[index],
          style: AppTextStyles.caption.copyWith(
            color: isActive
                ? AppTheme.primaryBlue
                : AppTheme.textMuted.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      key: const ValueKey('personal_info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('المعلومات الأساسية', Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _buildEnhancedField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          label: 'الاسم الكامل',
          hint: 'أدخل اسمك الكامل',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_emailFocusNode);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الاسم مطلوب';
            }
            if (value.length < 3) {
              return 'يجب أن يحتوي على 3 أحرف على الأقل';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildEnhancedField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: 'البريد الإلكتروني',
          hint: 'example@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_phoneFocusNode);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'البريد الإلكتروني مطلوب';
            }
            if (!Validators.isValidEmail(value)) {
              return 'البريد الإلكتروني غير صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildEnhancedField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          label: 'رقم الهاتف',
          hint: '967XXXXXXXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'رقم الهاتف مطلوب';
            }
            if (!Validators.isValidPhoneNumber('+$value')) {
              return 'رقم الهاتف غير صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('كلمة المرور', Icons.lock_outline_rounded),
        const SizedBox(height: 16),
        _buildEnhancedField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'كلمة المرور',
          hint: 'أدخل كلمة مرور قوية',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
          },
          suffixIcon: _buildPasswordToggle(
            obscure: _obscurePassword,
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'كلمة المرور مطلوبة';
            }
            if (!Validators.isValidPassword(value, minLength: 8)) {
              return 'يجب أن تحتوي على 8 أحرف على الأقل';
            }
            return null;
          },
        ),
        if (_showPasswordStrength) ...[
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _showPasswordStrength ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: PasswordStrengthIndicator(
              password: _passwordController.text,
              showRequirements: true,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildEnhancedField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          label: 'تأكيد كلمة المرور',
          hint: 'أعد إدخال كلمة المرور',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          suffixIcon: _buildPasswordToggle(
            obscure: _obscureConfirmPassword,
            onTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'تأكيد كلمة المرور مطلوب';
            }
            if (value != _passwordController.text) {
              return 'كلمات المرور غير متطابقة';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPropertyInfoStep() {
    return Column(
      key: const ValueKey('property_info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('معلومات الكيان', Icons.business_rounded),
        const SizedBox(height: 16),
        _buildEnhancedDropdown(
          label: 'نوع الكيان',
          icon: Icons.category_outlined,
          value:
              _selectedPropertyTypeId.isEmpty ? null : _selectedPropertyTypeId,
          items: _propertyTypes
              .map((t) => DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(t.name),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedPropertyTypeId = v ?? ''),
          isLoading: _loadingPropertyTypes,
          loadingText: 'جاري تحميل الأنواع...',
        ),
        const SizedBox(height: 16),
        _buildEnhancedField(
          controller: _propertyNameController,
          focusNode: _propertyNameFocusNode,
          label: 'اسم الكيان',
          hint: 'مثل: فندق النجوم',
          icon: Icons.apartment_rounded,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'اسم الكيان مطلوب';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildEnhancedDropdown(
          label: 'المدينة',
          icon: Icons.location_city_outlined,
          value: _selectedCity,
          items: _cities
              .map((c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedCity = v;
              _cityController.text = v ?? '';
            });
          },
          isLoading: _loadingCities,
          loadingText: 'جاري تحميل المدن...',
          error: _citiesError,
        ),
        const SizedBox(height: 16),
        _buildEnhancedField(
          controller: _addressController,
          focusNode: _addressFocusNode,
          onChanged: _onAddressChanged,
          label: 'العنوان',
          hint: 'مثل: شارع الحرية، جوار مول النور',
          icon: Icons.map_outlined,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) return 'العنوان مطلوب';
            return null;
          },
        ),
        if (_addressSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAddressSuggestionsPanel(),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedField(
                controller: _latitudeController,
                focusNode: _latitudeFocusNode,
                label: 'خط العرض',
                hint: 'Latitude',
                icon: Icons.explore_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedField(
                controller: _longitudeController,
                focusNode: _longitudeFocusNode,
                label: 'خط الطول',
                hint: 'Longitude',
                icon: Icons.explore_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMapPickerButton(),
        const SizedBox(height: 16),
        _buildEnhancedTextarea(
          controller: _descriptionController,
          label: 'وصف الكيان (اختياري)',
          hint: 'وصف مختصر عن الكيان وخدماته...',
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: 20),
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _sectionAnimationController,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: _sectionAnimationController,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.05),
                AppTheme.primaryPurple.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isFocused ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, focusValue, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isFocused)
                BoxShadow(
                  color:
                      AppTheme.primaryBlue.withValues(alpha: 0.1 * focusValue),
                  blurRadius: 20 * focusValue,
                  offset: Offset(0, 4 * focusValue),
                ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isFocused
                      ? AppTheme.primaryBlue.withValues(alpha: 0.04)
                      : AppTheme.darkCard.withValues(alpha: 0.15),
                  isFocused
                      ? AppTheme.primaryPurple.withValues(alpha: 0.03)
                      : AppTheme.darkCard.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused
                    ? AppTheme.primaryBlue.withValues(alpha: 0.4)
                    : AppTheme.darkBorder.withValues(alpha: 0.15),
                width: isFocused ? 1.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  inputFormatters: inputFormatters,
                  enabled: !widget.isLoading,
                  onChanged: onChanged,
                  onFieldSubmitted: onFieldSubmitted,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isFocused
                          ? AppTheme.primaryBlue
                          : AppTheme.textMuted.withValues(alpha: 0.6),
                      fontSize: hasText ? 11 : 13,
                      fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
                    ),
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      fontSize: 13,
                    ),
                    prefixIcon: _buildFieldIcon(icon, isFocused),
                    suffixIcon: suffixIcon,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    errorStyle: AppTextStyles.caption.copyWith(
                      color: AppTheme.error,
                      fontSize: 11,
                    ),
                  ),
                  validator: validator,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldIcon(IconData icon, bool isFocused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(10),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isFocused ? AppTheme.primaryGradient : null,
        color: !isFocused ? AppTheme.darkCard.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Icon(
        icon,
        size: 18,
        color: isFocused
            ? Colors.white
            : AppTheme.textMuted.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildEnhancedDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    bool isLoading = false,
    String? loadingText,
    String? error,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.15),
            AppTheme.darkCard.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: _buildFieldIcon(icon, false),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              errorText: error,
            ),
            dropdownColor: AppTheme.darkCard,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontSize: 14,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            items: isLoading
                ? [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(loadingText ?? 'جاري التحميل...'),
                    )
                  ]
                : items,
            onChanged: widget.isLoading ? null : onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextarea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.15),
            AppTheme.darkCard.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              prefixIcon: Container(
                width: 46,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 10),
                child: _buildFieldIcon(icon, false),
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPickerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : _openMapPicker,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.1),
                AppTheme.primaryPurple.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'تحديد الموقع على الخريطة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordToggle({
    required bool obscure,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppTheme.textMuted.withValues(alpha: 0.6),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: widget.isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              setState(() {
                _acceptTerms = !_acceptTerms;
                if (_acceptTerms) {
                  _checkboxAnimationController.forward();
                } else {
                  _checkboxAnimationController.reverse();
                }
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _acceptTerms
                  ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                  : AppTheme.darkCard.withValues(alpha: 0.1),
              _acceptTerms
                  ? AppTheme.primaryPurple.withValues(alpha: 0.03)
                  : AppTheme.darkCard.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _acceptTerms
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : AppTheme.darkBorder.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: _acceptTerms ? AppTheme.primaryGradient : null,
                color: !_acceptTerms
                    ? AppTheme.darkCard.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _acceptTerms
                      ? Colors.transparent
                      : AppTheme.darkBorder.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: _acceptTerms
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: _acceptTerms
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  children: [
                    const TextSpan(text: 'أوافق على '),
                    TextSpan(
                      text: 'الشروط والأحكام',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    const TextSpan(text: ' و'),
                    TextSpan(
                      text: 'سياسة الخصوصية',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: _buildSecondaryButton(
              onTap: () {
                setState(() {
                  _currentStep--;
                });
              },
              label: 'السابق',
              icon: Icons.arrow_back_rounded,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _currentStep < _totalSteps - 1
              ? _buildPrimaryButton(
                  onTap: () {
                    if (_validateCurrentStep()) {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  },
                  label: 'التالي',
                  icon: Icons.arrow_forward_rounded,
                  iconAtEnd: true,
                )
              : _buildSubmitButton(),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    bool iconAtEnd = false,
  }) {
    return GestureDetector(
      onTap: widget.isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: widget.isLoading
              ? LinearGradient(
                  colors: [
                    AppTheme.darkCard.withValues(alpha: 0.3),
                    AppTheme.darkCard.withValues(alpha: 0.2),
                  ],
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: !widget.isLoading
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!iconAtEnd) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (iconAtEnd) ...[
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: widget.isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = !widget.isLoading;

    return GestureDetector(
      onTap: canSubmit ? _onSubmit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 52,
        decoration: BoxDecoration(
          gradient: canSubmit
              ? AppTheme.primaryGradient
              : LinearGradient(
                  colors: [
                    AppTheme.darkCard.withValues(alpha: 0.3),
                    AppTheme.darkCard.withValues(alpha: 0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: widget.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'جاري إنشاء الحساب...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إنشاء الحساب',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      // Validate personal info
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _showError('يرجى ملء جميع الحقول المطلوبة');
        return false;
      }
      if (!Validators.isValidEmail(_emailController.text)) {
        _showError('البريد الإلكتروني غير صحيح');
        return false;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('كلمات المرور غير متطابقة');
        return false;
      }
      return true;
    }
    return true;
  }

  void _onSubmit() {
    if (!_acceptTerms) {
      HapticFeedback.lightImpact();
      _showError('يجب الموافقة على الشروط والأحكام');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      HapticFeedback.mediumImpact();

      if (_selectedPropertyTypeId.isEmpty) {
        _showError('نوع الكيان مطلوب');
        return;
      }

      widget.onSubmit(
        _nameController.text.trim(),
        _emailController.text.trim(),
        '+${_phoneController.text.trim()}',
        _passwordController.text,
        _confirmPasswordController.text,
        _selectedPropertyTypeId,
        _propertyNameController.text.trim(),
        _cityController.text.trim(),
        _addressController.text.trim(),
        _tryParseDouble(_latitudeController.text.trim()),
        _tryParseDouble(_longitudeController.text.trim()),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.error.withValues(alpha: 0.9),
                AppTheme.error.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double? _tryParseDouble(String v) {
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  Widget _buildAddressSuggestionsPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          itemCount: _addressSuggestions.length,
          separatorBuilder: (context, index) => Divider(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final suggestion = _addressSuggestions[index];
            return InkWell(
              onTap: () => _selectPlaceSuggestion(suggestion),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper methods remain the same
  Future<void> _loadPropertyTypes() async {
    setState(() => _loadingPropertyTypes = true);
    try {
      final ds = sl<ap_ds_pt_remote.PropertyTypesRemoteDataSource>();
      final PaginatedResult<ap_models.PropertyTypeModel> result =
          await ds.getAllPropertyTypes(pageNumber: 1, pageSize: 1000);
      setState(() {
        _propertyTypes = result.items;
      });
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loadingPropertyTypes = false);
    }
  }

  Future<void> _loadCities() async {
    setState(() {
      _loadingCities = true;
      _citiesError = null;
    });
    try {
      final usecase = sl<ci_uc.GetCitiesUseCase>();
      final result = await usecase(const ci_uc.GetCitiesParams());
      result.fold(
        (_) => setState(() {
          _citiesError = 'تعذر تحميل المدن';
          _loadingCities = false;
        }),
        (list) => setState(() {
          _cities = list.map((c) => c.name).toList();
          _loadingCities = false;
          if (_cities.contains(_cityController.text)) {
            _selectedCity = _cityController.text;
          } else {
            _selectedCity = null;
            _cityController.text = '';
          }
        }),
      );
    } catch (_) {
      setState(() {
        _citiesError = 'تعذر تحميل المدن';
        _loadingCities = false;
      });
    }
  }

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        setState(() => _addressSuggestions = const []);
        return;
      }
      _fetchPlaceAutocomplete(value.trim());
    });
  }

  Future<void> _fetchPlaceAutocomplete(String input) async {
    const apiKey = ApiConstants.googlePlacesApiKey;

    setState(() => _loadingSuggestions = true);

    try {
      final client = dio.Dio();

      final response = await client.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: {
          'input': input,
          'languageCode': 'ar',
          'regionCode': 'YE',
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'suggestions.placePrediction.text,suggestions.placePrediction.placeId',
          },
        ),
      );

      if (response.statusCode == 200) {
        final suggestions = response.data['suggestions'] as List? ?? [];

        setState(() {
          _addressSuggestions = suggestions.map((s) {
            final prediction = s['placePrediction'];
            return _PlaceSuggestion(
              description: prediction?['text']?['text'] ?? '',
              placeId: prediction?['placeId'] ?? '',
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _selectPlaceSuggestion(_PlaceSuggestion s) async {
    _addressController.text = s.description;
    setState(() => _addressSuggestions = const []);
    if (ApiConstants.googlePlacesApiKey.isEmpty) return;
    try {
      final client = dio.Dio();
      final resp = await client.get(
        '${ApiConstants.googlePlacesBaseUrl}/details/json',
        queryParameters: {
          'place_id': s.placeId,
          'key': ApiConstants.googlePlacesApiKey,
          'language': 'ar',
          'sessiontoken': _placesSessionToken,
        },
      );
      final result = resp.data['result'];
      final loc = result['geometry']?['location'];
      if (loc != null) {
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        _latitudeController.text = lat.toStringAsFixed(6);
        _longitudeController.text = lng.toStringAsFixed(6);
        final comps = (result['address_components'] as List?) ?? [];
        final cityComp = comps.firstWhere(
          (c) =>
              ((c['types'] as List?) ?? []).contains('locality') ||
              ((c['types'] as List?) ?? [])
                  .contains('administrative_area_level_1'),
          orElse: () => null,
        );
        if (cityComp != null) {
          final cityName = (cityComp['long_name'] ?? '').toString();
          if (cityName.isNotEmpty) {
            _cityController.text = cityName;
          }
        }
      }
    } catch (_) {}
    _placesSessionToken = _generatePlacesSessionToken();
  }

  void _openMapPicker() {
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _EnhancedMapPickerDialog(
        initialLocation: _tryParseDouble(_latitudeController.text) != null &&
                _tryParseDouble(_longitudeController.text) != null
            ? LatLng(
                _tryParseDouble(_latitudeController.text)!,
                _tryParseDouble(_longitudeController.text)!,
              )
            : null,
        onLocationSelected: (location, address) async {
          _latitudeController.text = location.latitude.toStringAsFixed(6);
          _longitudeController.text = location.longitude.toStringAsFixed(6);
          if (address != null && address.isNotEmpty) {
            _addressController.text = address;
          } else {
            try {
              final svc = sl<loc.LocationService>();
              final addr = await svc.getAddressFromCoordinates(
                location.latitude,
                location.longitude,
              );
              if (addr != null) {
                _addressController.text = addr.formattedAddress;
                if ((addr.locality ?? '').isNotEmpty) {
                  _cityController.text = addr.locality!;
                }
              }
            } catch (_) {}
          }
          setState(() {});
        },
      ),
    );
  }
}

class _PlaceSuggestion {
  final String description;
  final String placeId;
  _PlaceSuggestion({required this.description, required this.placeId});
}

class _EnhancedMapPickerDialog extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String?) onLocationSelected;

  const _EnhancedMapPickerDialog({
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<_EnhancedMapPickerDialog> createState() =>
      _EnhancedMapPickerDialogState();
}

class _EnhancedMapPickerDialogState extends State<_EnhancedMapPickerDialog>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  Set<Marker> _markers = {};
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();

    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _updateMarker(_selectedLocation!);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target:
                          _selectedLocation ?? const LatLng(15.3694, 44.1910),
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _markers,
                    onTap: (location) {
                      _updateMarker(location);
                      _selectedAddress =
                          'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                  ),

                  // Header
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 20,
                        right: 20,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.darkCard,
                            AppTheme.darkCard.withValues(alpha: 0.95),
                            AppTheme.darkCard.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.darkSurface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.darkBorder
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppTheme.textWhite,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'تحديد الموقع على الخريطة',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Actions
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.darkCard,
                            AppTheme.darkCard.withValues(alpha: 0.95),
                            AppTheme.darkCard.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppTheme.darkBorder
                                        .withValues(alpha: 0.3),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectedLocation != null
                                  ? () {
                                      widget.onLocationSelected(
                                        _selectedLocation!,
                                        _selectedAddress,
                                      );
                                      Navigator.pop(context);
                                    }
                                  : null,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: _selectedLocation != null
                                      ? AppTheme.primaryGradient
                                      : null,
                                  color: _selectedLocation == null
                                      ? AppTheme.darkSurface
                                          .withValues(alpha: 0.5)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _selectedLocation != null
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryBlue
                                                .withValues(alpha: 0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'تأكيد الموقع',
                                    style: AppTextStyles.buttonMedium.copyWith(
                                      color: _selectedLocation != null
                                          ? Colors.white
                                          : AppTheme.textMuted
                                              .withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _generatePlacesSessionToken() =>
    'sess_${DateTime.now().microsecondsSinceEpoch}';
