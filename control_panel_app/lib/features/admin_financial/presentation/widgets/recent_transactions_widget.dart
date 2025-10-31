// lib/features/admin_financial/presentation/widgets/futuristic_recent_transactions.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/financial_transaction.dart';

class RecentTransactionsWidget extends StatefulWidget {
  final List<FinancialTransaction> transactions;
  final Function(String)? onTransactionTap;
  final VoidCallback? onViewAllTap;

  const RecentTransactionsWidget({
    super.key,
    required this.transactions,
    this.onTransactionTap,
    this.onViewAllTap,
  });

  @override
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  bool _isExpanded = false;
  final int _displayCount = 5;

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _headerSlideAnimation = Tween<double>(
      begin: -20,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeIn,
    ));

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              if (widget.transactions.isEmpty)
                _buildEmptyState()
              else
                _buildTransactionsList(),
              if (widget.transactions.length > _displayCount && !_isExpanded)
                _buildShowMoreButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryCyan.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.darkBorder.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Animated Icon
                  AnimatedBuilder(
                    animation: _pulseAnimationController,
                    builder: (context, child) {
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryCyan.withOpacity(
                                0.2 + (_pulseAnimationController.value * 0.1),
                              ),
                              AppTheme.primaryPurple.withOpacity(
                                0.2 + (_pulseAnimationController.value * 0.1),
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryCyan.withOpacity(
                                0.2 * _pulseAnimationController.value,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.arrow_right_arrow_left_circle_fill,
                          color: AppTheme.primaryCyan,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'المعاملات الأخيرة',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 0,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: _buildTransactionCountBadge(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSubtitleText(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // View All Button
                  if (widget.onViewAllTap != null)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _buildViewAllButton(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.2),
            AppTheme.primaryPurple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
        ),
      ),
      child: Text(
        '${widget.transactions.length}',
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.primaryCyan,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildViewAllButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onViewAllTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'عرض الكل',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.arrow_right,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final displayTransactions = _isExpanded
        ? widget.transactions
        : widget.transactions.take(_displayCount).toList();

    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: displayTransactions.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 30,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FuturisticTransactionCard(
                    transaction: displayTransactions[index],
                    index: index,
                    onTap: widget.onTransactionTap != null
                        ? () => widget.onTransactionTap!(
                              displayTransactions[index].id,
                            )
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Empty Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkBorder.withOpacity(0.1),
                        AppTheme.darkBorder.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.doc_text,
                    color: AppTheme.textMuted,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد معاملات',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر المعاملات المالية هنا',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isExpanded = true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkBackground.withOpacity(0.5),
                AppTheme.darkBackground.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chevron_down,
                color: AppTheme.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'عرض المزيد (${widget.transactions.length - _displayCount})',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitleText() {
    if (widget.transactions.isEmpty) {
      return 'لا توجد معاملات لعرضها';
    }

    final now = DateTime.now();
    final mostRecent = widget.transactions.first.transactionDate;
    final difference = now.difference(mostRecent);

    if (difference.inMinutes < 1) {
      return 'آخر تحديث: الآن';
    } else if (difference.inMinutes < 60) {
      return 'آخر تحديث: منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'آخر تحديث: منذ ${difference.inHours} ساعة';
    } else {
      return 'آخر تحديث: منذ ${difference.inDays} يوم';
    }
  }
}

class _FuturisticTransactionCard extends StatefulWidget {
  final FinancialTransaction transaction;
  final int index;
  final VoidCallback? onTap;

  const _FuturisticTransactionCard({
    required this.transaction,
    required this.index,
    this.onTap,
  });

  @override
  State<_FuturisticTransactionCard> createState() =>
      _FuturisticTransactionCardState();
}

class _FuturisticTransactionCardState extends State<_FuturisticTransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDebit = _isDebitTransaction();
    final transactionColor = isDebit ? AppTheme.error : AppTheme.success;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? _handleTapDown : null,
        onTapUp: widget.onTap != null ? _handleTapUp : null,
        onTapCancel: widget.onTap != null ? _handleTapCancel : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkBackground.withOpacity(
                        _isHovered ? 0.9 : 0.7,
                      ),
                      AppTheme.darkBackground.withOpacity(
                        _isHovered ? 0.8 : 0.5,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPressed
                        ? transactionColor.withOpacity(0.3)
                        : _isHovered
                            ? AppTheme.darkBorder.withOpacity(0.3)
                            : AppTheme.darkBorder.withOpacity(0.15),
                    width: _isPressed ? 1.5 : 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: transactionColor.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background Pattern
                      if (_isHovered)
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  transactionColor.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Main Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 420;

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildTransactionIcon(transactionColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: _buildTransactionDetails(
                                              isDebit)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: _buildTransactionAmount(
                                        transactionColor, isDebit),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildTransactionIcon(transactionColor),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _buildTransactionDetails(isDebit)),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: _buildTransactionAmount(
                                          transactionColor, isDebit),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
    );
  }

  Widget _buildTransactionIcon(Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Text(
          widget.transaction.transactionIcon,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(bool isDebit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          widget.transaction.description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Info Row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Type Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkBorder.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.2),
                ),
              ),
              child: Text(
                widget.transaction.transactionType.nameAr,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ),

            // Status Badge
            _buildStatusBadge(),

            // Date
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 12,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(widget.transaction.transactionDate),
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Reference Number
        if (widget.transaction.referenceNumber != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                CupertinoIcons.number,
                size: 10,
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'المرجع: ${widget.transaction.referenceNumber}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionAmount(Color color, bool isDebit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDebit ? '-' : '+',
              style: AppTextStyles.bodyLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              Formatters.formatCurrency(
                widget.transaction.amount,
                widget.transaction.currency,
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_isHovered)
          Icon(
            CupertinoIcons.chevron_right,
            color: AppTheme.textMuted,
            size: 14,
          ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.2),
            statusColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        widget.transaction.status.nameAr,
        style: AppTextStyles.caption.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  bool _isDebitTransaction() {
    switch (widget.transaction.transactionType) {
      case TransactionType.newBooking:
      case TransactionType.advancePayment:
      case TransactionType.finalPayment:
      case TransactionType.platformCommission:
      case TransactionType.serviceFee:
      case TransactionType.lateFee:
      case TransactionType.otherIncome:
        return false;
      case TransactionType.bookingCancellation:
      case TransactionType.refund:
      case TransactionType.ownerPayout:
      case TransactionType.tax:
      case TransactionType.discount:
      case TransactionType.compensation:
      case TransactionType.securityDepositRefund:
      case TransactionType.interAccountTransfer:
      case TransactionType.adjustment:
      case TransactionType.openingBalance:
      case TransactionType.agentCommission:
      case TransactionType.operationalExpense:
      case TransactionType.securityDeposit:
        return true;
    }
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours}س';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays}ي';
    } else {
      return Formatters.formatDate(dateTime);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
}
