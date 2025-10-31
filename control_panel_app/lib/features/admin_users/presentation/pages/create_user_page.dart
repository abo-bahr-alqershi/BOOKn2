// lib/features/admin_users/presentation/pages/create_user_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/users_list/users_list_bloc.dart';
import '../bloc/user_details/user_details_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_details.dart';

class CreateUserPage extends StatefulWidget {
  final String? userId; // if provided -> edit mode
  final User? initialUser; // For edit mode
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialRoleId;

  const CreateUserPage({
    super.key,
    this.userId,
    this.initialUser,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
    this.initialRoleId,
  });

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _loadingRotation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // State
  String? _selectedRole;
  bool _isPasswordVisible = false;
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isPrefilledFromExtras = false;
  bool _emailConfirmed = false;
  bool _phoneNumberConfirmed = false;

  // Edit specific state
  bool _isDataLoaded = false;
  bool _hasChanges = false;

  // Original values for comparison
  String? _originalName;
  String? _originalEmail;
  String? _originalPhone;
  String? _originalRole;
  bool? _originalEmailConfirmed;
  bool? _originalPhoneConfirmed;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.userId != null) {
      if (widget.initialUser != null) {
        _loadUserData(widget.initialUser!, shouldSetState: false);
      } else if (_hasInitialFieldData) {
        _prefillFromInitialFields(shouldSetState: false);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserFromApi();
        }
      });
    } else {
      _isDataLoaded = true;
    }

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
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

  String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _loadUserFromApi() {
    final userId = widget.userId;
    if (userId == null) return;

    context.read<UserDetailsBloc>().add(
          LoadUserDetailsEvent(userId: userId),
        );
  }

  void _loadUserData(User user, {bool shouldSetState = true}) {
    void apply() {
      _isDataLoaded = true;
      _isPrefilledFromExtras = false;

      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = _digitsOnly(user.phone);
      _selectedRole = user.role.isEmpty ? null : user.role;
      _emailConfirmed = user.emailConfirmed;
      _phoneNumberConfirmed = user.phoneNumberConfirmed;

      _originalName = user.name;
      _originalEmail = user.email;
      _originalPhone = user.phone;
      _originalRole = user.role.isEmpty ? null : user.role;
      _originalEmailConfirmed = user.emailConfirmed;
      _originalPhoneConfirmed = user.phoneNumberConfirmed;
      _hasChanges = false;
    }

    if (shouldSetState && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _prefillFromInitialFields({bool shouldSetState = true}) {
    void apply() {
      _isPrefilledFromExtras = true;
      _isDataLoaded = true;

      final role = widget.initialRoleId;
      final roleValue = role != null && role.isEmpty ? null : role;

      _nameController.text = widget.initialName ?? '';
      _emailController.text = widget.initialEmail ?? '';
      _phoneController.text = _digitsOnly(widget.initialPhone ?? '');
      _selectedRole = roleValue;

      _originalName = widget.initialName ?? '';
      _originalEmail = widget.initialEmail ?? '';
      _originalPhone = widget.initialPhone ?? '';
      _originalRole = roleValue;
      _hasChanges = false;
    }

    if (shouldSetState && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  bool get _hasInitialFieldData =>
      widget.initialName != null ||
      widget.initialEmail != null ||
      widget.initialPhone != null ||
      widget.initialRoleId != null;

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _loadingAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.userId != null;

    final scaffold = Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: !_isDataLoaded && isEditMode
                ? _buildLoadingState()
                : Column(
                    children: [
                      _buildHeader(),
                      _buildProgressIndicator(),
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildFormContent(),
                          ),
                        ),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
          ),
        ],
      ),
    );

    Widget content;
    if (isEditMode) {
      content = MultiBlocListener(
        listeners: [
          BlocListener<UserDetailsBloc, UserDetailsState>(
            listener: _handleUserDetailsState,
          ),
          BlocListener<UsersListBloc, UsersListState>(
            listener: _handleUsersListState,
          ),
        ],
        child: scaffold,
      );
    } else {
      content = BlocListener<UsersListBloc, UsersListState>(
        listener: _handleUsersListState,
        child: scaffold,
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: content,
    );
  }

  void _handleUserDetailsState(
    BuildContext context,
    UserDetailsState state,
  ) {
    if (!mounted) return;

    if (state is UserDetailsLoading &&
        !_isPrefilledFromExtras &&
        !_isDataLoaded) {
      setState(() {
        _isDataLoaded = false;
      });
    }

    if (state is UserDetailsLoaded) {
      final user = _mapUserDetailsToUser(state.userDetails);
      _loadUserData(user);
    }

    if (state is UserDetailsError) {
      if (!_isDataLoaded) {
        setState(() {
          _isDataLoaded = true;
        });
      }
      _showErrorMessage(state.message);
    }
  }

  void _handleUsersListState(
    BuildContext context,
    UsersListState state,
  ) {
    // Handle success state
    if (state is UserOperationSuccess) {
      if (_isSubmitting) {
        _showSuccessMessage(state.message);
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pop(true);
          }
        });
      }
    }

    // Handle error state - ALWAYS stop the progress bar if there's an error
    if (state is UsersListError) {
      _showErrorMessage(state.message);
      // Stop submitting state regardless of current value to ensure UI updates
      if (mounted && _isSubmitting) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    // Safety check: if loading state appears while we think we're submitting,
    // it means a new operation started, so keep the loading indicator
    if (state is UsersListLoading && !_isSubmitting) {
      // This shouldn't happen, but if it does, sync the state
      if (mounted) {
        setState(() {
          _isSubmitting = true;
        });
      }
    }
  }

  User _mapUserDetailsToUser(UserDetails details) {
    return User(
      id: details.id,
      name: details.userName,
      role: details.role ?? '',
      email: details.email,
      phone: details.phoneNumber,
      profileImage: details.avatarUrl,
      createdAt: details.createdAt,
      isActive: details.isActive,
      emailConfirmed: details.emailConfirmed,
      phoneNumberConfirmed: details.phoneNumberConfirmed,
      settings: null,
      favorites: null,
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
            painter: _CreateUserBackgroundPainter(
              glowIntensity: _glowController.value,
              isEditMode: widget.userId != null,
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
                          Icons.person_rounded,
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
              'جاري تحميل بيانات المستخدم...',
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
    final isEditMode = widget.userId != null;

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
                        isEditMode ? 'تعديل المستخدم' : 'إضافة مستخدم جديد',
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isEditMode && _hasChanges) ...[
                      const SizedBox(width: 8),
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isEditMode
                      ? (_originalName != null && _originalName!.isNotEmpty
                          ? _originalName!
                          : 'قم بتعديل البيانات المطلوبة')
                      : 'قم بملء البيانات المطلوبة لإضافة المستخدم',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Reset Button (only in edit mode with changes)
          if (isEditMode && _hasChanges)
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
      'معلومات الاتصال',
      'الصلاحيات',
      'المراجعة'
    ];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          final isModified = widget.userId != null && _hasChangesInStep(index);

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
    return Form(
      key: _formKey,
      onChanged: () {
        if (widget.userId != null) {
          setState(() {
            _hasChanges = _checkForChanges();
          });
        }
      },
      child: IndexedStack(
        index: _currentStep,
        children: [
          _buildBasicInfoStep(),
          _buildContactStep(),
          _buildPermissionsStep(),
          _buildReviewStep(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    final isEditMode = widget.userId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Change Indicator for Name
          if (isEditMode && _originalName != null)
            _buildOriginalValueIndicator(
              'الاسم الأصلي',
              _originalName!,
              _nameController.text != _originalName,
            ),

          // Name
          _buildInputField(
            controller: _nameController,
            label: 'الاسم الكامل',
            hint: 'أدخل الاسم الكامل',
            icon: Icons.person_rounded,
            validator: Validators.validateName,
          ),

          const SizedBox(height: 20),

          // Change Indicator for Email
          if (isEditMode && _originalEmail != null)
            _buildOriginalValueIndicator(
              'البريد الإلكتروني الأصلي',
              _originalEmail!,
              _emailController.text != _originalEmail,
            ),

          // Email
          _buildInputField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'أدخل البريد الإلكتروني',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),

          const SizedBox(height: 16),

          // Email Confirmation Switch
          _buildConfirmationSwitch(
            title: 'تأكيد البريد الإلكتروني',
            subtitle: 'تفعيل هذا الخيار يعني أن البريد الإلكتروني مؤكد',
            value: _emailConfirmed,
            icon: Icons.mark_email_read_rounded,
            color: AppTheme.success,
            onChanged: (value) {
              setState(() {
                _emailConfirmed = value;
              });
            },
            showChangeIndicator: isEditMode && _originalEmailConfirmed != null && _emailConfirmed != _originalEmailConfirmed,
            originalValue: _originalEmailConfirmed,
          ),

          const SizedBox(height: 20),

          // Password (only in create mode)
          if (!isEditMode) ...[
            _buildPasswordField(),
          ] else ...[
            _buildChangePasswordCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    final isEditMode = widget.userId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Change Indicator for Phone
          if (isEditMode && _originalPhone != null)
            _buildOriginalValueIndicator(
              'رقم الهاتف الأصلي',
              _originalPhone!.isEmpty ? 'غير محدد' : _originalPhone!,
              _phoneController.text != _originalPhone,
            ),

          // Phone
          _buildInputField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            hint: '967XXXXXXXXX',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
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

          const SizedBox(height: 16),

          // Phone Confirmation Switch
          _buildConfirmationSwitch(
            title: 'تأكيد رقم الهاتف',
            subtitle: 'تفعيل هذا الخيار يعني أن رقم الهاتف مؤكد',
            value: _phoneNumberConfirmed,
            icon: Icons.phone_in_talk_rounded,
            color: AppTheme.primaryCyan,
            onChanged: (value) {
              setState(() {
                _phoneNumberConfirmed = value;
              });
            },
            showChangeIndicator: isEditMode && _originalPhoneConfirmed != null && _phoneNumberConfirmed != _originalPhoneConfirmed,
            originalValue: _originalPhoneConfirmed,
          ),

          const SizedBox(height: 20),

          // Additional contact info card
          _buildInfoCard(
            icon: Icons.info_rounded,
            title: 'معلومات إضافية',
            description:
                'يمكنك إضافة معلومات اتصال إضافية لاحقاً من صفحة تفاصيل المستخدم',
            color: AppTheme.info,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دور المستخدم',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.userId != null && _originalRole != null)
            Text(
              'الدور الحالي: ${_getRoleText(_originalRole!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          const SizedBox(height: 16),

          // Role Selector
          ..._buildRoleOptions(),
        ],
      ),
    );
  }

  List<Widget> _buildRoleOptions() {
    final roles = [
      {
        'id': 'admin',
        'name': 'مدير',
        'description': 'صلاحيات كاملة على النظام',
        'icon': Icons.admin_panel_settings_rounded,
        'gradient': [AppTheme.error, AppTheme.primaryViolet],
      },
      {
        'id': 'owner',
        'name': 'مالك',
        'description': 'مالك كيان أو عقار',
        'icon': Icons.business_rounded,
        'gradient': [AppTheme.primaryBlue, AppTheme.primaryPurple],
      },
      {
        'id': 'staff',
        'name': 'موظف',
        'description': 'موظف في كيان أو عقار',
        'icon': Icons.badge_rounded,
        'gradient': [AppTheme.warning, AppTheme.neonBlue],
      },
      {
        'id': 'customer',
        'name': 'عميل',
        'description': 'مستخدم عادي للخدمة',
        'icon': Icons.person_rounded,
        'gradient': [AppTheme.primaryCyan, AppTheme.neonGreen],
      },
    ];

    return roles.map((role) {
      final isSelected = _selectedRole == role['id'];
      final hasChanged = widget.userId != null &&
          _originalRole != null &&
          role['id'] == _selectedRole &&
          _selectedRole != _originalRole;

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role['id'] as String;
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      (role['gradient'] as List<Color>)[0]
                          .withOpacity(hasChanged ? 0.15 : 0.1),
                      (role['gradient'] as List<Color>)[1]
                          .withOpacity(hasChanged ? 0.08 : 0.05),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.5),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasChanged
                  ? AppTheme.warning.withOpacity(0.5)
                  : isSelected
                      ? (role['gradient'] as List<Color>)[0].withOpacity(0.5)
                      : AppTheme.darkBorder.withOpacity(0.3),
              width: hasChanged ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: hasChanged
                          ? AppTheme.warning.withOpacity(0.2)
                          : (role['gradient'] as List<Color>)[0]
                              .withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: role['gradient'] as List<Color>,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  role['icon'] as IconData,
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
                      role['name'] as String,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role['description'] as String,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    if (hasChanged) ...[
                      const SizedBox(height: 4),
                      Text(
                        'كان: ${_getRoleText(_originalRole!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.warning,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasChanged
                          ? [
                              AppTheme.warning,
                              AppTheme.warning.withOpacity(0.7)
                            ]
                          : role['gradient'] as List<Color>,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildReviewStep() {
    final isEditMode = widget.userId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isEditMode ? 'مراجعة التغييرات' : 'مراجعة البيانات',
                style: AppTextStyles.heading2.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isEditMode && _hasChanges) ...[
                const SizedBox(width: 12),
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
            ],
          ),
          const SizedBox(height: 20),

          // Changes Summary (for edit mode)
          if (isEditMode && _hasChanges) ...[
            _buildChangesSummary(),
            const SizedBox(height: 20),
          ],

          // Validation summary
          Builder(builder: (context) {
            final errors = _getReviewValidationErrors();
            if (errors.isEmpty) return const SizedBox.shrink();
            return _buildValidationSummary(errors);
          }),
          if (_getReviewValidationErrors().isNotEmpty)
            const SizedBox(height: 16),

          // Review Cards
          _buildReviewCard(
            title: 'المعلومات الأساسية',
            icon: Icons.person_rounded,
            iconColor: AppTheme.primaryBlue,
            items: [
              {
                'label': 'الاسم',
                'value': _nameController.text,
                'changed': isEditMode && _nameController.text != _originalName
              },
              {
                'label': 'البريد الإلكتروني',
                'value': _emailController.text,
                'changed': isEditMode && _emailController.text != _originalEmail
              },
              {
                'label': 'تأكيد البريد الإلكتروني',
                'value': _emailConfirmed ? 'مؤكد ✓' : 'غير مؤكد ✕',
                'changed': isEditMode && _emailConfirmed != (_originalEmailConfirmed ?? false)
              },
              if (!isEditMode)
                {'label': 'كلمة المرور', 'value': '••••••••', 'changed': false},
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'معلومات الاتصال',
            icon: Icons.phone_rounded,
            iconColor: AppTheme.success,
            items: [
              {
                'label': 'رقم الهاتف',
                'value': _phoneController.text.isEmpty
                    ? 'غير محدد'
                    : _phoneController.text,
                'changed': isEditMode && _phoneController.text != _originalPhone
              },
              {
                'label': 'تأكيد رقم الهاتف',
                'value': _phoneNumberConfirmed ? 'مؤكد ✓' : 'غير مؤكد ✕',
                'changed': isEditMode && _phoneNumberConfirmed != (_originalPhoneConfirmed ?? false)
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'الصلاحيات',
            icon: Icons.security_rounded,
            iconColor: AppTheme.warning,
            items: [
              {
                'label': 'الدور',
                'value': _getRoleText(_selectedRole ?? ''),
                'changed': isEditMode && _selectedRole != _originalRole
              },
            ],
          ),
        ],
      ),
    );
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

  Widget _buildChangePasswordCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withOpacity(0.1),
            AppTheme.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_reset_rounded,
            color: AppTheme.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تغيير كلمة المرور',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'يمكن تغيير كلمة المرور من صفحة إعدادات المستخدم',
                  style: AppTextStyles.caption.copyWith(
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
            inputFormatters: inputFormatters,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                color: AppTheme.primaryBlue.withOpacity(0.7),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كلمة المرور',
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
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل كلمة المرور',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                Icons.lock_rounded,
                color: AppTheme.primaryBlue.withOpacity(0.7),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: Validators.validatePassword,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
    bool showChangeIndicator = false,
    bool? originalValue,
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
          color: showChangeIndicator
              ? AppTheme.warning.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: showChangeIndicator ? 2 : 1,
        ),
        boxShadow: showChangeIndicator
            ? [
                BoxShadow(
                  color: AppTheme.warning.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: value
                    ? [color, color.withOpacity(0.7)]
                    : [
                        AppTheme.darkSurface.withOpacity(0.5),
                        AppTheme.darkSurface.withOpacity(0.3)
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: value ? Colors.white : AppTheme.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (showChangeIndicator) ...[
                      const SizedBox(width: 8),
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                if (showChangeIndicator && originalValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'القيمة الأصلية: ${originalValue ? "مؤكد" : "غير مؤكد"}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.5),
            inactiveThumbColor: AppTheme.darkSurface,
            inactiveTrackColor: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
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

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required Color iconColor,
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasChanges
                        ? [AppTheme.warning, AppTheme.warning.withOpacity(0.7)]
                        : [iconColor, iconColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasChanges ? AppTheme.warning : iconColor,
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
                        Icon(
                          _getItemIcon(item['label']!),
                          size: 14,
                          color: item['changed'] == true
                              ? AppTheme.warning.withOpacity(0.7)
                              : AppTheme.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
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

  Widget _buildActionButtons() {
    final isEditMode = widget.userId != null;

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
            child: BlocBuilder<UsersListBloc, UsersListState>(
              builder: (context, state) {
                final bool isSubmitting =
                    _isSubmitting || state is UsersListLoading;
                return GestureDetector(
                  onTap: isSubmitting
                      ? null
                      : (_currentStep < 3 ? _nextStep : _submitForm),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isEditMode && _hasChanges
                          ? LinearGradient(colors: [
                              AppTheme.warning,
                              AppTheme.warning.withOpacity(0.8)
                            ])
                          : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isEditMode && _hasChanges
                              ? AppTheme.warning.withOpacity(0.3)
                              : AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_currentStep == 3 &&
                                    isEditMode &&
                                    _hasChanges)
                                  const Icon(
                                    Icons.save_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                if (_currentStep == 3 &&
                                    isEditMode &&
                                    _hasChanges)
                                  const SizedBox(width: 8),
                                Text(
                                  _currentStep < 3
                                      ? 'التالي'
                                      : isEditMode
                                          ? _hasChanges
                                              ? 'حفظ التغييرات'
                                              : 'لا توجد تغييرات'
                                          : 'إنشاء المستخدم',
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationSummary(List<String> errors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withOpacity(0.10),
            AppTheme.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.35),
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
                  color: AppTheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'يرجى مراجعة الأخطاء التالية',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...errors.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Helper Methods
  bool _checkForChanges() {
    if (widget.userId == null) return false;

    final currentRole = _selectedRole ?? '';
    final originalRole = _originalRole ?? '';

    return _nameController.text != (_originalName ?? '') ||
        _emailController.text != (_originalEmail ?? '') ||
        _phoneController.text != (_originalPhone ?? '') ||
        currentRole != originalRole ||
        _emailConfirmed != (_originalEmailConfirmed ?? false) ||
        _phoneNumberConfirmed != (_originalPhoneConfirmed ?? false);
  }

  bool _hasChangesInStep(int step) {
    if (widget.userId == null) return false;

    switch (step) {
      case 0: // Basic Info
        return _nameController.text != (_originalName ?? '') ||
            _emailController.text != (_originalEmail ?? '') ||
            _emailConfirmed != (_originalEmailConfirmed ?? false);
      case 1: // Contact
        return _phoneController.text != (_originalPhone ?? '') ||
            _phoneNumberConfirmed != (_originalPhoneConfirmed ?? false);
      case 2: // Permissions
        final currentRole = _selectedRole ?? '';
        final originalRole = _originalRole ?? '';
        return currentRole != originalRole;
      default:
        return false;
    }
  }

  List<Map<String, String>> _getChangedFields() {
    final changes = <Map<String, String>>[];
    if (widget.userId == null) return changes;

    final originalName = _originalName ?? '';
    final originalEmail = _originalEmail ?? '';
    final originalPhone = _originalPhone ?? '';
    final originalRole = _originalRole ?? '';

    if (_nameController.text != originalName) {
      changes.add({
        'field': 'الاسم',
        'oldValue': originalName.isEmpty ? 'غير محدد' : originalName,
        'newValue': _nameController.text,
      });
    }

    if (_emailController.text != originalEmail) {
      changes.add({
        'field': 'البريد الإلكتروني',
        'oldValue': originalEmail.isEmpty ? 'غير محدد' : originalEmail,
        'newValue': _emailController.text,
      });
    }

    if (_phoneController.text != originalPhone) {
      changes.add({
        'field': 'رقم الهاتف',
        'oldValue': originalPhone.isEmpty ? 'غير محدد' : originalPhone,
        'newValue':
            _phoneController.text.isEmpty ? 'غير محدد' : _phoneController.text,
      });
    }

    final currentRole = _selectedRole ?? '';
    if (currentRole != originalRole) {
      changes.add({
        'field': 'الدور',
        'oldValue': _getRoleText(originalRole),
        'newValue': _getRoleText(currentRole),
      });
    }

    if (_emailConfirmed != (_originalEmailConfirmed ?? false)) {
      changes.add({
        'field': 'تأكيد البريد الإلكتروني',
        'oldValue': (_originalEmailConfirmed ?? false) ? 'مؤكد' : 'غير مؤكد',
        'newValue': _emailConfirmed ? 'مؤكد' : 'غير مؤكد',
      });
    }

    if (_phoneNumberConfirmed != (_originalPhoneConfirmed ?? false)) {
      changes.add({
        'field': 'تأكيد رقم الهاتف',
        'oldValue': (_originalPhoneConfirmed ?? false) ? 'مؤكد' : 'غير مؤكد',
        'newValue': _phoneNumberConfirmed ? 'مؤكد' : 'غير مؤكد',
      });
    }

    return changes;
  }

  void _resetChanges() {
    if (widget.userId == null) return;

    showDialog(
      context: context,
      builder: (context) => _ResetConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);

          // Reset all values
          setState(() {
            _nameController.text = _originalName ?? '';
            _emailController.text = _originalEmail ?? '';
            _phoneController.text = _originalPhone ?? '';
            _selectedRole = _originalRole;
            _emailConfirmed = _originalEmailConfirmed ?? false;
            _phoneNumberConfirmed = _originalPhoneConfirmed ?? false;
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
      if (widget.userId != null && _hasChanges) {
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
      // Validate current step
      bool isValid = true;

      if (_currentStep == 0) {
        isValid = _validateBasicInfo();
      } else if (_currentStep == 1) {
        isValid = _validateContact();
      } else if (_currentStep == 2) {
        isValid = _validatePermissions();
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    final isEditing = widget.userId != null;
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        (!isEditing && _passwordController.text.isEmpty)) {
      _showErrorMessage('الرجاء ملء جميع الحقول المطلوبة');
      return false;
    }
    return true;
  }

  bool _validateContact() {
    if (_phoneController.text.isEmpty) {
      _showErrorMessage('الرجاء إدخال رقم الهاتف');
      return false;
    }
    return true;
  }

  bool _validatePermissions() {
    if (_selectedRole == null) {
      _showErrorMessage('الرجاء اختيار دور المستخدم');
      return false;
    }
    return true;
  }

  void _submitForm() {
    // Prevent multiple submissions
    if (_isSubmitting) {
      return;
    }

    final isEditMode = widget.userId != null;

    // Check for changes in edit mode
    if (isEditMode && !_hasChanges) {
      _showInfoMessage('لا توجد تغييرات للحفظ');
      return;
    }

    // Validate
    final reviewErrors = _getReviewValidationErrors();
    if (reviewErrors.isNotEmpty) {
      _showErrorMessage('يرجى تصحيح الأخطاء قبل الحفظ');
      setState(() {});
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      if (!isEditMode) {
        context.read<UsersListBloc>().add(
              CreateUserEvent(
                name: _nameController.text,
                email: _emailController.text,
                password: _passwordController.text,
                phone: _phoneController.text,
                roleId: _selectedRole,
                emailConfirmed: _emailConfirmed,
                phoneNumberConfirmed: _phoneNumberConfirmed,
              ),
            );
      } else {
        context.read<UsersListBloc>().add(
              UpdateUserEvent(
                userId: widget.userId!,
                name: _nameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                roleId: _selectedRole,
                emailConfirmed: _emailConfirmed,
                phoneNumberConfirmed: _phoneNumberConfirmed,
              ),
            );
      }
    }
  }

  List<String> _getReviewValidationErrors() {
    final List<String> errors = [];

    final nameError = Validators.validateName(_nameController.text);
    if (nameError != null) errors.add(nameError);

    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) errors.add(emailError);

    if (widget.userId == null) {
      final pwdError = Validators.validatePassword(_passwordController.text);
      if (pwdError != null) errors.add(pwdError);
    }

    final phoneError = Validators.validatePhone(_phoneController.text);
    if (phoneError != null) errors.add(phoneError);

    if (_selectedRole == null || _selectedRole!.isEmpty) {
      errors.add('يرجى اختيار دور المستخدم');
    }

    return errors;
  }

  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير';
      case 'owner':
        return 'مالك';
      case 'staff':
        return 'موظف';
      case 'customer':
        return 'عميل';
      default:
        return role.isEmpty ? 'غير محدد' : role;
    }
  }

  IconData _getItemIcon(String label) {
    switch (label) {
      case 'الاسم':
        return Icons.person_rounded;
      case 'البريد الإلكتروني':
        return Icons.email_rounded;
      case 'كلمة المرور':
        return Icons.lock_rounded;
      case 'رقم الهاتف':
        return Icons.phone_rounded;
      case 'تأكيد البريد الإلكتروني':
        return Icons.mark_email_read_rounded;
      case 'تأكيد رقم الهاتف':
        return Icons.phone_in_talk_rounded;
      case 'الدور':
        return Icons.security_rounded;
      default:
        return Icons.info_rounded;
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
}

// Additional Dialogs
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

// Background Painter
class _CreateUserBackgroundPainter extends CustomPainter {
  final double glowIntensity;
  final bool isEditMode;

  _CreateUserBackgroundPainter({
    required this.glowIntensity,
    this.isEditMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw glowing orbs
    final primaryColor = isEditMode ? AppTheme.warning : AppTheme.primaryBlue;

    paint.shader = RadialGradient(
      colors: [
        primaryColor.withOpacity(0.1 * glowIntensity),
        primaryColor.withOpacity(0.05 * glowIntensity),
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
