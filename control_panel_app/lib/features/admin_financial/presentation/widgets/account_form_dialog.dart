// lib/features/admin_financial/presentation/widgets/futuristic_account_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/chart_of_account.dart';

class AccountFormDialog extends StatefulWidget {
  final ChartOfAccount? account;
  final ChartOfAccount? parentAccount;
  final Function(ChartOfAccount) onSave;

  const AccountFormDialog({
    super.key,
    this.account,
    this.parentAccount,
    required this.onSave,
  });

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accountNumberController;
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionController;

  AccountType _selectedAccountType = AccountType.assets;
  AccountCategory _selectedCategory = AccountCategory.main;
  AccountNature _selectedNature = AccountNature.debit;
  bool _isActive = true;
  bool _canPost = true;

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
      curve: const Interval(0.0, 0.5),
    ));

    _animationController.forward();

    // Initialize controllers
    _accountNumberController = TextEditingController(
      text: widget.account?.accountNumber ?? '',
    );
    _nameArController = TextEditingController(
      text: widget.account?.nameAr ?? '',
    );
    _nameEnController = TextEditingController(
      text: widget.account?.nameEn ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.account?.description ?? '',
    );

    // Set initial values if editing
    if (widget.account != null) {
      _selectedAccountType = widget.account!.accountType;
      _selectedCategory = widget.account!.category;
      _selectedNature = widget.account!.normalBalance;
      _isActive = widget.account!.isActive;
      _canPost = widget.account!.canPost;
    } else if (widget.parentAccount != null) {
      // If creating sub-account, inherit parent's type
      _selectedAccountType = widget.parentAccount!.accountType;
      _selectedCategory = AccountCategory.sub;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _accountNumberController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final account = ChartOfAccount(
        id: widget.account?.id ?? DateTime.now().toString(),
        accountNumber: _accountNumberController.text,
        nameAr: _nameArController.text,
        nameEn: _nameEnController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        accountType: _selectedAccountType,
        category: _selectedCategory,
        normalBalance: _selectedNature,
        level: widget.parentAccount != null
            ? (widget.parentAccount!.level + 1)
            : widget.account?.level ?? 1,
        balance: widget.account?.balance ?? 0,
        currency: widget.account?.currency ?? 'YER',
        isActive: _isActive,
        isSystemAccount: widget.account?.isSystemAccount ?? false,
        canPost: _canPost,
        parentAccountId:
            widget.parentAccount?.id ?? widget.account?.parentAccountId,
        subAccounts: widget.account?.subAccounts ?? [],
        createdAt: widget.account?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(account);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 40,
              vertical: 20,
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 500;
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: 600,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
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
                        color: AppTheme.primaryCyan.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Column(
                          children: [
                            _buildHeader(isCompact),
                            Expanded(
                              child: _buildForm(isCompact),
                            ),
                            _buildActions(isCompact),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.15),
            AppTheme.primaryCyan.withOpacity(0.08),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 40 : 48,
            height: isCompact ? 40 : 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isEditing
                  ? CupertinoIcons.pencil_circle_fill
                  : CupertinoIcons.plus_circle_fill,
              color: Colors.white,
              size: isCompact ? 20 : 24,
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'تعديل الحساب' : 'حساب جديد',
                  style: (isCompact
                          ? AppTextStyles.heading3
                          : AppTextStyles.heading2)
                      .copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.parentAccount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'حساب فرعي من: ${widget.parentAccount!.nameAr}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textMuted,
              size: isCompact ? 20 : 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Number
            _buildTextField(
              controller: _accountNumberController,
              label: 'رقم الحساب',
              hint: 'مثال: 1100',
              icon: CupertinoIcons.number,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'رقم الحساب مطلوب';
                }
                return null;
              },
              readOnly: widget.account?.isSystemAccount ?? false,
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 12 : 16),

            // Arabic Name
            _buildTextField(
              controller: _nameArController,
              label: 'اسم الحساب بالعربية',
              hint: 'اسم الحساب',
              icon: CupertinoIcons.textformat,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'اسم الحساب بالعربية مطلوب';
                }
                return null;
              },
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 12 : 16),

            // English Name
            _buildTextField(
              controller: _nameEnController,
              label: 'اسم الحساب بالإنجليزية',
              hint: 'Account Name',
              icon: CupertinoIcons.textformat_alt,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'اسم الحساب بالإنجليزية مطلوب';
                }
                return null;
              },
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 12 : 16),

            // Account Type
            _buildDropdown<AccountType>(
              label: 'نوع الحساب',
              value: _selectedAccountType,
              items: AccountType.values,
              onChanged: widget.account?.isSystemAccount == true
                  ? null
                  : (value) {
                      setState(() {
                        _selectedAccountType = value!;
                        // Auto-adjust normal balance
                        _selectedNature = (value == AccountType.assets ||
                                value == AccountType.expenses)
                            ? AccountNature.debit
                            : AccountNature.credit;
                      });
                    },
              itemBuilder: (type) => Row(
                children: [
                  Icon(
                    _getAccountIcon(type),
                    size: 20,
                    color: _getAccountColor(type),
                  ),
                  const SizedBox(width: 8),
                  Text(type.nameAr),
                ],
              ),
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 12 : 16),

            // Normal Balance & Category
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<AccountNature>(
                    label: 'طبيعة الحساب',
                    value: _selectedNature,
                    items: AccountNature.values,
                    onChanged: (value) {
                      setState(() => _selectedNature = value!);
                    },
                    itemBuilder: (nature) => Text(nature.nameAr),
                    isCompact: isCompact,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown<AccountCategory>(
                    label: 'تصنيف الحساب',
                    value: _selectedCategory,
                    items: AccountCategory.values,
                    onChanged: widget.parentAccount != null
                        ? null
                        : (value) {
                            setState(() => _selectedCategory = value!);
                          },
                    itemBuilder: (category) => Text(category.nameAr),
                    isCompact: isCompact,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'وصف الحساب (اختياري)',
              hint: 'وصف مختصر للحساب',
              icon: CupertinoIcons.doc_text,
              maxLines: 3,
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 16 : 20),

            // Switches
            _buildSwitch(
              title: 'الحساب نشط',
              subtitle: 'يمكن استخدام الحساب في المعاملات',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 10 : 12),
            _buildSwitch(
              title: 'يمكن الترحيل إليه',
              subtitle: 'يمكن ترحيل المعاملات مباشرة لهذا الحساب',
              value: _canPost,
              onChanged: (value) => setState(() => _canPost = value),
              isCompact: isCompact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    int maxLines = 1,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            readOnly: readOnly,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                color: AppTheme.primaryCyan,
                size: isCompact ? 18 : 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isCompact ? 12 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    void Function(T?)? onChanged,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: itemBuilder(item),
                );
              }).toList(),
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: AppTheme.darkCard,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isCompact ? 8 : 10,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.primaryCyan.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 20 : 24,
                  vertical: isCompact ? 10 : 12,
                ),
              ),
              child: Text(
                isEditing ? 'تحديث' : 'إضافة',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.assets:
        return AppTheme.success;
      case AccountType.liabilities:
        return AppTheme.error;
      case AccountType.equity:
        return AppTheme.primaryBlue;
      case AccountType.revenue:
        return AppTheme.primaryPurple;
      case AccountType.expenses:
        return AppTheme.warning;
    }
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.assets:
        return CupertinoIcons.building_2_fill;
      case AccountType.liabilities:
        return CupertinoIcons.creditcard;
      case AccountType.equity:
        return CupertinoIcons.briefcase;
      case AccountType.revenue:
        return CupertinoIcons.arrow_up_circle_fill;
      case AccountType.expenses:
        return CupertinoIcons.arrow_down_circle_fill;
    }
  }
}
