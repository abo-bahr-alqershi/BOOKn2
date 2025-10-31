// lib/features/admin_financial/presentation/widgets/futuristic_transaction_details.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/financial_transaction.dart';

class TransactionDetailsDialog extends StatefulWidget {
  final FinancialTransaction transaction;
  final VoidCallback? onPost;
  final VoidCallback? onReverse;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
    this.onPost,
    this.onReverse,
  });

  @override
  State<TransactionDetailsDialog> createState() =>
      _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState extends State<TransactionDetailsDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _tabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

    _tabController = TabController(
      length: 4,
      vsync: this,
    );

    _tabController.addListener(() {
      setState(() => _currentTabIndex = _tabController.index);
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
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
              vertical: MediaQuery.of(context).size.height < 700 ? 20 : 40,
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
                        color: _getStatusColor().withOpacity(0.3),
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
                            _buildTabBar(isCompact),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _buildGeneralTab(isCompact),
                                  _buildFinancialTab(isCompact),
                                  _buildAccountingTab(isCompact),
                                  _buildAuditTab(isCompact),
                                ],
                              ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor().withOpacity(0.2),
            _getStatusColor().withOpacity(0.1),
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
          // Icon
          Container(
            width: isCompact ? 40 : 48,
            height: isCompact ? 40 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTransactionColor(),
                  _getTransactionColor().withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getTransactionColor().withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.transaction.transactionIcon,
                style: TextStyle(fontSize: isCompact ? 20 : 24),
              ),
            ),
          ),

          SizedBox(width: isCompact ? 12 : 16),

          // Title & Number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل المعاملة',
                  style: (isCompact
                          ? AppTextStyles.heading3
                          : AppTextStyles.heading2)
                      .copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.transaction.transactionNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.primaryCyan,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(isSmall: isCompact),
                  ],
                ),
              ],
            ),
          ),

          // Close Button
          IconButton(
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textMuted,
              size: isCompact ? 20 : 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isCompact) {
    return Container(
      height: isCompact ? 40 : 48,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isCompact,
        indicatorColor: AppTheme.primaryCyan,
        indicatorWeight: 2,
        labelColor: AppTheme.primaryCyan,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tabs: [
          Tab(
            icon: Icon(CupertinoIcons.info_circle, size: isCompact ? 14 : 16),
            text: 'عام',
          ),
          Tab(
            icon: Icon(CupertinoIcons.money_dollar_circle,
                size: isCompact ? 14 : 16),
            text: 'مالية',
          ),
          Tab(
            icon: Icon(CupertinoIcons.chart_bar, size: isCompact ? 14 : 16),
            text: 'محاسبية',
          ),
          Tab(
            icon: Icon(CupertinoIcons.clock, size: isCompact ? 14 : 16),
            text: 'تدقيق',
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'معلومات أساسية',
            icon: CupertinoIcons.info_circle,
            isCompact: isCompact,
            children: [
              _buildInfoRow('التاريخ',
                  Formatters.formatDateTime(widget.transaction.transactionDate),
                  isCompact: isCompact),
              _buildInfoRow('النوع', widget.transaction.transactionType.nameAr,
                  isCompact: isCompact),
              _buildInfoRow('نوع القيد', widget.transaction.entryType.nameAr,
                  isCompact: isCompact),
              _buildInfoRow('الحالة', widget.transaction.status.nameAr,
                  valueColor: _getStatusColor(), isCompact: isCompact),
            ],
          ),
          SizedBox(height: isCompact ? 16 : 20),
          _buildSection(
            title: 'الوصف',
            icon: CupertinoIcons.doc_text,
            isCompact: isCompact,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction.description,
                      style: (isCompact
                              ? AppTextStyles.bodySmall
                              : AppTextStyles.bodyMedium)
                          .copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    if (widget.transaction.narration != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.transaction.narration!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.transaction.referenceNumber != null ||
              widget.transaction.bookingId != null ||
              widget.transaction.paymentId != null) ...[
            SizedBox(height: isCompact ? 16 : 20),
            _buildSection(
              title: 'المراجع',
              icon: CupertinoIcons.link,
              isCompact: isCompact,
              children: [
                if (widget.transaction.referenceNumber != null)
                  _buildInfoRow(
                      'رقم المرجع', widget.transaction.referenceNumber!,
                      isCompact: isCompact),
                if (widget.transaction.bookingId != null)
                  _buildInfoRow('رقم الحجز', widget.transaction.bookingId!,
                      isCompact: isCompact),
                if (widget.transaction.paymentId != null)
                  _buildInfoRow('رقم الدفعة', widget.transaction.paymentId!,
                      isCompact: isCompact),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialTab(bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildAmountCard(isCompact),
          SizedBox(height: isCompact ? 16 : 20),
          _buildSection(
            title: 'تفاصيل مالية',
            icon: CupertinoIcons.money_dollar_circle,
            isCompact: isCompact,
            children: [
              _buildInfoRow('العملة', widget.transaction.currency,
                  isCompact: isCompact),
              if (widget.transaction.exchangeRate != 1.0)
                _buildInfoRow(
                    'سعر الصرف', widget.transaction.exchangeRate.toString(),
                    isCompact: isCompact),
              _buildInfoRow(
                  'المبلغ الأساسي',
                  Formatters.formatCurrency(
                    widget.transaction.baseAmount,
                    widget.transaction.currency,
                  ),
                  isCompact: isCompact),
              if (widget.transaction.commission != null)
                _buildInfoRow(
                    'العمولة',
                    Formatters.formatCurrency(
                      widget.transaction.commission!,
                      widget.transaction.currency,
                    ),
                    isCompact: isCompact),
              if (widget.transaction.tax != null)
                _buildInfoRow(
                    'الضريبة',
                    Formatters.formatCurrency(
                      widget.transaction.tax!,
                      widget.transaction.currency,
                    ),
                    isCompact: isCompact),
              if (widget.transaction.netAmount != null)
                _buildInfoRow(
                    'الصافي',
                    Formatters.formatCurrency(
                      widget.transaction.netAmount!,
                      widget.transaction.currency,
                    ),
                    valueColor: AppTheme.success,
                    isCompact: isCompact),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingTab(bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildSection(
            title: 'معلومات محاسبية',
            icon: CupertinoIcons.chart_bar,
            isCompact: isCompact,
            children: [
              _buildInfoRow(
                  'السنة المالية', widget.transaction.fiscalYear.toString(),
                  isCompact: isCompact),
              _buildInfoRow(
                  'الفترة المالية', widget.transaction.fiscalPeriod.toString(),
                  isCompact: isCompact),
              if (widget.transaction.costCenter != null)
                _buildInfoRow('مركز التكلفة', widget.transaction.costCenter!,
                    isCompact: isCompact),
              if (widget.transaction.project != null)
                _buildInfoRow('المشروع', widget.transaction.project!,
                    isCompact: isCompact),
            ],
          ),
          if (widget.transaction.isPosted) ...[
            SizedBox(height: isCompact ? 16 : 20),
            _buildSection(
              title: 'معلومات الترحيل',
              icon: CupertinoIcons.checkmark_seal,
              isCompact: isCompact,
              children: [
                _buildInfoRow('مرحّل', 'نعم',
                    valueColor: AppTheme.success, isCompact: isCompact),
                if (widget.transaction.postingDate != null)
                  _buildInfoRow(
                      'تاريخ الترحيل',
                      Formatters.formatDateTime(
                          widget.transaction.postingDate!),
                      isCompact: isCompact),
                if (widget.transaction.approvedBy != null)
                  _buildInfoRow('اعتمد بواسطة', widget.transaction.approvedBy!,
                      isCompact: isCompact),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditTab(bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildSection(
            title: 'معلومات التدقيق',
            icon: CupertinoIcons.clock,
            isCompact: isCompact,
            children: [
              _buildInfoRow('أنشئ بواسطة', widget.transaction.createdBy,
                  isCompact: isCompact),
              _buildInfoRow('تاريخ الإنشاء',
                  Formatters.formatDateTime(widget.transaction.createdAt),
                  isCompact: isCompact),
              if (widget.transaction.updatedBy != null)
                _buildInfoRow('آخر تعديل', widget.transaction.updatedBy!,
                    isCompact: isCompact),
              if (widget.transaction.updatedAt != null)
                _buildInfoRow('تاريخ التعديل',
                    Formatters.formatDateTime(widget.transaction.updatedAt!),
                    isCompact: isCompact),
              if (widget.transaction.isAutomatic)
                _buildInfoRow(
                    'مصدر تلقائي', widget.transaction.automaticSource ?? 'نظام',
                    isCompact: isCompact),
            ],
          ),
          if (widget.transaction.isReversed) ...[
            SizedBox(height: isCompact ? 16 : 20),
            _buildSection(
              title: 'معلومات العكس',
              icon: CupertinoIcons.arrow_2_squarepath,
              isCompact: isCompact,
              children: [
                _buildInfoRow('معكوس', 'نعم',
                    valueColor: AppTheme.warning, isCompact: isCompact),
                if (widget.transaction.reverseTransactionId != null)
                  _buildInfoRow(
                    'رقم معاملة العكس',
                    widget.transaction.reverseTransactionId!,
                    isCompact: isCompact,
                  ),
                if (widget.transaction.cancelledAt != null)
                  _buildInfoRow(
                    'تاريخ الإلغاء',
                    Formatters.formatDateTime(widget.transaction.cancelledAt!),
                    isCompact: isCompact,
                  ),
                if (widget.transaction.cancelledBy != null)
                  _buildInfoRow(
                    'تم الإلغاء بواسطة',
                    widget.transaction.cancelledBy!,
                    isCompact: isCompact,
                  ),
                if (widget.transaction.cancellationReason != null)
                  _buildInfoRow(
                    'سبب الإلغاء',
                    widget.transaction.cancellationReason!,
                    isCompact: isCompact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTransactionColor().withOpacity(0.2),
            _getTransactionColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTransactionColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.money_dollar_circle_fill,
            color: _getTransactionColor(),
            size: isCompact ? 32 : 40,
          ),
          const SizedBox(height: 12),
          Text(
            'المبلغ',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(
              widget.transaction.amount,
              widget.transaction.currency,
            ),
            style: (isCompact ? AppTextStyles.heading3 : AppTextStyles.heading2)
                .copyWith(
              color: _getTransactionColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: isCompact ? 28 : 32,
              height: isCompact ? 28 : 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryCyan,
                size: isCompact ? 14 : 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: (isCompact
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLarge)
                  .copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 10 : 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    required bool isCompact,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 3 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: (isCompact ? AppTextStyles.caption : AppTextStyles.bodySmall)
                .copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style:
                  (isCompact ? AppTextStyles.caption : AppTextStyles.bodySmall)
                      .copyWith(
                color: valueColor ?? AppTheme.textLight,
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
          if (widget.transaction.canReverse && widget.onReverse != null) ...[
            _buildActionButton(
              label: 'عكس المعاملة',
              icon: CupertinoIcons.arrow_2_squarepath,
              color: AppTheme.warning,
              onTap: widget.onReverse!,
              isCompact: isCompact,
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          if (widget.transaction.canPost && widget.onPost != null) ...[
            _buildActionButton(
              label: 'ترحيل',
              icon: CupertinoIcons.checkmark_circle_fill,
              color: AppTheme.success,
              onTap: widget.onPost!,
              isCompact: isCompact,
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          _buildActionButton(
            label: 'إغلاق',
            icon: CupertinoIcons.xmark,
            color: AppTheme.textMuted,
            onTap: () => Navigator.of(context).pop(),
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isCompact,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: isCompact ? 14 : 16,
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Text(
              label,
              style:
                  (isCompact ? AppTextStyles.caption : AppTextStyles.bodySmall)
                      .copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.2),
            _getStatusColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.5),
        ),
      ),
      child: Text(
        widget.transaction.status.nameAr,
        style: AppTextStyles.caption.copyWith(
          color: _getStatusColor(),
          fontWeight: FontWeight.bold,
          fontSize: isSmall ? 9 : 10,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.transaction.status) {
      case TransactionStatus.draft:
        return AppTheme.textMuted;
      case TransactionStatus.pending:
        return AppTheme.warning;
      case TransactionStatus.approved:
        return AppTheme.success;
      case TransactionStatus.posted:
        return AppTheme.primaryCyan;
      case TransactionStatus.rejected:
        return AppTheme.error;
      case TransactionStatus.cancelled:
        return AppTheme.textMuted;
      case TransactionStatus.reversed:
        return AppTheme.primaryPurple;
    }
  }

  Color _getTransactionColor() {
    switch (widget.transaction.transactionType) {
      case TransactionType.newBooking:
      case TransactionType.advancePayment:
      case TransactionType.finalPayment:
      case TransactionType.platformCommission:
      case TransactionType.serviceFee:
      case TransactionType.lateFee:
      case TransactionType.otherIncome:
        return AppTheme.success;
      case TransactionType.bookingCancellation:
      case TransactionType.refund:
      case TransactionType.ownerPayout:
      case TransactionType.operationalExpense:
        return AppTheme.error;
      default:
        return AppTheme.primaryCyan;
    }
  }
}
