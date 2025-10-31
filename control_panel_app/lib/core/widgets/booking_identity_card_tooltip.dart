import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../enums/booking_status.dart';

/// Booking Identity Card Tooltip - بطاقة الحجز المنبثقة
class BookingIdentityCardTooltip {
  static OverlayEntry? _overlayEntry;
  static final GlobalKey<_BookingCardContentState> _contentKey = GlobalKey();

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String bookingId,
    required String userName,
    required String unitName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestsCount,
    required double totalAmount,
    required String currency,
    required BookingStatus status,
    required DateTime bookedAt,
    String? propertyName,
    String? unitImage,
    String? userEmail,
    String? userPhone,
    String? notes,
    String? specialRequests,
    String? paymentStatus,
    String? bookingSource,
    bool? isWalkIn,
    DateTime? confirmedAt,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => _BookingCardOverlay(
        targetKey: targetKey,
        bookingId: bookingId,
        userName: userName,
        unitName: unitName,
        checkIn: checkIn,
        checkOut: checkOut,
        guestsCount: guestsCount,
        totalAmount: totalAmount,
        currency: currency,
        status: status,
        bookedAt: bookedAt,
        propertyName: propertyName,
        unitImage: unitImage,
        userEmail: userEmail,
        userPhone: userPhone,
        notes: notes,
        specialRequests: specialRequests,
        paymentStatus: paymentStatus,
        bookingSource: bookingSource,
        isWalkIn: isWalkIn,
        confirmedAt: confirmedAt,
        checkedInAt: checkedInAt,
        checkedOutAt: checkedOutAt,
        cancelledAt: cancelledAt,
        cancellationReason: cancellationReason,
        contentKey: _contentKey,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _contentKey.currentState?.animateOut(() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

class _BookingCardOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String bookingId;
  final String userName;
  final String unitName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestsCount;
  final double totalAmount;
  final String currency;
  final BookingStatus status;
  final DateTime bookedAt;
  final String? propertyName;
  final String? unitImage;
  final String? userEmail;
  final String? userPhone;
  final String? notes;
  final String? specialRequests;
  final String? paymentStatus;
  final String? bookingSource;
  final bool? isWalkIn;
  final DateTime? confirmedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final GlobalKey<_BookingCardContentState> contentKey;

  const _BookingCardOverlay({
    required this.targetKey,
    required this.bookingId,
    required this.userName,
    required this.unitName,
    required this.checkIn,
    required this.checkOut,
    required this.guestsCount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.bookedAt,
    this.propertyName,
    this.unitImage,
    this.userEmail,
    this.userPhone,
    this.notes,
    this.specialRequests,
    this.paymentStatus,
    this.bookingSource,
    this.isWalkIn,
    this.confirmedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: BookingIdentityCardTooltip.hide,
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        _BookingCardContent(
          key: contentKey,
          targetKey: targetKey,
          bookingId: bookingId,
          userName: userName,
          unitName: unitName,
          checkIn: checkIn,
          checkOut: checkOut,
          guestsCount: guestsCount,
          totalAmount: totalAmount,
          currency: currency,
          status: status,
          bookedAt: bookedAt,
          propertyName: propertyName,
          unitImage: unitImage,
          userEmail: userEmail,
          userPhone: userPhone,
          notes: notes,
          specialRequests: specialRequests,
          paymentStatus: paymentStatus,
          bookingSource: bookingSource,
          isWalkIn: isWalkIn,
          confirmedAt: confirmedAt,
          checkedInAt: checkedInAt,
          checkedOutAt: checkedOutAt,
          cancelledAt: cancelledAt,
          cancellationReason: cancellationReason,
        ),
      ],
    );
  }
}

class _BookingCardContent extends StatefulWidget {
  final GlobalKey targetKey;
  final String bookingId;
  final String userName;
  final String unitName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestsCount;
  final double totalAmount;
  final String currency;
  final BookingStatus status;
  final DateTime bookedAt;
  final String? propertyName;
  final String? unitImage;
  final String? userEmail;
  final String? userPhone;
  final String? notes;
  final String? specialRequests;
  final String? paymentStatus;
  final String? bookingSource;
  final bool? isWalkIn;
  final DateTime? confirmedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const _BookingCardContent({
    super.key,
    required this.targetKey,
    required this.bookingId,
    required this.userName,
    required this.unitName,
    required this.checkIn,
    required this.checkOut,
    required this.guestsCount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.bookedAt,
    this.propertyName,
    this.unitImage,
    this.userEmail,
    this.userPhone,
    this.notes,
    this.specialRequests,
    this.paymentStatus,
    this.bookingSource,
    this.isWalkIn,
    this.confirmedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  @override
  State<_BookingCardContent> createState() => _BookingCardContentState();
}

class _BookingCardContentState extends State<_BookingCardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateOut(VoidCallback onComplete) {
    _controller.reverse().then((_) => onComplete());
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case BookingStatus.confirmed:
        return AppTheme.success;
      case BookingStatus.pending:
        return AppTheme.warning;
      case BookingStatus.cancelled:
        return AppTheme.error;
      case BookingStatus.completed:
        return AppTheme.primaryBlue;
      case BookingStatus.checkedIn:
        return AppTheme.primaryCyan;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case BookingStatus.confirmed:
        return CupertinoIcons.check_mark_circled_solid;
      case BookingStatus.pending:
        return CupertinoIcons.time_solid;
      case BookingStatus.cancelled:
        return CupertinoIcons.xmark_circle_fill;
      case BookingStatus.completed:
        return CupertinoIcons.checkmark_seal_fill;
      case BookingStatus.checkedIn:
        return CupertinoIcons.arrow_right_circle_fill;
    }
  }

  int get nights {
    return widget.checkOut.difference(widget.checkIn).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final statusColor = _getStatusColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Container(
                width: isMobile ? size.width * 0.9 : 400,
                constraints: BoxConstraints(maxHeight: size.height * 0.85),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: DefaultTextStyle(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(statusColor),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _buildBookingImage(statusColor),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      CupertinoIcons.person_fill,
                                      'اسم العميل',
                                      widget.userName,
                                      AppTheme.primaryPurple,
                                    ),
                                    const SizedBox(height: 12),
                                    if (widget.propertyName != null) ...[
                                      _buildInfoRow(
                                        CupertinoIcons.building_2_fill,
                                        'العقار',
                                        widget.propertyName!,
                                        AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    _buildInfoRow(
                                      CupertinoIcons.bed_double_fill,
                                      'الوحدة',
                                      widget.unitName,
                                      AppTheme.primaryCyan,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDateGrid(),
                                    const SizedBox(height: 16),
                                    _buildDetailsGrid(),
                                    if (widget.notes != null ||
                                        widget.specialRequests != null ||
                                        widget.cancellationReason != null) ...[
                                      const SizedBox(height: 16),
                                      _buildNotesSection(),
                                    ],
                                    const SizedBox(height: 16),
                                    _buildBookingId(),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.calendar_badge_plus,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'بطاقة الحجز',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: BookingIdentityCardTooltip.hide,
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textMuted,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingImage(Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Unit/Property Image
          if (widget.unitImage != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.3),
                      statusColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Image.network(
                  widget.unitImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultImage(statusColor),
                ),
              ),
            )
          else
            _buildDefaultImage(statusColor),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Booking Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: statusColor.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: statusColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.status.displayName,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isWalkIn == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.person_crop_circle_badge_checkmark,
                              color: AppTheme.warning,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Walk-in',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage(Color color) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.bed_double_fill,
          size: 60,
          color: color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 16,
                color: AppTheme.success,
              ),
              const SizedBox(width: 8),
              Text(
                'تواريخ الحجز',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateItem(
                  'تسجيل الوصول',
                  Formatters.formatDate(widget.checkIn),
                  CupertinoIcons.arrow_down_circle,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateItem(
                  'تسجيل المغادرة',
                  Formatters.formatDate(widget.checkOut),
                  CupertinoIcons.arrow_up_circle,
                  AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.moon_fill,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  '$nights ليلة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle_fill,
                size: 16,
                color: AppTheme.primaryCyan,
              ),
              const SizedBox(width: 8),
              Text(
                'تفاصيل الحجز',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  CupertinoIcons.person_2_fill,
                  widget.guestsCount.toString(),
                  'ضيف',
                  AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem(
                  CupertinoIcons.money_dollar_circle_fill,
                  Formatters.formatCurrency(widget.totalAmount, widget.currency),
                  'الإجمالي',
                  AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text_fill,
                size: 14,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'ملاحظات',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          if (widget.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.notes!,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textLight,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (widget.specialRequests != null) ...[
            const SizedBox(height: 8),
            Text(
              'طلبات خاصة: ${widget.specialRequests}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (widget.cancellationReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'سبب الإلغاء: ${widget.cancellationReason}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingId() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.number,
            size: 12,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'ID: ${widget.bookingId}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
