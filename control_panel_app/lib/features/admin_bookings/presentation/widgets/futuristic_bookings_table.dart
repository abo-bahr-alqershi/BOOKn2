import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/booking.dart';
import 'booking_status_badge.dart';
import '../../../../core/widgets/booking_identity_card_tooltip.dart';

class FuturisticBookingsTable extends StatefulWidget {
  final List<Booking> bookings;
  final List<Booking> selectedBookings;
  final Function(String) onBookingTap;
  final Function(List<Booking>) onSelectionChanged;
  final bool showActions;
  final void Function(String bookingId)? onConfirm;
  final void Function(String bookingId)? onCancel;
  final void Function(String bookingId)? onCheckIn;
  final void Function(String bookingId)? onCheckOut;

  const FuturisticBookingsTable({
    super.key,
    required this.bookings,
    required this.selectedBookings,
    required this.onBookingTap,
    required this.onSelectionChanged,
    this.showActions = true,
    this.onConfirm,
    this.onCancel,
    this.onCheckIn,
    this.onCheckOut,
  });

  @override
  State<FuturisticBookingsTable> createState() =>
      _FuturisticBookingsTableState();
}

class _FuturisticBookingsTableState extends State<FuturisticBookingsTable> {
  bool _selectAll = false;
  int? _hoveredIndex;
  String? _pressedBookingId;
  String _sortColumn = 'date';
  bool _sortAscending = false;
  final Map<String, GlobalKey> _rowKeys = {};

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  _buildHeader(isCompact),
                  isCompact
                      ? _buildCompactView()
                      : _buildTableView(constraints),
                ],
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
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'قائمة الحجوزات',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: isCompact ? 16 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.bookings.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 10 : 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isCompact) _buildSortDropdown(isCompact),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.sort_down,
            size: isCompact ? 14 : 16,
            color: AppTheme.textMuted,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            'ترتيب',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
          SizedBox(width: isCompact ? 4 : 8),
          DropdownButton<String>(
            value: _sortColumn,
            dropdownColor: AppTheme.darkCard,
            underline: const SizedBox.shrink(),
            icon: Icon(
              CupertinoIcons.chevron_down,
              size: isCompact ? 12 : 14,
              color: AppTheme.primaryBlue,
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryBlue,
              fontSize: isCompact ? 11 : 12,
            ),
            items: const [
              DropdownMenuItem(value: 'date', child: Text('التاريخ')),
              DropdownMenuItem(value: 'status', child: Text('الحالة')),
              DropdownMenuItem(value: 'price', child: Text('السعر')),
              DropdownMenuItem(value: 'name', child: Text('الاسم')),
            ],
            onChanged: (value) {
              setState(() {
                _sortColumn = value!;
                _sortBookings();
              });
            },
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _sortBookings();
              });
            },
            icon: Icon(
              _sortAscending
                  ? CupertinoIcons.arrow_up
                  : CupertinoIcons.arrow_down,
              size: isCompact ? 14 : 16,
              color: AppTheme.primaryBlue,
            ),
            padding: EdgeInsets.all(isCompact ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isCompact ? 24 : 32,
              minHeight: isCompact ? 24 : 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.bookings.length,
      itemBuilder: (context, index) {
        final booking = widget.bookings[index];
        final isSelected = widget.selectedBookings.contains(booking);

        return GestureDetector(
          key: _getRowKey(booking.id),
          onTap: () => widget.onBookingTap(booking.id),
          onLongPress: () => _showBookingCard(booking),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                  : AppTheme.darkCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pressedBookingId == booking.id
                    ? AppTheme.primaryBlue.withValues(alpha: 0.6)
                    : isSelected
                        ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                        : AppTheme.darkBorder.withValues(alpha: 0.2),
                width: _pressedBookingId == booking.id ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        final updatedSelection = [...widget.selectedBookings];
                        if (value!) {
                          updatedSelection.add(booking);
                        } else {
                          updatedSelection.remove(booking);
                        }
                        widget.onSelectionChanged(updatedSelection);
                      },
                      activeColor: AppTheme.primaryBlue,
                      checkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '#${booking.id.substring(0, 8)}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              BookingStatusBadge(
                                status: booking.status,
                                size: BadgeSize.small,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.userName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.bed_double,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.unitName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                        '${Formatters.formatDate(booking.checkIn)} - ${Formatters.formatDate(booking.checkOut)}',
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.totalPrice.formattedAmount,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.showActions) _buildCompactActions(booking),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(BoxConstraints constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
        child: Column(
          children: [
            _buildTableHeader(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.bookings.length,
              itemBuilder: (context, index) {
                return _buildTableRow(index, widget.bookings[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: _selectAll,
              onChanged: (value) {
                setState(() {
                  _selectAll = value!;
                  if (_selectAll) {
                    widget.onSelectionChanged(widget.bookings);
                  } else {
                    widget.onSelectionChanged([]);
                  }
                });
              },
              activeColor: AppTheme.primaryBlue,
              checkColor: Colors.white,
            ),
          ),
          _buildHeaderCell('رقم الحجز', 120),
          _buildHeaderCell('الضيف', 150),
          _buildHeaderCell('الوحدة', 150),
          _buildHeaderCell('تاريخ الوصول', 120),
          _buildHeaderCell('تاريخ المغادرة', 120),
          _buildHeaderCell('الحالة', 100),
          _buildHeaderCell('السعر', 120),
          _buildHeaderCell('طريقة الدفع', 120),
          if (widget.showActions) _buildHeaderCell('الإجراءات', 150),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableRow(int index, Booking booking) {
    final isSelected = widget.selectedBookings.contains(booking);
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        key: _getRowKey(booking.id),
        onTap: () => widget.onBookingTap(booking.id),
        onLongPress: () => _showBookingCard(booking),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                : isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.02)
                    : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withValues(alpha: 0.05),
              ),
              left: BorderSide(
                color: _pressedBookingId == booking.id
                    ? AppTheme.primaryBlue.withValues(alpha: 0.8)
                    : isSelected
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    final updatedSelection = [...widget.selectedBookings];
                    if (value!) {
                      updatedSelection.add(booking);
                    } else {
                      updatedSelection.remove(booking);
                    }
                    widget.onSelectionChanged(updatedSelection);
                  },
                  activeColor: AppTheme.primaryBlue,
                  checkColor: Colors.white,
                ),
              ),
              _buildCell(
                '#${booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id}',
                120,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildCell(booking.userName, 150),
              _buildCell(booking.unitName, 150),
              _buildCell(Formatters.formatDate(booking.checkIn), 120),
              _buildCell(Formatters.formatDate(booking.checkOut), 120),
              SizedBox(
                width: 100,
                child: BookingStatusBadge(
                  status: booking.status,
                  size: BadgeSize.small,
                ),
              ),
              _buildCell(
                booking.totalPrice.formattedAmount,
                120,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildCell(booking.paymentStatus ?? 'نقداً', 120),
              if (widget.showActions)
                SizedBox(
                  width: 150,
                  child: _buildActions(booking),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: style ??
            AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActions(Booking booking) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildActionIcon(
          icon: CupertinoIcons.eye,
          onTap: () => widget.onBookingTap(booking.id),
          tooltip: 'عرض',
        ),
        if (booking.canCheckIn)
          _buildActionIcon(
            icon: CupertinoIcons.arrow_down_circle,
            onTap: () => widget.onCheckIn?.call(booking.id),
            tooltip: 'تسجيل وصول',
            color: AppTheme.success,
          ),
        if (booking.canCheckOut)
          _buildActionIcon(
            icon: CupertinoIcons.arrow_up_circle,
            onTap: () => widget.onCheckOut?.call(booking.id),
            tooltip: 'تسجيل مغادرة',
            color: AppTheme.warning,
          ),
        if (booking.canCancel)
          _buildActionIcon(
            icon: CupertinoIcons.xmark_circle,
            onTap: () => widget.onCancel?.call(booking.id),
            tooltip: 'إلغاء',
            color: AppTheme.error,
          ),
        _buildActionIcon(
          icon: CupertinoIcons.ellipsis,
          onTap: () => _showActionsMenu(booking),
          tooltip: 'المزيد',
        ),
        _buildActionIcon(
          icon: CupertinoIcons.doc_text,
          onTap: () => context.push('/admin/financial/transactions', extra: {
            'bookingId': booking.id,
          }),
          tooltip: 'القيود',
        ),
      ],
    );
  }

  Widget _buildCompactActions(Booking booking) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.canCheckIn)
          _buildActionIcon(
            icon: CupertinoIcons.arrow_down_circle,
            onTap: () => widget.onCheckIn?.call(booking.id),
            tooltip: 'تسجيل وصول',
            color: AppTheme.success,
            size: 14,
          ),
        if (booking.canCheckOut)
          _buildActionIcon(
            icon: CupertinoIcons.arrow_up_circle,
            onTap: () => widget.onCheckOut?.call(booking.id),
            tooltip: 'تسجيل مغادرة',
            color: AppTheme.warning,
            size: 14,
          ),
        _buildActionIcon(
          icon: CupertinoIcons.ellipsis,
          onTap: () => _showActionsMenu(booking),
          tooltip: 'المزيد',
          size: 14,
        ),
        _buildActionIcon(
          icon: CupertinoIcons.doc_text,
          onTap: () => context.push('/admin/financial/transactions', extra: {
            'bookingId': booking.id,
          }),
          tooltip: 'القيود',
          size: 14,
        ),
      ],
    );
  }

  void _showActionsMenu(Booking booking) {
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
              _buildSheetAction(
                icon: CupertinoIcons.eye,
                label: 'عرض التفاصيل',
                onTap: () {
                  Navigator.pop(context);
                  widget.onBookingTap(booking.id);
                },
              ),
              if (booking.canCheckIn)
                _buildSheetAction(
                  icon: CupertinoIcons.arrow_down_circle,
                  label: 'تسجيل وصول',
                  color: AppTheme.success,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onCheckIn?.call(booking.id);
                  },
                ),
              if (booking.canCheckOut)
                _buildSheetAction(
                  icon: CupertinoIcons.arrow_up_circle,
                  label: 'تسجيل مغادرة',
                  color: AppTheme.warning,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onCheckOut?.call(booking.id);
                  },
                ),
              if (booking.canConfirm)
                _buildSheetAction(
                  icon: CupertinoIcons.checkmark_circle,
                  label: 'تأكيد الحجز',
                  color: AppTheme.success,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onConfirm?.call(booking.id);
                  },
                ),
              if (booking.canCancel)
                _buildSheetAction(
                  icon: CupertinoIcons.xmark_circle,
                  label: 'إلغاء الحجز',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onCancel?.call(booking.id);
                  },
                ),
              _buildSheetAction(
                icon: CupertinoIcons.doc_text,
                label: 'عرض القيود المحاسبية',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/financial/transactions', extra: {
                    'bookingId': booking.id,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textWhite),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
    double size = 16,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(size == 14 ? 4 : 6),
              child: Icon(
                icon,
                size: size,
                color: color ?? AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sortBookings() {
    widget.bookings.sort((a, b) {
      int result;
      switch (_sortColumn) {
        case 'date':
          result = a.bookedAt.compareTo(b.bookedAt);
          break;
        case 'status':
          result = a.status.toString().compareTo(b.status.toString());
          break;
        case 'price':
          result = a.totalPrice.amount.compareTo(b.totalPrice.amount);
          break;
        case 'name':
          result = a.userName.compareTo(b.userName);
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
  }

  GlobalKey _getRowKey(String bookingId) {
    if (!_rowKeys.containsKey(bookingId)) {
      _rowKeys[bookingId] = GlobalKey();
    }
    return _rowKeys[bookingId]!;
  }

  void _showBookingCard(Booking booking) {
    setState(() => _pressedBookingId = booking.id);
    
    HapticFeedback.mediumImpact();
    
    BookingIdentityCardTooltip.show(
      context: context,
      targetKey: _getRowKey(booking.id),
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
      if (mounted) setState(() => _pressedBookingId = null);
    });
  }
}
