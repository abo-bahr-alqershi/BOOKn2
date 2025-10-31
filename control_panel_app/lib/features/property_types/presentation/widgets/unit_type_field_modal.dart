// lib/features/units/presentation/widgets/unit_type_field_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/unit_type_field.dart';

class UnitTypeFieldModal extends StatefulWidget {
  final UnitTypeField? field;
  final String unitTypeId;
  final Function(Map<String, dynamic>) onSave;

  const UnitTypeFieldModal({
    super.key,
    this.field,
    required this.unitTypeId,
    required this.onSave,
  });

  @override
  State<UnitTypeFieldModal> createState() => _UnitTypeFieldModalState();
}

class _UnitTypeFieldModalState extends State<UnitTypeFieldModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fieldNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _sortOrderController;
  late TextEditingController _priorityController;
  late TextEditingController _optionsController;

  String _selectedFieldType = 'text';
  bool _isRequired = false;
  bool _isSearchable = false;
  bool _isPublic = true;
  bool _isForUnits = true;
  bool _showInCards = false;
  bool _isPrimaryFilter = false;
  final bool _isLoading = false;

  // Mobile tab management
  int _currentMobileTab = 0;
  final PageController _pageController = PageController();

  // Breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;

  final List<Map<String, dynamic>> _fieldTypes = [
    {
      'value': 'text',
      'label': 'نص قصير',
      'icon': Icons.text_fields_rounded,
      'color': AppTheme.primaryBlue
    },
    {
      'value': 'textarea',
      'label': 'نص طويل',
      'icon': Icons.subject_rounded,
      'color': AppTheme.primaryPurple
    },
    {
      'value': 'number',
      'label': 'رقم',
      'icon': Icons.numbers_rounded,
      'color': AppTheme.success
    },
    {
      'value': 'currency',
      'label': 'مبلغ مالي',
      'icon': Icons.attach_money_rounded,
      'color': AppTheme.warning
    },
    {
      'value': 'boolean',
      'label': 'نعم/لا',
      'icon': Icons.toggle_on_rounded,
      'color': AppTheme.info
    },
    {
      'value': 'select',
      'label': 'قائمة منسدلة',
      'icon': Icons.arrow_drop_down_circle_rounded,
      'color': AppTheme.neonPurple
    },
    {
      'value': 'multiselect',
      'label': 'تحديد متعدد',
      'icon': Icons.checklist_rounded,
      'color': AppTheme.neonGreen
    },
    {
      'value': 'date',
      'label': 'تاريخ',
      'icon': Icons.calendar_today_rounded,
      'color': AppTheme.error
    },
    {
      'value': 'email',
      'label': 'بريد إلكتروني',
      'icon': Icons.email_rounded,
      'color': AppTheme.primaryBlue
    },
    {
      'value': 'phone',
      'label': 'رقم هاتف',
      'icon': Icons.phone_rounded,
      'color': AppTheme.success
    },
    {
      'value': 'file',
      'label': 'ملف',
      'icon': Icons.attach_file_rounded,
      'color': AppTheme.warning
    },
    {
      'value': 'image',
      'label': 'صورة',
      'icon': Icons.image_rounded,
      'color': AppTheme.info
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fieldNameController = TextEditingController(
      text: widget.field?.fieldName ?? '',
    );
    _displayNameController = TextEditingController(
      text: widget.field?.displayName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.field?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.field?.category ?? '',
    );
    _sortOrderController = TextEditingController(
      text: widget.field?.sortOrder.toString() ?? '0',
    );
    _priorityController = TextEditingController(
      text: widget.field?.priority.toString() ?? '0',
    );
    _optionsController = TextEditingController(
      text: widget.field?.fieldOptions['options']?.join(', ') ?? '',
    );

    if (widget.field != null) {
      _selectedFieldType = widget.field!.fieldTypeId;
      _isRequired = widget.field!.isRequired;
      _isSearchable = widget.field!.isSearchable;
      _isPublic = widget.field!.isPublic;
      _isForUnits = widget.field!.isForUnits;
      _showInCards = widget.field!.showInCards;
      _isPrimaryFilter = widget.field!.isPrimaryFilter;
    }

    _animationController.forward();
    _tabAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabAnimationController.dispose();
    _pageController.dispose();
    _fieldNameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _sortOrderController.dispose();
    _priorityController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _mobileBreakpoint) {
          return _buildMobileLayout();
        } else if (constraints.maxWidth < _tabletBreakpoint) {
          return _buildTabletLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  // ================ MOBILE LAYOUT ================
  Widget _buildMobileLayout() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Scaffold(
              backgroundColor: AppTheme.darkBackground,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildMobileHeader(),
                    _buildMobileTabs(),
                    Expanded(
                      child: _buildMobileContent(),
                    ),
                    _buildMobileActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neonPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.neonPurple, AppTheme.neonGreen],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPurple.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.dynamic_form_rounded,
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
                  widget.field == null ? 'حقل جديد' : 'تعديل الحقل',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 18,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  'قم بإدخال البيانات المطلوبة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabs() {
    final tabs = [
      {'label': 'الأساسي', 'icon': Icons.info_rounded},
      {'label': 'النوع', 'icon': Icons.category_rounded},
      {'label': 'الخصائص', 'icon': Icons.settings_rounded},
      {'label': 'متقدم', 'icon': Icons.tune_rounded},
    ];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = _currentMobileTab == index;

          return GestureDetector(
            onTap: () {
              setState(() => _currentMobileTab = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          AppTheme.neonPurple.withOpacity(0.3),
                          AppTheme.neonGreen.withOpacity(0.2),
                        ],
                      )
                    : null,
                color: !isActive ? AppTheme.darkSurface.withOpacity(0.3) : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppTheme.neonPurple.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 16,
                    color: isActive ? AppTheme.neonPurple : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? AppTheme.textWhite : AppTheme.textMuted,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildMobileContent() {
    return Form(
      key: _formKey,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentMobileTab = index);
        },
        children: [
          _buildMobileBasicInfo(),
          _buildMobileFieldType(),
          _buildMobileFeatures(),
          _buildMobileAdvanced(),
        ],
      ),
    );
  }

  Widget _buildMobileBasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileSection(
            title: 'معلومات الحقل',
            icon: Icons.info_outline_rounded,
            children: [
              _buildMobileTextField(
                controller: _fieldNameController,
                label: 'اسم الحقل (بالإنجليزية)',
                hint: 'field_name',
                icon: Icons.code_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم الحقل';
                  }
                  if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value)) {
                    return 'يجب أن يبدأ بحرف ويحتوي على حروف وأرقام و _ فقط';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildMobileTextField(
                controller: _displayNameController,
                label: 'الاسم المعروض',
                hint: 'الاسم الذي سيظهر للمستخدم',
                icon: Icons.label_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم المعروض';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildMobileTextField(
                controller: _descriptionController,
                label: 'الوصف',
                hint: 'وصف مختصر للحقل',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFieldType() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileSection(
            title: 'نوع الحقل',
            icon: Icons.category_rounded,
            children: [
              _buildMobileFieldTypeGrid(),
              if (_selectedFieldType == 'select' ||
                  _selectedFieldType == 'multiselect') ...[
                const SizedBox(height: 16),
                _buildMobileTextField(
                  controller: _optionsController,
                  label: 'الخيارات',
                  hint: 'خيار 1, خيار 2, خيار 3',
                  icon: Icons.list_rounded,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال الخيارات مفصولة بفاصلة';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFieldTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _fieldTypes.length,
      itemBuilder: (context, index) {
        final type = _fieldTypes[index];
        final isSelected = _selectedFieldType == type['value'];

        return GestureDetector(
          onTap: () {
            setState(() => _selectedFieldType = type['value'] as String);
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        (type['color'] as Color).withOpacity(0.3),
                        (type['color'] as Color).withOpacity(0.1),
                      ],
                    )
                  : null,
              color: !isSelected ? AppTheme.darkSurface.withOpacity(0.5) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (type['color'] as Color).withOpacity(0.5)
                    : AppTheme.darkBorder.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type['icon'] as IconData,
                  size: 24,
                  color: isSelected
                      ? (type['color'] as Color)
                      : AppTheme.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  type['label'] as String,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileFeatures() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileSection(
            title: 'خصائص الحقل',
            icon: Icons.settings_rounded,
            children: [
              _buildMobileFeatureToggle(
                title: 'حقل مطلوب',
                subtitle: 'يجب على المستخدم ملء هذا الحقل',
                value: _isRequired,
                onChanged: (v) => setState(() => _isRequired = v),
                icon: Icons.star_rounded,
                activeColor: AppTheme.error,
              ),
              const SizedBox(height: 12),
              _buildMobileFeatureToggle(
                title: 'قابل للبحث',
                subtitle: 'يمكن البحث بواسطة هذا الحقل',
                value: _isSearchable,
                onChanged: (v) => setState(() => _isSearchable = v),
                icon: Icons.search_rounded,
                activeColor: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 12),
              _buildMobileFeatureToggle(
                title: 'حقل عام',
                subtitle: 'يظهر لجميع المستخدمين',
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
                icon: Icons.public_rounded,
                activeColor: AppTheme.success,
              ),
              const SizedBox(height: 12),
              _buildMobileFeatureToggle(
                title: 'للوحدات',
                subtitle: 'يستخدم هذا الحقل مع الوحدات',
                value: _isForUnits,
                onChanged: (v) => setState(() => _isForUnits = v),
                icon: Icons.home_work_rounded,
                activeColor: AppTheme.warning,
              ),
              const SizedBox(height: 12),
              _buildMobileFeatureToggle(
                title: 'يظهر في الكروت',
                subtitle: 'عرض الحقل في بطاقات العرض',
                value: _showInCards,
                onChanged: (v) => setState(() => _showInCards = v),
                icon: Icons.view_carousel_rounded,
                activeColor: AppTheme.info,
              ),
              const SizedBox(height: 12),
              _buildMobileFeatureToggle(
                title: 'فلتر أساسي',
                subtitle: 'استخدام الحقل كفلتر رئيسي',
                value: _isPrimaryFilter,
                onChanged: (v) => setState(() => _isPrimaryFilter = v),
                icon: Icons.filter_list_rounded,
                activeColor: AppTheme.neonPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAdvanced() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileSection(
            title: 'إعدادات متقدمة',
            icon: Icons.tune_rounded,
            children: [
              _buildMobileTextField(
                controller: _categoryController,
                label: 'الفئة',
                hint: 'فئة الحقل',
                icon: Icons.category_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMobileTextField(
                      controller: _sortOrderController,
                      label: 'الترتيب',
                      hint: '0',
                      icon: Icons.sort_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMobileTextField(
                      controller: _priorityController,
                      label: 'الأولوية',
                      hint: '0',
                      icon: Icons.priority_high_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.5),
            AppTheme.darkSurface.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonPurple.withOpacity(0.3),
                      AppTheme.neonGreen.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppTheme.neonPurple,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.neonPurple.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFeatureToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(
                  colors: [
                    activeColor.withOpacity(0.2),
                    activeColor.withOpacity(0.1),
                  ],
                )
              : null,
          color: !value ? AppTheme.darkCard.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? activeColor.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: value ? activeColor : AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: activeColor,
              activeTrackColor: activeColor.withOpacity(0.3),
              inactiveThumbColor: AppTheme.textMuted,
              inactiveTrackColor: AppTheme.darkBorder.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                height: 48,
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _handleSave,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.neonPurple, AppTheme.neonGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPurple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.field == null ? 'إضافة' : 'تحديث',
                          style: AppTextStyles.bodyMedium.copyWith(
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
    );
  }

  // ================ TABLET LAYOUT ================
  Widget _buildTabletLayout() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints:
                    const BoxConstraints(maxWidth: 800, maxHeight: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkCard.withOpacity(0.95),
                      AppTheme.darkCard.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.neonPurple.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPurple.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Column(
                      children: [
                        _buildTabletHeader(),
                        Expanded(
                          child: Row(
                            children: [
                              _buildTabletSidebar(),
                              Expanded(
                                child: _buildTabletContent(),
                              ),
                            ],
                          ),
                        ),
                        _buildTabletActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonPurple.withOpacity(0.1),
            AppTheme.neonGreen.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.neonPurple, AppTheme.neonGreen],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPurple.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.dynamic_form_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.field == null
                      ? 'إضافة حقل ديناميكي'
                      : 'تعديل الحقل الديناميكي',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  'قم بإدخال معلومات الحقل',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletSidebar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        border: Border(
          right: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildTabletSidebarItem(
            'المعلومات الأساسية',
            Icons.info_rounded,
            0,
          ),
          _buildTabletSidebarItem(
            'نوع الحقل',
            Icons.category_rounded,
            1,
          ),
          _buildTabletSidebarItem(
            'الخصائص',
            Icons.settings_rounded,
            2,
          ),
          _buildTabletSidebarItem(
            'إعدادات متقدمة',
            Icons.tune_rounded,
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletSidebarItem(String label, IconData icon, int index) {
    final isActive = _currentMobileTab == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentMobileTab = index);
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppTheme.neonPurple.withOpacity(0.2),
                    AppTheme.neonGreen.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.neonPurple.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.neonPurple : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isActive ? AppTheme.textWhite : AppTheme.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _getTabletContent(),
      ),
    );
  }

  Widget _getTabletContent() {
    switch (_currentMobileTab) {
      case 0:
        return _buildTabletBasicInfo();
      case 1:
        return _buildTabletFieldType();
      case 2:
        return _buildTabletFeatures();
      case 3:
        return _buildTabletAdvanced();
      default:
        return _buildTabletBasicInfo();
    }
  }

  Widget _buildTabletBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _fieldNameController,
                label: 'اسم الحقل (بالإنجليزية)',
                hint: 'field_name',
                icon: Icons.code_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم الحقل';
                  }
                  if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value)) {
                    return 'يجب أن يبدأ بحرف ويحتوي على حروف وأرقام و _ فقط';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _displayNameController,
                label: 'الاسم المعروض',
                hint: 'الاسم الذي سيظهر للمستخدم',
                icon: Icons.label_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم المعروض';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'الوصف',
          hint: 'وصف مختصر للحقل',
          icon: Icons.description_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTabletFieldType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabletFieldTypeGrid(),
        if (_selectedFieldType == 'select' ||
            _selectedFieldType == 'multiselect') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _optionsController,
            label: 'الخيارات',
            hint: 'خيار 1, خيار 2, خيار 3',
            icon: Icons.list_rounded,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال الخيارات مفصولة بفاصلة';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTabletFieldTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _fieldTypes.length,
      itemBuilder: (context, index) {
        final type = _fieldTypes[index];
        final isSelected = _selectedFieldType == type['value'];

        return GestureDetector(
          onTap: () {
            setState(() => _selectedFieldType = type['value'] as String);
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        (type['color'] as Color).withOpacity(0.3),
                        (type['color'] as Color).withOpacity(0.1),
                      ],
                    )
                  : null,
              color: !isSelected ? AppTheme.darkSurface.withOpacity(0.5) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (type['color'] as Color).withOpacity(0.5)
                    : AppTheme.darkBorder.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type['icon'] as IconData,
                  size: 24,
                  color: isSelected
                      ? (type['color'] as Color)
                      : AppTheme.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  type['label'] as String,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletFeatures() {
    return _buildFeatureToggles();
  }

  Widget _buildTabletAdvanced() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _categoryController,
          label: 'الفئة',
          hint: 'فئة الحقل',
          icon: Icons.category_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _sortOrderController,
                label: 'الترتيب',
                hint: '0',
                icon: Icons.sort_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _priorityController,
                label: 'الأولوية',
                hint: '0',
                icon: Icons.priority_high_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.3),
            AppTheme.darkSurface.withOpacity(0.1),
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildCancelButton(),
          const SizedBox(width: 12),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ================ DESKTOP LAYOUT ================
  Widget _buildDesktopLayout() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(10),
              child: _buildDesktopContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        border: Border.all(
          color: AppTheme.neonPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonPurple.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildForm(),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonPurple.withOpacity(0.1),
            AppTheme.neonGreen.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.neonPurple, AppTheme.neonGreen],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPurple.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.dynamic_form_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.field == null
                      ? 'إضافة حقل ديناميكي'
                      : 'تعديل الحقل الديناميكي',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'قم بإدخال معلومات الحقل',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Field Type Selector
            _buildFieldTypeSelector(),

            const SizedBox(height: AppDimensions.spaceMedium),

            // Basic Info
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _fieldNameController,
                    label: 'اسم الحقل (بالإنجليزية)',
                    hint: 'field_name',
                    icon: Icons.code_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم الحقل';
                      }
                      if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$')
                          .hasMatch(value)) {
                        return 'يجب أن يبدأ بحرف ويحتوي على حروف وأرقام و _ فقط';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMedium),
                Expanded(
                  child: _buildTextField(
                    controller: _displayNameController,
                    label: 'الاسم المعروض',
                    hint: 'الاسم الذي سيظهر للمستخدم',
                    icon: Icons.label_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال الاسم المعروض';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceMedium),

            _buildTextField(
              controller: _descriptionController,
              label: 'الوصف',
              hint: 'وصف مختصر للحقل',
              icon: Icons.description_rounded,
              maxLines: 2,
            ),

            const SizedBox(height: AppDimensions.spaceMedium),

            // Options for select/multiselect
            if (_selectedFieldType == 'select' ||
                _selectedFieldType == 'multiselect')
              Column(
                children: [
                  _buildTextField(
                    controller: _optionsController,
                    label: 'الخيارات',
                    hint: 'خيار 1, خيار 2, خيار 3',
                    icon: Icons.list_rounded,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال الخيارات مفصولة بفاصلة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),
                ],
              ),

            // Additional Fields
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _categoryController,
                    label: 'الفئة',
                    hint: 'فئة الحقل',
                    icon: Icons.category_rounded,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMedium),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _sortOrderController,
                    label: 'الترتيب',
                    hint: '0',
                    icon: Icons.sort_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMedium),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _priorityController,
                    label: 'الأولوية',
                    hint: '0',
                    icon: Icons.priority_high_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceLarge),

            // Feature Toggles
            _buildFeatureToggles(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الحقل',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface.withOpacity(0.5),
                AppTheme.darkSurface.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedFieldType,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            dropdownColor: AppTheme.darkCard,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppTheme.textMuted,
            ),
            items: _fieldTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'] as String,
                child: Row(
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 20,
                      color: type['color'] as Color,
                    ),
                    const SizedBox(width: 8),
                    Text(type['label'] as String),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFieldType = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface.withOpacity(0.5),
                AppTheme.darkSurface.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: maxLines == 1
                  ? Icon(
                      icon,
                      color: AppTheme.neonPurple.withOpacity(0.7),
                      size: 18,
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 10, left: 10),
                      child: Icon(
                        icon,
                        color: AppTheme.neonPurple.withOpacity(0.7),
                        size: 18,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: maxLines == 1 ? 10 : 10,
                vertical: maxLines == 1 ? 12 : 10,
              ),
              isDense: true,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggles() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.3),
            AppTheme.darkSurface.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خصائص الحقل',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildCompactToggle(
                label: 'مطلوب',
                value: _isRequired,
                onChanged: (v) => setState(() => _isRequired = v),
                color: AppTheme.error,
              ),
              _buildCompactToggle(
                label: 'قابل للبحث',
                value: _isSearchable,
                onChanged: (v) => setState(() => _isSearchable = v),
                color: AppTheme.primaryBlue,
              ),
              _buildCompactToggle(
                label: 'عام',
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
                color: AppTheme.success,
              ),
              _buildCompactToggle(
                label: 'للوحدات',
                value: _isForUnits,
                onChanged: (v) => setState(() => _isForUnits = v),
                color: AppTheme.warning,
              ),
              _buildCompactToggle(
                label: 'يظهر في الكروت',
                value: _showInCards,
                onChanged: (v) => setState(() => _showInCards = v),
                color: AppTheme.info,
              ),
              _buildCompactToggle(
                label: 'فلتر أساسي',
                value: _isPrimaryFilter,
                onChanged: (v) => setState(() => _isPrimaryFilter = v),
                color: AppTheme.neonPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? color.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value ? color : AppTheme.darkBorder,
                  width: 1,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: value ? color : AppTheme.textMuted,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.3),
            AppTheme.darkSurface.withOpacity(0.1),
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
          Expanded(
            child: _buildCancelButton(),
          ),
          const SizedBox(width: AppDimensions.spaceMedium),
          Expanded(
            child: _buildSaveButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.5),
              AppTheme.darkCard.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSave,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.neonPurple, AppTheme.neonGreen],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.field == null ? 'إضافة' : 'تحديث',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      final fieldOptions = <String, dynamic>{};
      if (_selectedFieldType == 'select' ||
          _selectedFieldType == 'multiselect') {
        fieldOptions['options'] = _optionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      final validationRules = <String, dynamic>{};

      widget.onSave({
        'fieldTypeId': _selectedFieldType,
        'fieldName': _fieldNameController.text,
        'displayName': _displayNameController.text,
        'description': _descriptionController.text,
        'fieldOptions': fieldOptions,
        'validationRules': validationRules,
        'isRequired': _isRequired,
        'isSearchable': _isSearchable,
        'isPublic': _isPublic,
        'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
        'category': _categoryController.text,
        'isForUnits': _isForUnits,
        'showInCards': _showInCards,
        'isPrimaryFilter': _isPrimaryFilter,
        'priority': int.tryParse(_priorityController.text) ?? 0,
      });

      Navigator.of(context).pop();
    }
  }
}
// import 'package:flutter/material.dart';
// import 'dart:ui';
// import 'package:bookn_cp_app/core/theme/app_theme.dart';
// import 'package:bookn_cp_app/core/theme/app_text_styles.dart';

// class UnitTypeFieldModal extends StatefulWidget {
//   final dynamic field;
//   final String unitTypeId;
//   final Function(Map<String, dynamic>) onSave;

//   const UnitTypeFieldModal({
//     super.key,
//     this.field,
//     required this.unitTypeId,
//     required this.onSave,
//   });

//   @override
//   State<UnitTypeFieldModal> createState() => _UnitTypeFieldModalState();
// }

// class _UnitTypeFieldModalState extends State<UnitTypeFieldModal> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _fieldNameController;
//   late TextEditingController _displayNameController;
//   late TextEditingController _descriptionController;
//   late TextEditingController _categoryController;
//   late String _fieldTypeId;
//   late bool _isRequired;
//   late bool _isSearchable;
//   late bool _isPublic;
//   late bool _isForUnits;
//   late bool _showInCards;
//   late bool _isPrimaryFilter;
//   late int _sortOrder;
//   late int _priority;
//   List<String> _options = [];

//   final List<Map<String, dynamic>> _fieldTypes = [
//     {'value': 'text', 'label': 'نص قصير', 'icon': Icons.text_fields_rounded},
//     {'value': 'textarea', 'label': 'نص طويل', 'icon': Icons.notes_rounded},
//     {'value': 'number', 'label': 'رقم', 'icon': Icons.numbers_rounded},
//     {'value': 'currency', 'label': 'مبلغ مالي', 'icon': Icons.attach_money_rounded},
//     {'value': 'boolean', 'label': 'منطقي (نعم/لا)', 'icon': Icons.toggle_on_rounded},
//     {'value': 'select', 'label': 'قائمة منسدلة', 'icon': Icons.arrow_drop_down_circle_rounded},
//     {'value': 'multiselect', 'label': 'تحديد متعدد', 'icon': Icons.checklist_rounded},
//     {'value': 'date', 'label': 'تاريخ', 'icon': Icons.calendar_today_rounded},
//     {'value': 'email', 'label': 'بريد إلكتروني', 'icon': Icons.email_rounded},
//     {'value': 'phone', 'label': 'رقم هاتف', 'icon': Icons.phone_rounded},
//     {'value': 'file', 'label': 'ملف', 'icon': Icons.attach_file_rounded},
//     {'value': 'image', 'label': 'صورة', 'icon': Icons.image_rounded},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fieldNameController = TextEditingController(text: widget.field?.fieldName ?? '');
//     _displayNameController = TextEditingController(text: widget.field?.displayName ?? '');
//     _descriptionController = TextEditingController(text: widget.field?.description ?? '');
//     _categoryController = TextEditingController(text: widget.field?.category ?? '');
//     _fieldTypeId = widget.field?.fieldTypeId ?? 'text';
//     _isRequired = widget.field?.isRequired ?? false;
//     _isSearchable = widget.field?.isSearchable ?? false;
//     _isPublic = widget.field?.isPublic ?? true;
//     _isForUnits = widget.field?.isForUnits ?? true;
//     _showInCards = widget.field?.showInCards ?? false;
//     _isPrimaryFilter = widget.field?.isPrimaryFilter ?? false;
//     _sortOrder = widget.field?.sortOrder ?? 0;
//     _priority = widget.field?.priority ?? 0;
    
//     if (widget.field?.fieldOptions != null && widget.field.fieldOptions['options'] != null) {
//       _options = List<String>.from(widget.field.fieldOptions['options']);
//     }
//   }

//   @override
//   void dispose() {
//     _fieldNameController.dispose();
//     _displayNameController.dispose();
//     _descriptionController.dispose();
//     _categoryController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final bool isSmall = screenSize.width < 600;
//     final EdgeInsets inset = isSmall
//         ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
//         : const EdgeInsets.all(20);
//     final double dialogWidth = isSmall ? (screenSize.width - inset.horizontal) : 760;
//     final double maxHeight = isSmall ? (screenSize.height * 0.95) : (screenSize.height * 0.9);

//     return Dialog(
      // insetPadding: const EdgeInsets.all(10),
//       backgroundColor: Colors.transparent,
//       insetPadding: inset,
//       child: Container(
//         width: dialogWidth,
//         constraints: BoxConstraints(
//           maxHeight: maxHeight,
//         ),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               AppTheme.darkCard.withOpacity(0.95),
//               AppTheme.darkCard.withOpacity(0.85),
//             ],
//           ),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: AppTheme.primaryPurple.withOpacity(0.3),
//             width: 1,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildHeader(),
//                   Flexible(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(24),
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(child: _buildFieldTypeSelector()),
//                               const SizedBox(width: 16),
//                               Expanded(child: _buildFieldNameField()),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           _buildDisplayNameField(),
//                           const SizedBox(height: 16),
//                           _buildDescriptionField(),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(child: _buildCategoryField()),
//                               const SizedBox(width: 16),
//                               Expanded(
//                                 child: Row(
//                                   children: [
//                                     Expanded(child: _buildSortOrderField()),
//                                     const SizedBox(width: 8),
//                                     Expanded(child: _buildPriorityField()),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           if (_fieldTypeId == 'select' || _fieldTypeId == 'multiselect') ...[
//                             const SizedBox(height: 16),
//                             _buildOptionsField(),
//                           ],
//                           const SizedBox(height: 20),
//                           _buildSettingsSection(),
//                         ],
//                       ),
//                     ),
//                   ),
//                   _buildActions(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.primaryPurple.withOpacity(0.1),
//             AppTheme.primaryBlue.withOpacity(0.05),
//           ],
//         ),
//         border: Border(
//           bottom: BorderSide(
//             color: AppTheme.darkBorder.withOpacity(0.3),
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.7)],
//               ),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(
//               Icons.text_fields_rounded,
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.field == null ? 'إضافة حقل جديد' : 'تعديل الحقل',
//                   style: AppTextStyles.heading3.copyWith(
//                     color: AppTheme.textWhite,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   'قم بملء البيانات المطلوبة للحقل الديناميكي',
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppTheme.textMuted,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFieldTypeSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'نوع الحقل',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(
//             color: AppTheme.darkSurface.withOpacity(0.5),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: AppTheme.darkBorder.withOpacity(0.3),
//             ),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: _fieldTypeId,
//               isExpanded: true,
//               dropdownColor: AppTheme.darkCard,
//               style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
//               items: _fieldTypes.map((type) {
//                 return DropdownMenuItem<String>(
//                   value: type['value'],
//                   child: Row(
//                     children: [
//                       Icon(
//                         type['icon'],
//                         size: 18,
//                         color: AppTheme.primaryPurple,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(type['label']),
//                     ],
//                   ),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _fieldTypeId = value!;
//                 });
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFieldNameField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'اسم الحقل (بالإنجليزية)',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: _fieldNameController,
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontFamily: 'monospace',
//           ),
//           decoration: _getInputDecoration('field_name'),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'الرجاء إدخال اسم الحقل';
//             }
//             if (!RegExp(r'^[a-z_]+$').hasMatch(value)) {
//               return 'يجب أن يحتوي على أحرف صغيرة و _ فقط';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildDisplayNameField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'الاسم المعروض',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: _displayNameController,
//           style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
//           decoration: _getInputDecoration('أدخل الاسم المعروض للحقل'),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'الرجاء إدخال الاسم المعروض';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildDescriptionField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'الوصف',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: _descriptionController,
//           maxLines: 2,
//           style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
//           decoration: _getInputDecoration('أدخل وصف الحقل (اختياري)'),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategoryField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'الفئة',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: _categoryController,
//           style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
//           decoration: _getInputDecoration('أدخل فئة الحقل'),
//         ),
//       ],
//     );
//   }

//   Widget _buildSortOrderField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'الترتيب',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: AppTheme.darkSurface.withOpacity(0.5),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: AppTheme.darkBorder.withOpacity(0.3),
//             ),
//           ),
//           child: Row(
//             children: [
//               IconButton(
//                 onPressed: () {
//                   if (_sortOrder > 0) {
//                     setState(() => _sortOrder--);
//                   }
//                 },
//                 icon: Icon(Icons.remove, color: AppTheme.textMuted),              ),
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     '$_sortOrder',
//                     style: AppTextStyles.bodyMedium.copyWith(
//                       color: AppTheme.textWhite,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               IconButton(
//                 onPressed: () {
//                   setState(() => _sortOrder++);
//                 },
//                 icon: Icon(Icons.add, color: AppTheme.primaryPurple),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPriorityField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'الأولوية',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: AppTheme.darkSurface.withOpacity(0.5),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: AppTheme.darkBorder.withOpacity(0.3),
//             ),
//           ),
//           child: Row(
//             children: [
//               IconButton(
//                 onPressed: () {
//                   if (_priority > 0) {
//                     setState(() => _priority--);
//                   }
//                 },
//                 icon: Icon(Icons.remove, color: AppTheme.textMuted),
//               ),
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     '$_priority',
//                     style: AppTextStyles.bodyMedium.copyWith(
//                       color: AppTheme.textWhite,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               IconButton(
//                 onPressed: () {
//                   setState(() => _priority++);
//                 },
//                 icon: Icon(Icons.add, color: AppTheme.primaryPurple),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOptionsField() {
//     final optionController = TextEditingController();
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'خيارات القائمة',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppTheme.darkSurface.withOpacity(0.5),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: AppTheme.darkBorder.withOpacity(0.3),
//             ),
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: optionController,
//                       style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
//                       decoration: InputDecoration(
//                         hintText: 'أضف خيار',
//                         hintStyle: AppTextStyles.bodyMedium.copyWith(
//                           color: AppTheme.textMuted.withOpacity(0.5),
//                         ),
//                         border: InputBorder.none,
//                       ),
//                       onSubmitted: (value) {
//                         if (value.isNotEmpty) {
//                           setState(() {
//                             _options.add(value);
//                             optionController.clear();
//                           });
//                         }
//                       },
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () {
//                       if (optionController.text.isNotEmpty) {
//                         setState(() {
//                           _options.add(optionController.text);
//                           optionController.clear();
//                         });
//                       }
//                     },
//                     icon: Icon(
//                       Icons.add_circle_rounded,
//                       color: AppTheme.primaryPurple,
//                     ),
//                   ),
//                 ],
//               ),
//               if (_options.isNotEmpty) ...[
//                 const SizedBox(height: 8),
//                 Container(
//                   constraints: const BoxConstraints(maxHeight: 150),
//                   child: SingleChildScrollView(
//                     child: Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: _options.map((option) {
//                         return Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 AppTheme.primaryPurple.withOpacity(0.2),
//                                 AppTheme.primaryBlue.withOpacity(0.1),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                               color: AppTheme.primaryPurple.withOpacity(0.3),
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 option,
//                                 style: AppTextStyles.bodySmall.copyWith(
//                                   color: AppTheme.textWhite,
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               GestureDetector(
//                                 onTap: () {
//                                   setState(() {
//                                     _options.remove(option);
//                                   });
//                                 },
//                                 child: Icon(
//                                   Icons.close_rounded,
//                                   size: 14,
//                                   color: AppTheme.textMuted,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSettingsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'إعدادات الحقل',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: AppTheme.darkSurface.withOpacity(0.3),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: AppTheme.darkBorder.withOpacity(0.2),
//             ),
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildSettingToggle(
//                       icon: Icons.star_rounded,
//                       title: 'مطلوب',
//                       value: _isRequired,
//                       onChanged: (value) => setState(() => _isRequired = value),
//                       color: AppTheme.error,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildSettingToggle(
//                       icon: Icons.search_rounded,
//                       title: 'قابل للبحث',
//                       value: _isSearchable,
//                       onChanged: (value) => setState(() => _isSearchable = value),
//                       color: AppTheme.info,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildSettingToggle(
//                       icon: Icons.public_rounded,
//                       title: 'عام',
//                       value: _isPublic,
//                       onChanged: (value) => setState(() => _isPublic = value),
//                       color: AppTheme.success,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildSettingToggle(
//                       icon: Icons.home_work_rounded,
//                       title: 'للوحدات',
//                       value: _isForUnits,
//                       onChanged: (value) => setState(() => _isForUnits = value),
//                       color: AppTheme.primaryBlue,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildSettingToggle(
//                       icon: Icons.view_agenda_rounded,
//                       title: 'عرض في البطاقات',
//                       value: _showInCards,
//                       onChanged: (value) => setState(() => _showInCards = value),
//                       color: AppTheme.primaryPurple,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildSettingToggle(
//                       icon: Icons.filter_alt_rounded,
//                       title: 'فلتر أساسي',
//                       value: _isPrimaryFilter,
//                       onChanged: (value) => setState(() => _isPrimaryFilter = value),
//                       color: AppTheme.primaryCyan,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSettingToggle({
//     required IconData icon,
//     required String title,
//     required bool value,
//     required Function(bool) onChanged,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         gradient: value
//             ? LinearGradient(
//                 colors: [
//                   color.withOpacity(0.1),
//                   color.withOpacity(0.05),
//                 ],
//               )
//             : null,
//         color: value ? null : AppTheme.darkSurface.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: value ? color.withOpacity(0.3) : AppTheme.darkBorder.withOpacity(0.1),
//           width: 0.5,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: value ? color : AppTheme.textMuted,
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               title,
//               style: AppTextStyles.caption.copyWith(
//                 color: value ? AppTheme.textWhite : AppTheme.textMuted,
//                 fontWeight: value ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ),
//           Transform.scale(
//             scale: 0.8,
//             child: Switch(
//               value: value,
//               onChanged: onChanged,
//               activeColor: color,
//               activeTrackColor: color.withOpacity(0.3),
//               inactiveThumbColor: AppTheme.textMuted,
//               inactiveTrackColor: AppTheme.darkSurface,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActions() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.darkSurface.withOpacity(0.7),
//             AppTheme.darkSurface.withOpacity(0.5),
//           ],
//         ),
//         border: Border(
//           top: BorderSide(
//             color: AppTheme.darkBorder.withOpacity(0.3),
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   color: AppTheme.darkSurface.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: AppTheme.darkBorder.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     'إلغاء',
//                     style: AppTextStyles.buttonMedium.copyWith(
//                       color: AppTheme.textMuted,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: GestureDetector(
//               onTap: _save,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.7)],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppTheme.primaryPurple.withOpacity(0.3),
//                       blurRadius: 12,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Text(
//                     widget.field == null ? 'إضافة' : 'تحديث',
//                     style: AppTextStyles.buttonMedium.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _getInputDecoration(String hintText) {
//     return InputDecoration(
//       hintText: hintText,
//       hintStyle: AppTextStyles.bodyMedium.copyWith(
//         color: AppTheme.textMuted.withOpacity(0.5),
//       ),
//       filled: true,
//       fillColor: AppTheme.darkSurface.withOpacity(0.5),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(
//           color: AppTheme.darkBorder.withOpacity(0.3),
//         ),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(
//           color: AppTheme.darkBorder.withOpacity(0.3),
//         ),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(
//           color: AppTheme.primaryPurple.withOpacity(0.5),
//         ),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(
//           color: AppTheme.error.withOpacity(0.5),
//         ),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(
//           color: AppTheme.error.withOpacity(0.5),
//         ),
//       ),
//     );
//   }

//   void _save() {
//     if (_formKey.currentState!.validate()) {
//       final Map<String, dynamic> fieldData = {
//         'fieldTypeId': _fieldTypeId,
//         'fieldName': _fieldNameController.text,
//         'displayName': _displayNameController.text,
//         'description': _descriptionController.text,
//         'fieldOptions': (_fieldTypeId == 'select' || _fieldTypeId == 'multiselect') 
//             ? {'options': _options} 
//             : {},
//         'validationRules': {},
//         'isRequired': _isRequired,
//         'isSearchable': _isSearchable,
//         'isPublic': _isPublic,
//         'sortOrder': _sortOrder,
//         'category': _categoryController.text,
//         'isForUnits': _isForUnits,
//         'showInCards': _showInCards,
//         'isPrimaryFilter': _isPrimaryFilter,
//         'priority': _priority,
//       };
      
//       widget.onSave(fieldData);
//       Navigator.pop(context);
//     }
//   }
// }