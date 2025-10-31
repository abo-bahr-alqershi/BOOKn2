// lib/features/admin_bookings/presentation/widgets/booking_timeline_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/booking.dart';
import 'booking_status_badge.dart';

class BookingTimelineWidget extends StatelessWidget {
  final String timeSlot;
  final List<Booking> bookings;
  final bool isFirst;
  final bool isLast;
  final Function(String) onBookingTap;

  const BookingTimelineWidget({
    super.key,
    required this.timeSlot,
    required this.bookings,
    required this.isFirst,
    required this.isLast,
    required this.onBookingTap,
  });

  @override
  Widget build(BuildContext context) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.manual,
      lineXY: 0.15,
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: _buildTimeIndicator(),
        drawGap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      beforeLineStyle: LineStyle(
        color: AppTheme.primaryBlue.withOpacity(0.2),
        thickness: 2,
      ),
      afterLineStyle: LineStyle(
        color: AppTheme.primaryBlue.withOpacity(0.2),
        thickness: 2,
      ),
      startChild: _buildTimeLabel(),
      endChild: _buildBookingsList(context),
    );
  }

  Widget _buildTimeIndicator() {
    final isNow = _isCurrentTime();

    return Container(
      decoration: BoxDecoration(
        gradient: isNow ? AppTheme.primaryGradient : null,
        color: isNow ? null : AppTheme.darkCard,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isNow ? Colors.transparent : AppTheme.darkBorder.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: isNow
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          _getTimeIcon(),
          size: 20,
          color: isNow ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildTimeLabel() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timeSlot,
              style: AppTextStyles.heading3.copyWith(
                color: _isCurrentTime()
                    ? AppTheme.primaryBlue
                    : AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${bookings.length} حجز',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: bookings.map((booking) {
          return _buildBookingCard(context, booking);
        }).toList(),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final isCheckIn = booking.checkIn.hour == int.parse(timeSlot.split(':')[0]);
    final isCheckOut =
        booking.checkOut.hour == int.parse(timeSlot.split(':')[0]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCheckIn
                    ? AppTheme.success.withOpacity(0.3)
                    : isCheckOut
                        ? AppTheme.error.withOpacity(0.3)
                        : AppTheme.darkBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onBookingTap(booking.id),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildEventTypeIcon(isCheckIn, isCheckOut),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.unitName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.userName,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: BookingStatusBadge(
                              status: booking.status,
                              size: BadgeSize.small,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBookingDetails(
                          context, booking, isCheckIn, isCheckOut),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeIcon(bool isCheckIn, bool isCheckOut) {
    IconData icon;
    Color color;

    if (isCheckIn) {
      icon = CupertinoIcons.arrow_down_circle_fill;
      color = AppTheme.success;
    } else if (isCheckOut) {
      icon = CupertinoIcons.arrow_up_circle_fill;
      color = AppTheme.error;
    } else {
      icon = CupertinoIcons.house_fill;
      color = AppTheme.primaryBlue;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildBookingDetails(
      BuildContext context, Booking booking, bool isCheckIn, bool isCheckOut) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isSmallScreen
          ? _buildCompactLayout(booking, isCheckIn, isCheckOut)
          : _buildNormalLayout(booking, isCheckIn, isCheckOut),
    );
  }

  Widget _buildNormalLayout(Booking booking, bool isCheckIn, bool isCheckOut) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      children: [
        _buildDetailItem(
          icon: CupertinoIcons.calendar,
          label: isCheckIn
              ? 'وصول'
              : isCheckOut
                  ? 'مغادرة'
                  : 'إقامة',
          value: isCheckIn
              ? Formatters.formatDate(booking.checkIn)
              : isCheckOut
                  ? Formatters.formatDate(booking.checkOut)
                  : '${booking.nights} ليلة',
        ),
        _buildDetailItem(
          icon: CupertinoIcons.person_2,
          label: 'الضيوف',
          value: '${booking.guestsCount}',
        ),
        _buildPriceTag(booking.totalPrice.formattedAmount),
      ],
    );
  }

  Widget _buildCompactLayout(Booking booking, bool isCheckIn, bool isCheckOut) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                icon: CupertinoIcons.calendar,
                label: isCheckIn
                    ? 'وصول'
                    : isCheckOut
                        ? 'مغادرة'
                        : 'إقامة',
                value: isCheckIn
                    ? Formatters.formatDate(booking.checkIn)
                    : isCheckOut
                        ? Formatters.formatDate(booking.checkOut)
                        : '${booking.nights} ليلة',
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDetailItem(
              icon: CupertinoIcons.person_2,
              label: 'الضيوف',
              value: '${booking.guestsCount}',
              compact: true,
            ),
            _buildPriceTag(booking.totalPrice.formattedAmount, compact: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceTag(String price, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        price,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: compact ? 11 : null,
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool compact = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: compact ? 12 : 14,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontSize: compact ? 9 : 10,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  bool _isCurrentTime() {
    final now = DateTime.now();
    final currentHour = '${now.hour.toString().padLeft(2, '0')}:00';
    return currentHour == timeSlot;
  }

  IconData _getTimeIcon() {
    final hour = int.parse(timeSlot.split(':')[0]);

    if (hour >= 6 && hour < 12) {
      return CupertinoIcons.sun_max_fill;
    } else if (hour >= 12 && hour < 18) {
      return CupertinoIcons.sun_min_fill;
    } else if (hour >= 18 && hour < 22) {
      return CupertinoIcons.sunset_fill;
    } else {
      return CupertinoIcons.moon_stars_fill;
    }
  }
}
