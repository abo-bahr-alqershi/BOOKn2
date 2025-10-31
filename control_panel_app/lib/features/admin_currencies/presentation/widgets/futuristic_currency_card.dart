// lib/features/admin_currencies/presentation/widgets/futuristic_currency_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/currency.dart';
import 'package:intl/intl.dart';

class FuturisticCurrencyCard extends StatefulWidget {
  final Currency currency;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const FuturisticCurrencyCard({
    super.key,
    required this.currency,
    this.isSelected = false,
    this.isCompact = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
  });

  @override
  State<FuturisticCurrencyCard> createState() => _FuturisticCurrencyCardState();
}

class _FuturisticCurrencyCardState extends State<FuturisticCurrencyCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late AnimationController _rateChangeController;

  bool _isHovered = false;
  bool _showActions = false;
  double? _previousRate;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rateChangeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _previousRate = widget.currency.exchangeRate;
  }

  @override
  void didUpdateWidget(FuturisticCurrencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency.exchangeRate != widget.currency.exchangeRate) {
      _rateChangeController.forward().then((_) {
        _rateChangeController.reset();
      });
      _previousRate = oldWidget.currency.exchangeRate;
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    _rateChangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()
        ..scale(_isHovered ? 0.98 : 1.0)
        ..rotateZ(_isHovered ? 0.002 : 0),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() => _showActions = !_showActions);
        },
        onTapDown: (_) => _setHovered(true),
        onTapUp: (_) => _setHovered(false),
        onTapCancel: () => _setHovered(false),
        child: Stack(
          children: [
            Container(
              height: widget.isCompact ? 100 : null,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? AppTheme.primaryCyan.withValues(alpha: 0.3)
                        : AppTheme.shadowDark.withValues(alpha: 0.15),
                    blurRadius: widget.isSelected ? 25 : 15,
                    offset: const Offset(0, 10),
                    spreadRadius: widget.isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isSelected
                            ? [
                                AppTheme.primaryCyan.withValues(alpha: 0.15),
                                AppTheme.primaryBlue.withValues(alpha: 0.1),
                              ]
                            : widget.currency.isDefault
                                ? [
                                    AppTheme.success.withValues(alpha: 0.1),
                                    AppTheme.neonGreen.withValues(alpha: 0.05),
                                  ]
                                : [
                                    AppTheme.darkCard.withValues(alpha: 0.9),
                                    AppTheme.darkCard.withValues(alpha: 0.7),
                                  ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.currency.isDefault
                            ? AppTheme.success.withValues(alpha: 0.3)
                            : widget.isSelected
                                ? AppTheme.primaryCyan.withValues(alpha: 0.5)
                                : AppTheme.darkBorder.withValues(alpha: 0.2),
                        width: widget.currency.isDefault || widget.isSelected
                            ? 1.5
                            : 1,
                      ),
                    ),
                    child: widget.isCompact
                        ? _buildCompactContent()
                        : _buildFullContent(),
                  ),
                ),
              ),
            ),
            if (_showActions && !widget.isCompact) _buildActionsOverlay(),
            if (widget.currency.isDefault) _buildDefaultBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Currency symbol with gradient background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryCyan.withValues(alpha: 0.2),
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getCurrencySymbol(widget.currency.code),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                ),
              ),

              // Exchange rate indicator
              if (widget.currency.exchangeRate != null)
                _buildExchangeRateChip(),
            ],
          ),

          const SizedBox(height: 16),

          // Currency name
          Text(
            widget.currency.arabicName,
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.currency.name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),

          const SizedBox(height: 16),

          // Currency codes
          Row(
            children: [
              _buildCodeChip(widget.currency.code, isLatin: true),
              const SizedBox(width: 8),
              _buildCodeChip(widget.currency.arabicCode, isLatin: false),
            ],
          ),

          if (widget.currency.lastUpdated != null) ...[
            const SizedBox(height: 12),
            _buildLastUpdatedInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Currency symbol
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryCyan.withValues(alpha: 0.2),
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                _getCurrencySymbol(widget.currency.code),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryCyan,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Currency info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.currency.arabicName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.currency.exchangeRate != null)
                      _buildMiniExchangeRate(),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.currency.code,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.currency.arabicCode,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          _buildCompactActions(),
        ],
      ),
    );
  }

  Widget _buildExchangeRateChip() {
    final isIncreased = _previousRate != null &&
        widget.currency.exchangeRate != null &&
        widget.currency.exchangeRate! > _previousRate!;

    return AnimatedBuilder(
      animation: _rateChangeController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isIncreased
                  ? [
                      AppTheme.success.withValues(alpha: 0.2),
                      AppTheme.neonGreen.withValues(alpha: 0.1),
                    ]
                  : [
                      AppTheme.error.withValues(alpha: 0.2),
                      AppTheme.error.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isIncreased ? AppTheme.success : AppTheme.error)
                  .withValues(alpha: 0.3 + (_rateChangeController.value * 0.3)),
              width: 1,
            ),
            boxShadow: [
              if (_rateChangeController.value > 0)
                BoxShadow(
                  color: (isIncreased ? AppTheme.success : AppTheme.error)
                      .withValues(alpha: 0.2 * _rateChangeController.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncreased
                    ? CupertinoIcons.arrow_up_right_circle_fill
                    : CupertinoIcons.arrow_down_right_circle_fill,
                size: 16,
                color: isIncreased ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                widget.currency.exchangeRate!.toStringAsFixed(4),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isIncreased ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniExchangeRate() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.currency.exchangeRate!.toStringAsFixed(2),
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.primaryCyan,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCodeChip(String code, {required bool isLatin}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLatin
                ? CupertinoIcons.textformat
                : CupertinoIcons.text_alignright,
            size: 12,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            code,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return Row(
      children: [
        Icon(
          CupertinoIcons.clock,
          size: 12,
          color: AppTheme.textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'آخر تحديث: ${formatter.format(widget.currency.lastUpdated!)}',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.success,
                  AppTheme.neonGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withValues(
                    alpha: 0.3 + (0.1 * _pulseController.value),
                  ),
                  blurRadius: 8 + (4 * _pulseController.value),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'افتراضية',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionsOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Wrap(
              spacing: 12,
              children: [
                if (!widget.currency.isDefault)
                  _buildActionButton(
                    icon: CupertinoIcons.star,
                    label: 'تعيين كافتراضية',
                    onTap: () {
                      setState(() => _showActions = false);
                      widget.onSetDefault?.call();
                    },
                    color: AppTheme.warning,
                  ),
                _buildActionButton(
                  icon: CupertinoIcons.pencil,
                  label: 'تعديل',
                  onTap: () {
                    setState(() => _showActions = false);
                    widget.onEdit?.call();
                  },
                  color: AppTheme.primaryBlue,
                ),
                if (!widget.currency.isDefault)
                  _buildActionButton(
                    icon: CupertinoIcons.trash,
                    label: 'حذف',
                    onTap: () {
                      setState(() => _showActions = false);
                      widget.onDelete?.call();
                    },
                    color: AppTheme.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.currency.isDefault)
          IconButton(
            onPressed: widget.onSetDefault,
            icon: Icon(
              CupertinoIcons.star,
              color: AppTheme.warning,
              size: 18,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        IconButton(
          onPressed: widget.onEdit,
          icon: Icon(
            CupertinoIcons.pencil,
            color: AppTheme.primaryBlue,
            size: 18,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  String _getCurrencySymbol(String code) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'SAR': '﷼',
      'AED': 'د.إ',
      'KWD': 'د.ك',
      'QAR': 'ر.ق',
      'OMR': 'ر.ع',
      'BHD': 'د.ب',
      'JOD': 'د.أ',
      'EGP': 'ج.م',
      'LBP': 'ل.ل',
    };
    return symbols[code] ?? code.substring(0, 1);
  }

  void _setHovered(bool value) {
    setState(() => _isHovered = value);
    if (value) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
}
