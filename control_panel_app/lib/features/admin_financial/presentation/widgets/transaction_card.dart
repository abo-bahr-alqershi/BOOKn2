// lib/features/admin_financial/presentation/widgets/futuristic_transaction_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/financial_transaction.dart';

class TransactionCard extends StatefulWidget {
  final FinancialTransaction transaction;
  final VoidCallback onTap;
  final bool isCompact;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactCard();
    }
    return _buildFullCard();
  }

  Widget _buildFullCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()
        ..scale(_isHovered ? 0.98 : 1.0)
        ..rotateZ(_isHovered ? 0.002 : 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.8),
                AppTheme.darkCard.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor().withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBody()),
                  if (widget.transaction.canPost ||
                      widget.transaction.canReverse)
                    _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.5),
              AppTheme.darkCard.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTransactionColor(),
                    _getTransactionColor().withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.transaction.transactionIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.transaction.transactionNumber,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(isSmall: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.transaction.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(
                    widget.transaction.amount,
                    widget.transaction.currency,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _getTransactionColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Formatters.formatDate(widget.transaction.transactionDate),
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.15),
            _getStatusColor().withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
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
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.transaction.transactionNumber,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.transaction.transactionType.nameAr,
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

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Description
                Text(
                  widget.transaction.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Details Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: CupertinoIcons.money_dollar_circle,
                        label: 'المبلغ',
                        value: Formatters.formatCurrency(
                          widget.transaction.amount,
                          widget.transaction.currency,
                        ),
                        valueColor: _getTransactionColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailItem(
                        icon: CupertinoIcons.calendar,
                        label: 'التاريخ',
                        value: Formatters.formatDate(
                            widget.transaction.transactionDate),
                      ),
                    ),
                  ],
                ),

                if (widget.transaction.referenceNumber != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    icon: CupertinoIcons.tag,
                    label: 'المرجع',
                    value: widget.transaction.referenceNumber!,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryCyan,
          ),
          const SizedBox(width: 8),
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
                  style: AppTextStyles.bodySmall.copyWith(
                    color: valueColor ?? AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.transaction.canPost)
            _buildActionButton(
              icon: CupertinoIcons.checkmark_circle,
              label: 'ترحيل',
              color: AppTheme.success,
              onTap: widget.onTap,
            ),
          if (widget.transaction.canPost && widget.transaction.canReverse)
            const SizedBox(width: 8),
          if (widget.transaction.canReverse)
            _buildActionButton(
              icon: CupertinoIcons.arrow_2_squarepath,
              label: 'عكس',
              color: AppTheme.warning,
              onTap: widget.onTap,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
