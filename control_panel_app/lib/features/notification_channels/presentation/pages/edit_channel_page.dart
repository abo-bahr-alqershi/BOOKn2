// lib/features/notifications/presentation/pages/edit_channel_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/notification_channel.dart';
import '../bloc/channels_bloc.dart';
import '../bloc/channels_event.dart';
import '../bloc/channels_state.dart';

class EditChannelPage extends StatefulWidget {
  final String channelId;

  const EditChannelPage({
    super.key,
    required this.channelId,
  });

  @override
  State<EditChannelPage> createState() => _EditChannelPageState();
}

class _EditChannelPageState extends State<EditChannelPage>
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State
  int _currentStep = 0;
  String _selectedType = 'CUSTOM';
  String _selectedIcon = '📢';
  String _selectedColor = '#1E88E5';
  bool _isPrivate = false;
  bool _isActive = true;
  List<String> _selectedRoles = [];

  // Edit specific state
  NotificationChannel? _originalChannel;
  bool _isDataLoaded = false;
  bool _hasChanges = false;

  // Original values for tracking changes
  String? _originalName;
  String? _originalDescription;
  String? _originalIcon;
  String? _originalColor;
  bool? _originalIsPrivate;
  bool? _originalIsActive;
  List<String> _originalRoles = [];

  // Available Options
  final List<String> _availableTypes = [
    'CUSTOM',
    'ROLE_BASED',
    'EVENT_BASED',
    'BROADCAST',
    'PRIVATE',
    'SYSTEM',
  ];

  final List<String> _availableIcons = [
    '📢',
    '🔔',
    '📣',
    '📡',
    '📮',
    '📤',
    '💬',
    '📻',
    '🎯',
    '⚡',
    '🚀',
    '💎',
    '🎉',
    '🏆',
    '⭐',
    '🌟',
    '📨',
    '📧',
    '📩',
    '💌',
    '📝',
    '📄',
    '📃',
    '📋',
  ];

  final List<String> _availableColors = [
    '#1E88E5',
    '#43A047',
    '#E53935',
    '#FB8C00',
    '#8E24AA',
    '#00ACC1',
    '#D81B60',
    '#546E7A',
    '#6A1B9A',
    '#00897B',
    '#F4511E',
    '#3949AB',
    '#FF6F00',
    '#C0CA33',
    '#26A69A',
    '#AB47BC',
  ];

  final List<String> _availableRoles = [
    'Admin',
    'SuperAdmin',
    'PropertyManager',
    'User',
    'Guest',
    'Moderator',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChannelData();
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

  void _loadChannelData() {
    context.read<ChannelsBloc>().add(LoadChannelDetailsEvent(widget.channelId));
  }

  void _populateFormData(NotificationChannel channel) {
    if (_isDataLoaded) return;

    setState(() {
      _originalChannel = channel;
      _isDataLoaded = true;

      // Store original values
      _originalName = channel.name;
      _originalDescription = channel.description;
      _originalIcon = channel.icon ?? '📢';
      _originalColor = channel.color ?? '#1E88E5';
      _originalIsPrivate = channel.isPrivate;
      _originalIsActive = channel.isActive;
      _originalRoles = List<String>.from(channel.allowedRoles);

      // Populate form fields
      _nameController.text = channel.name;
      _identifierController.text = channel.identifier;
      _descriptionController.text = channel.description ?? '';
      _selectedType = channel.type;
      _selectedIcon = channel.icon ?? '📢';
      _selectedColor = channel.color ?? '#1E88E5';
      _isPrivate = channel.isPrivate;
      _isActive = channel.isActive;
      _selectedRoles = List<String>.from(channel.allowedRoles);
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
    _nameController.dispose();
    _identifierController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocListener<ChannelsBloc, ChannelsState>(
        listener: (context, state) {
          if (!_isDataLoaded &&
              state.selectedChannel != null &&
              state.selectedChannel!.id == widget.channelId) {
            _populateFormData(state.selectedChannel!);
          } else if (!state.isLoading &&
              state.error == null &&
              _currentStep == 3 &&
              _hasChanges) {
            _showSuccessMessage('تم تحديث القناة بنجاح');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop(true);
              }
            });
          } else if (state.error != null) {
            _showErrorMessage(state.error!);
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Stack(
            children: [
              _buildAnimatedBackground(),
              SafeArea(
                child: !_isDataLoaded
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
            painter: _EditChannelBackgroundPainter(
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
                          Icons.notifications_rounded,
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
              'جاري تحميل بيانات القناة...',
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
                        'تعديل القناة',
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
                  _originalChannel?.name ?? 'قم بتعديل البيانات المطلوبة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
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
          if (_originalChannel != null && !_originalChannel!.isDeletable)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.info.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: AppTheme.info,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'قناة نظام',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.info,
                      fontWeight: FontWeight.w600,
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
      'المظهر والتصميم',
      'الإعدادات',
      'المراجعة',
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
    return BlocBuilder<ChannelsBloc, ChannelsState>(
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
              _buildBasicInfoStep(),
              _buildAppearanceStep(),
              _buildSettingsStep(),
              _buildReviewStep(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoStep() {
    final isSystemChannel = _originalChannel?.type == 'SYSTEM';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_originalChannel != null)
            _buildOriginalValueIndicator(
              'اسم القناة الأصلي',
              _originalName!,
              _nameController.text != _originalName,
            ),
          _buildInputField(
            controller: _nameController,
            label: 'اسم القناة',
            hint: 'أدخل اسم القناة',
            icon: Icons.label_rounded,
            enabled: !isSystemChannel,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال اسم القناة';
              }
              if (value.length < 3) {
                return 'الاسم يجب أن يكون 3 أحرف على الأقل';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildReadOnlyField(
            label: 'معرف القناة',
            value: _identifierController.text,
            icon: Icons.fingerprint_rounded,
          ),
          const SizedBox(height: 20),
          if (_originalChannel != null &&
              _descriptionController.text != (_originalDescription ?? ''))
            _buildOriginalValueIndicator(
              'الوصف الأصلي',
              _originalDescription?.isEmpty ?? true
                  ? 'لا يوجد'
                  : _originalDescription!,
              true,
            ),
          _buildInputField(
            controller: _descriptionController,
            label: 'وصف القناة',
            hint: 'وصف مختصر للقناة (اختياري)',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          _buildReadOnlyField(
            label: 'نوع القناة',
            value: _getTypeLabel(_selectedType),
            icon: _getTypeIcon(_selectedType),
          ),
          if (_originalChannel != null) ...[
            const SizedBox(height: 20),
            _buildChannelMetadata(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppearanceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedIcon != _originalIcon)
            _buildOriginalValueIndicator(
              'الأيقونة الأصلية',
              _originalIcon!,
              true,
            ),
          Text(
            'اختر أيقونة القناة',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildIconGrid(),
          const SizedBox(height: 30),
          if (_selectedColor != _originalColor)
            _buildOriginalValueIndicator(
              'اللون الأصلي',
              '',
              true,
              colorValue: _originalColor,
            ),
          Text(
            'اختر لون القناة',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildColorGrid(),
          const SizedBox(height: 30),
          _buildPreviewCard(),
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
          _buildChannelStatusSettings(),
          const SizedBox(height: 24),
          _buildPrivacySettings(),
          const SizedBox(height: 24),
          if (_selectedType == 'ROLE_BASED') _buildRoleSelector(),
          if (_originalChannel != null) ...[
            const SizedBox(height: 24),
            _buildStatistics(),
          ],
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
          if (_hasChanges) _buildChangesSummary(),
          const SizedBox(height: 20),
          _buildReviewCard(
            title: 'المعلومات الأساسية',
            items: [
              {
                'label': 'الاسم',
                'value': _nameController.text,
                'changed': _nameController.text != _originalName
              },
              {
                'label': 'المعرف',
                'value': _identifierController.text,
                'changed': false
              },
              {
                'label': 'النوع',
                'value': _getTypeLabel(_selectedType),
                'changed': false
              },
              {
                'label': 'الوصف',
                'value': _descriptionController.text.isEmpty
                    ? 'لا يوجد'
                    : _descriptionController.text,
                'changed':
                    _descriptionController.text != (_originalDescription ?? '')
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'المظهر',
            items: [
              {
                'label': 'الأيقونة',
                'value': _selectedIcon,
                'changed': _selectedIcon != _originalIcon
              },
              {
                'label': 'اللون',
                'value': _selectedColor,
                'changed': _selectedColor != _originalColor
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'الإعدادات',
            items: [
              {
                'label': 'الحالة',
                'value': _isActive ? 'نشطة' : 'غير نشطة',
                'changed': _isActive != _originalIsActive
              },
              {
                'label': 'الخصوصية',
                'value': _isPrivate ? 'خاصة' : 'عامة',
                'changed': _isPrivate != _originalIsPrivate
              },
            ],
          ),
          if (_selectedType == 'ROLE_BASED' && _selectedRoles.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRolesReviewCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelMetadata() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات القناة',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetadataItem(
                  'تاريخ الإنشاء',
                  _formatDate(_originalChannel!.createdAt),
                  Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetadataItem(
                  'آخر تحديث',
                  _formatDate(_originalChannel!.updatedAt ??
                      _originalChannel!.createdAt),
                  Icons.update_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.primaryBlue.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelStatusSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isActive
                        ? [AppTheme.success, AppTheme.success.withOpacity(0.7)]
                        : [AppTheme.error, AppTheme.error.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'حالة القناة',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            title: 'القناة نشطة',
            subtitle: 'يمكن إرسال الإشعارات عبر القنوات النشطة فقط',
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            hasChanged: _isActive != _originalIsActive,
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalValueIndicator(
    String label,
    String value,
    bool isChanged, {
    String? colorValue,
  }) {
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
          if (colorValue != null) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(
                    int.parse(colorValue.substring(1), radix: 16) + 0xFF000000),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.warning.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
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

  Widget _buildRolesReviewCard() {
    final hasChanges = !_areListsEqual(_selectedRoles, _originalRoles);

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
                'الأدوار المسموح لها',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedRoles.map((role) {
              final isNew = !_originalRoles.contains(role);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isNew
                      ? LinearGradient(colors: [
                          AppTheme.success.withOpacity(0.7),
                          AppTheme.success.withOpacity(0.5),
                        ])
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNew)
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    if (isNew) const SizedBox(width: 4),
                    Text(
                      _getRoleLabel(role),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (_originalRoles.any((role) => !_selectedRoles.contains(role))) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أدوار محذوفة:',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _originalRoles
                        .where((role) => !_selectedRoles.contains(role))
                        .map((role) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.remove_rounded,
                                    size: 12,
                                    color: AppTheme.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _getRoleLabel(role),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.error,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      AppTheme.primaryPurple.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إحصائيات القناة',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people_rounded,
                  label: 'المشتركين',
                  value: _originalChannel!.subscribersCount.toString(),
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.send_rounded,
                  label: 'الإشعارات',
                  value: _originalChannel!.notificationsSentCount.toString(),
                  color: AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // All helper widgets and methods continue...

  Widget _buildIconGrid() {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _availableIcons.length,
        itemBuilder: (context, index) {
          final icon = _availableIcons[index];
          final isSelected = _selectedIcon == icon;
          final isOriginal = icon == _originalIcon;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIcon = icon;
              });
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected
                    ? null
                    : isOriginal
                        ? AppTheme.warning.withOpacity(0.1)
                        : AppTheme.darkBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : isOriginal
                          ? AppTheme.warning.withOpacity(0.3)
                          : AppTheme.darkBorder.withOpacity(0.3),
                  width: isOriginal ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorGrid() {
    return SizedBox(
      height: 100,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _availableColors.length,
        itemBuilder: (context, index) {
          final color = _availableColors[index];
          final isSelected = _selectedColor == color;
          final isOriginal = color == _originalColor;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Color(
                    int.parse(color.substring(1), radix: 16) + 0xFF000000),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.textWhite
                      : isOriginal
                          ? AppTheme.warning
                          : AppTheme.darkBorder.withOpacity(0.3),
                  width: isSelected || isOriginal ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(
                                  int.parse(color.substring(1), radix: 16) +
                                      0xFF000000)
                              .withOpacity(0.5),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  if (isSelected)
                    const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  if (isOriginal && !isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard() {
    final hasChanges =
        _selectedIcon != _originalIcon || _selectedColor != _originalColor;

    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(16),
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
                'معاينة القناة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(
                          int.parse(_selectedColor.substring(1), radix: 16) +
                              0xFF000000)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(
                            int.parse(_selectedColor.substring(1), radix: 16) +
                                0xFF000000)
                        .withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _selectedIcon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? 'اسم القناة'
                          : _nameController.text,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _descriptionController.text.isEmpty
                          ? 'وصف القناة'
                          : _descriptionController.text,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    final hasChanges = _isPrivate != _originalIsPrivate;

    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إعدادات الخصوصية',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
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
          const SizedBox(height: 20),
          _buildSwitchTile(
            title: 'قناة خاصة',
            subtitle: 'القناة الخاصة تحتاج إذن للانضمام',
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            hasChanged: _isPrivate != _originalIsPrivate,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    final hasChanges = !_areListsEqual(_selectedRoles, _originalRoles);

    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      AppTheme.primaryPurple.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الأدوار المسموح لها',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableRoles.map((role) {
              final isSelected = _selectedRoles.contains(role);
              final wasOriginal = _originalRoles.contains(role);
              final isNew = isSelected && !wasOriginal;
              final isRemoved = !isSelected && wasOriginal;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedRoles.remove(role);
                    } else {
                      _selectedRoles.add(role);
                    }
                  });
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? isNew
                            ? LinearGradient(colors: [
                                AppTheme.success.withOpacity(0.7),
                                AppTheme.success.withOpacity(0.5),
                              ])
                            : AppTheme.primaryGradient
                        : null,
                    color: isSelected
                        ? null
                        : isRemoved
                            ? AppTheme.error.withOpacity(0.1)
                            : AppTheme.darkBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isRemoved
                              ? AppTheme.error.withOpacity(0.3)
                              : AppTheme.darkBorder.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNew)
                        const Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      if (isNew) const SizedBox(width: 4),
                      Text(
                        _getRoleLabel(role),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : isRemoved
                                  ? AppTheme.error
                                  : AppTheme.textMuted,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          decoration:
                              isRemoved ? TextDecoration.lineThrough : null,
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool hasChanged = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (hasChanged)
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
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: hasChanged ? AppTheme.warning : AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor:
              hasChanged ? AppTheme.warning : AppTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
    bool hasChanged = false,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: value
                  ? hasChanged
                      ? LinearGradient(colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.7),
                        ])
                      : AppTheme.primaryGradient
                  : null,
              color: value ? null : AppTheme.darkBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value
                    ? Colors.transparent
                    : hasChanged
                        ? AppTheme.warning.withOpacity(0.3)
                        : AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              if (hasChanged)
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
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: hasChanged ? AppTheme.warning : AppTheme.textWhite,
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
                  child: BlocBuilder<ChannelsBloc, ChannelsState>(
                    builder: (context, state) {
                      if (state.isLoading) {
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    bool enabled = true,
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
                AppTheme.darkCard.withOpacity(enabled ? 0.5 : 0.3),
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
            enabled: enabled,
            style: AppTextStyles.bodyMedium.copyWith(
              color: enabled ? AppTheme.textWhite : AppTheme.textMuted,
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

  // Helper methods
  bool _checkForChanges() {
    if (_originalChannel == null) return false;

    return _nameController.text != _originalName ||
        _descriptionController.text != (_originalDescription ?? '') ||
        _selectedIcon != _originalIcon ||
        _selectedColor != _originalColor ||
        _isPrivate != _originalIsPrivate ||
        _isActive != _originalIsActive ||
        !_areListsEqual(_selectedRoles, _originalRoles);
  }

  bool _hasChangesInStep(int step) {
    if (_originalChannel == null) return false;

    switch (step) {
      case 0: // Basic Info
        return _nameController.text != _originalName ||
            _descriptionController.text != (_originalDescription ?? '');
      case 1: // Appearance
        return _selectedIcon != _originalIcon ||
            _selectedColor != _originalColor;
      case 2: // Settings
        return _isPrivate != _originalIsPrivate ||
            _isActive != _originalIsActive ||
            !_areListsEqual(_selectedRoles, _originalRoles);
      default:
        return false;
    }
  }

  List<Map<String, String>> _getChangedFields() {
    final changes = <Map<String, String>>[];
    if (_originalChannel == null) return changes;

    if (_nameController.text != _originalName) {
      changes.add({
        'field': 'اسم القناة',
        'oldValue': _originalName!,
        'newValue': _nameController.text,
      });
    }

    if (_descriptionController.text != (_originalDescription ?? '')) {
      changes.add({
        'field': 'الوصف',
        'oldValue': _originalDescription?.isEmpty ?? true
            ? 'لا يوجد'
            : _originalDescription!,
        'newValue': _descriptionController.text.isEmpty
            ? 'لا يوجد'
            : _descriptionController.text,
      });
    }

    if (_selectedIcon != _originalIcon) {
      changes.add({
        'field': 'الأيقونة',
        'oldValue': _originalIcon!,
        'newValue': _selectedIcon,
      });
    }

    if (_selectedColor != _originalColor) {
      changes.add({
        'field': 'اللون',
        'oldValue': _originalColor!,
        'newValue': _selectedColor,
      });
    }

    if (_isActive != _originalIsActive) {
      changes.add({
        'field': 'حالة القناة',
        'oldValue': _originalIsActive! ? 'نشطة' : 'غير نشطة',
        'newValue': _isActive ? 'نشطة' : 'غير نشطة',
      });
    }

    if (_isPrivate != _originalIsPrivate) {
      changes.add({
        'field': 'الخصوصية',
        'oldValue': _originalIsPrivate! ? 'خاصة' : 'عامة',
        'newValue': _isPrivate ? 'خاصة' : 'عامة',
      });
    }

    if (!_areListsEqual(_selectedRoles, _originalRoles)) {
      changes.add({
        'field': 'الأدوار المسموح لها',
        'oldValue': _originalRoles.isEmpty
            ? 'لا يوجد'
            : _originalRoles.map((r) => _getRoleLabel(r)).join(', '),
        'newValue': _selectedRoles.isEmpty
            ? 'لا يوجد'
            : _selectedRoles.map((r) => _getRoleLabel(r)).join(', '),
      });
    }

    return changes;
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (var item in list1) {
      if (!list2.contains(item)) return false;
    }
    return true;
  }

  void _resetChanges() {
    if (_originalChannel == null) return;

    showDialog(
      context: context,
      builder: (context) => _ResetConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);

          setState(() {
            // Reset all values to original
            _nameController.text = _originalName!;
            _descriptionController.text = _originalDescription ?? '';
            _selectedIcon = _originalIcon!;
            _selectedColor = _originalColor!;
            _isPrivate = _originalIsPrivate!;
            _isActive = _originalIsActive!;
            _selectedRoles = List<String>.from(_originalRoles);

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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'CUSTOM':
        return 'قناة مخصصة';
      case 'ROLE_BASED':
        return 'حسب الدور';
      case 'EVENT_BASED':
        return 'حسب الحدث';
      case 'BROADCAST':
        return 'بث عام';
      case 'PRIVATE':
        return 'خاصة';
      case 'SYSTEM':
        return 'قناة نظام';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'CUSTOM':
        return Icons.star_rounded;
      case 'ROLE_BASED':
        return Icons.people_rounded;
      case 'EVENT_BASED':
        return Icons.event_rounded;
      case 'BROADCAST':
        return Icons.campaign_rounded;
      case 'PRIVATE':
        return Icons.lock_rounded;
      case 'SYSTEM':
        return Icons.settings_rounded;
      default:
        return Icons.tag_rounded;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'Admin':
        return 'مدير';
      case 'SuperAdmin':
        return 'مدير عام';
      case 'PropertyManager':
        return 'مدير عقار';
      case 'User':
        return 'مستخدم';
      case 'Guest':
        return 'ضيف';
      case 'Moderator':
        return 'مشرف';
      case 'Support':
        return 'دعم فني';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).floor()} أسابيع';
    } else if (difference.inDays < 365) {
      return 'منذ ${(difference.inDays / 30).floor()} شهور';
    } else {
      return 'منذ ${(difference.inDays / 365).floor()} سنوات';
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
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    if (_nameController.text.isEmpty) {
      _showErrorMessage('الرجاء إدخال اسم القناة');
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
      HapticFeedback.mediumImpact();

      context.read<ChannelsBloc>().add(
            UpdateChannelEvent(
              id: widget.channelId,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              isActive: _isActive,
              icon: _selectedIcon,
              color: _selectedColor,
            ),
          );
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
class _EditChannelBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _EditChannelBackgroundPainter({required this.glowIntensity});

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
