import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/booking.dart';
import 'booking_status_badge.dart';
import '../../../../core/widgets/booking_identity_card_tooltip.dart';

class FuturisticBookingCard extends StatefulWidget {
  final Booking booking;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showActions;
  final bool isCompact;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;

  const FuturisticBookingCard({
    super.key,
    required this.booking,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.showActions = false,
    this.isCompact = false,
    this.onConfirm,
    this.onCancel,
    this.onCheckIn,
    this.onCheckOut,
  });

  @override
  State<FuturisticBookingCard> createState() => _FuturisticBookingCardState();
}

class _FuturisticBookingCardState extends State<FuturisticBookingCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  late AnimationController _animationController;
  bool _isHovered = false;
  bool _isPressed = false;

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

  void _showBookingCard() {
    setState(() => _isPressed = true);
    
    HapticFeedback.mediumImpact();
    
    final booking = widget.booking;
    BookingIdentityCardTooltip.show(
      context: context,
      targetKey: _cardKey,
      bookingId: booking.id,
      userName: booking.userName,
      unitName: booking.unitName,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      guestsCount: booking.guestsCount,
      totalAmount: booking.totalPrice.amount,
      currency: booking.totalPrice.currency,
      status: booking.status,
      bookedAt: booking.bookedAt,
      propertyName: booking.propertyName,
      unitImage: booking.unitImage,
      userEmail: booking.userEmail,
      userPhone: booking.userPhone,
      notes: booking.notes,
      specialRequests: booking.specialRequests,
      paymentStatus: booking.paymentStatus,
      bookingSource: booking.bookingSource,
      isWalkIn: booking.isWalkIn,
      confirmedAt: booking.confirmedAt,
      checkedInAt: booking.checkedInAt,
      checkedOutAt: booking.checkedOutAt,
      cancelledAt: booking.cancelledAt,
      cancellationReason: booking.cancellationReason,
    );
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
      child: GestureDetector(
        key: _cardKey,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress ?? _showBookingCard,
        onTapDown: (_) => _setHovered(true),
        onTapUp: (_) => _setHovered(false),
        onTapCancel: () => _setHovered(false),
        child: Container(
          margin: EdgeInsets.only(bottom: widget.isCompact ? 8 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                    : AppTheme.shadowDark.withValues(alpha: 0.1),
                blurRadius: widget.isSelected ? 20 : 15,
                offset: const Offset(0, 8),
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
                            AppTheme.primaryBlue.withValues(alpha: 0.15),
                            AppTheme.primaryPurple.withValues(alpha: 0.1),
                          ]
                        : [
                            AppTheme.darkCard.withValues(alpha: 0.8),
                            AppTheme.darkCard.withValues(alpha: 0.6),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isPressed
                        ? AppTheme.primaryBlue.withValues(alpha: 0.7)
                        : widget.isSelected
                            ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                            : AppTheme.darkBorder.withValues(alpha: 0.2),
                    width: _isPressed || widget.isSelected ? 2 : 1,
                  ),
                ),
                child: widget.isCompact
                    ? _buildCompactContent()
                    : _buildFullContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // إصلاح مشكلة overflow في Column (السطر 121)
  Widget _buildFullContent() {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: _buildBody(),
          ),
          if (widget.showActions) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildCompactImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.booking.unitName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BookingStatusBadge(
                      status: widget.booking.status,
                      size: BadgeSize.small,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.booking.userName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${Formatters.formatDate(widget.booking.checkIn)} - ${Formatters.formatDate(widget.booking.checkOut)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 10,
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
          _buildCompactPrice(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.booking.unitImage != null)
            CachedImageWidget(
              imageUrl: widget.booking.unitImage!,
              fit: BoxFit.cover,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.darkBackground.withValues(alpha: 0.7),
                ],
                stops: const [0.5, 1.0],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.photo,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: BookingStatusBadge(
              status: widget.booking.status,
              size: BadgeSize.medium,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _buildOverflowMenu(),
          ),
          if (widget.isSelected)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.checkmark,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.booking.unitName,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.booking.propertyName != null)
                  Text(
                    widget.booking.propertyName!,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 5,
                        ),
                      ],
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

  Widget _buildOverflowMenu() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCardActionsMenu,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(CupertinoIcons.ellipsis, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  void _showCardActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.eye, color: Colors.white),
                title: Text('عرض التفاصيل', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                onTap: () { Navigator.pop(context); widget.onTap?.call(); },
              ),
              if (widget.booking.canConfirm)
                ListTile(
                  leading: Icon(CupertinoIcons.checkmark_circle, color: AppTheme.success),
                  title: Text('تأكيد الحجز', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                  onTap: () { Navigator.pop(context); widget.onConfirm?.call(); },
                ),
              if (widget.booking.canCancel)
                ListTile(
                  leading: Icon(CupertinoIcons.xmark_circle, color: AppTheme.error),
                  title: Text('إلغاء الحجز', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                  onTap: () { Navigator.pop(context); widget.onCancel?.call(); },
                ),
              if (widget.booking.canCheckIn)
                ListTile(
                  leading: Icon(CupertinoIcons.arrow_down_circle, color: AppTheme.success),
                  title: Text('تسجيل وصول', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                  onTap: () { Navigator.pop(context); widget.onCheckIn?.call(); },
                ),
              if (widget.booking.canCheckOut)
                ListTile(
                  leading: Icon(CupertinoIcons.arrow_up_circle, color: AppTheme.warning),
                  title: Text('تسجيل مغادرة', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                  onTap: () { Navigator.pop(context); widget.onCheckOut?.call(); },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoRow(
            icon: CupertinoIcons.person_fill,
            label: widget.booking.userName,
            color: AppTheme.textWhite,
          ),
          const SizedBox(height: 12),
          _buildDateSection(),
          const SizedBox(height: 12),
          _buildStatsSection(),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // للشاشات الصغيرة، عرض التواريخ بشكل عمودي
        if (constraints.maxWidth < 300) {
          return Column(
            children: [
              _buildDateChip(
                icon: CupertinoIcons.arrow_down_circle,
                label: 'وصول',
                date: widget.booking.checkIn,
                color: AppTheme.success,
                isFullWidth: true,
              ),
              const SizedBox(height: 8),
              _buildDateChip(
                icon: CupertinoIcons.arrow_up_circle,
                label: 'مغادرة',
                date: widget.booking.checkOut,
                color: AppTheme.error,
                isFullWidth: true,
              ),
            ],
          );
        }
        // للشاشات الكبيرة، عرض التواريخ بشكل أفقي
        return Row(
          children: [
            Expanded(
              child: _buildDateChip(
                icon: CupertinoIcons.arrow_down_circle,
                label: 'وصول',
                date: widget.booking.checkIn,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateChip(
                icon: CupertinoIcons.arrow_up_circle,
                label: 'مغادرة',
                date: widget.booking.checkOut,
                color: AppTheme.error,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatChip(
              icon: CupertinoIcons.moon_fill,
              value: '${widget.booking.nights}',
              label: 'ليلة',
              constraints: constraints,
            ),
            _buildStatChip(
              icon: CupertinoIcons.person_2_fill,
              value: '${widget.booking.guestsCount}',
              label: 'ضيف',
              constraints: constraints,
            ),
            _buildPriceTag(),
          ],
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttons = <Widget>[];

          buttons.add(
            _buildActionButton(
              icon: CupertinoIcons.eye,
              label: 'عرض',
              onTap: widget.onTap,
              isCompact: constraints.maxWidth < 350,
            ),
          );

          if (widget.booking.canCheckIn) {
            buttons.add(const SizedBox(width: 8));
            buttons.add(
              _buildActionButton(
                icon: CupertinoIcons.arrow_down_circle,
                label: 'تسجيل وصول',
                onTap: () {},
                isPrimary: true,
                isCompact: constraints.maxWidth < 350,
              ),
            );
          }

          if (widget.booking.canCheckOut) {
            buttons.add(const SizedBox(width: 8));
            buttons.add(
              _buildActionButton(
                icon: CupertinoIcons.arrow_up_circle,
                label: 'تسجيل مغادرة',
                onTap: () {},
                isPrimary: true,
                isCompact: constraints.maxWidth < 350,
              ),
            );
          }

          // للشاشات الصغيرة جداً، عرض الأزرار بشكل عمودي
          if (constraints.maxWidth < 250) {
            return Column(
              children: buttons.where((w) => w is! SizedBox).map((button) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: button,
                  ),
                );
              }).toList(),
            );
          }

          return Row(
            children: buttons.map((button) {
              if (button is SizedBox) return button;
              return Expanded(child: button);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required DateTime date,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.formatDate(date),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // إصلاح مشكلة overflow في Row (السطر 340)
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required BoxConstraints constraints,
  }) {
    // حساب العرض المناسب بناءً على حجم الشاشة
    final isCompact = constraints.maxWidth < 300;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: AppTheme.textMuted,
          ),
          SizedBox(width: isCompact ? 2 : 4),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 12 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isCompact ? 1 : 2),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontSize: isCompact ? 9 : 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        Formatters.formatCurrency(
          widget.booking.totalPrice.amount,
          widget.booking.totalPrice.currency,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // إصلاح مشكلة overflow في Row (السطر 441)
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: isPrimary ? AppTheme.primaryGradient : null,
        color:
            isPrimary ? null : AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: isPrimary
            ? null
            : Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.3),
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
            ),
            child: Center(
              child: isCompact
                  ? Icon(
                      icon,
                      size: 16,
                      color: isPrimary ? Colors.white : AppTheme.textMuted,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isPrimary ? Colors.white : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  isPrimary ? Colors.white : AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildCompactImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppTheme.primaryGradient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.booking.unitImage != null
            ? CachedImageWidget(
                imageUrl: widget.booking.unitImage!,
                fit: BoxFit.cover,
              )
            : Center(
                child: Text(
                  widget.booking.unitName.length >= 2
                      ? widget.booking.unitName.substring(0, 2).toUpperCase()
                      : widget.booking.unitName.toUpperCase(),
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCompactPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            Formatters.formatCurrency(
              widget.booking.totalPrice.amount,
              widget.booking.totalPrice.currency,
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${widget.booking.nights} ليلة',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _setHovered(bool value) {
    setState(() => _isHovered = value);
    if (value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
