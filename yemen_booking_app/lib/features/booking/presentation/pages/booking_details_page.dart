import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/price_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/enums/booking_status.dart';
import '../../domain/entities/payment.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/booking_status_widget.dart';
import '../widgets/cancellation_deadline_has_expired_widget.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage>
    with TickerProviderStateMixin {
  // Animation Controllers - Reduced and optimized
  late AnimationController _backgroundAnimationController;
  late AnimationController _qrAnimationController;
  late AnimationController _fadeController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _qrScaleAnimation;

  // State
  bool _showQRCode = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadBookingDetails();
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    // Slow background animation for subtlety
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    )..repeat();

    // QR Animation
    _qrAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _qrScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _qrAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _loadBookingDetails() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
            GetBookingDetailsEvent(
              bookingId: widget.bookingId,
              userId: authState.user.userId,
            ),
          );
    }
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _qrAnimationController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _refreshUserBookings();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Subtle animated background
            _buildSubtleBackground(),

            // Main Content
            BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                if (state is BookingLoading) {
                  return Center(
                    child: _buildMinimalLoader(),
                  );
                }

                if (state is BookingError) {
                  return Center(
                    child: _buildMinimalError(state),
                  );
                }

                if (state is BookingDetailsLoaded) {
                  return _buildContent(state.booking);
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshUserBookings() async {
    context.read<BookingBloc>().add(const ResetBookingStateEvent());
  }

  Widget _buildSubtleBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _SubtleDetailPatternPainter(
              animationValue: _backgroundAnimationController.value,
              scrollOffset: _scrollOffset,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildContent(dynamic booking) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildMinimalAppBar(booking),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildCompactStatusCard(booking),
                        const SizedBox(height: 12),
                        _buildCompactQRCodeSection(booking),
                        const SizedBox(height: 12),
                        _buildCompactPropertyCard(booking),
                        const SizedBox(height: 12),
                        _buildCompactBookingInfo(booking),
                        const SizedBox(height: 12),
                        _buildCompactGuestInfo(booking),
                        if (booking.services.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildCompactServicesCard(booking),
                        ],
                        const SizedBox(height: 12),
                        _buildCompactPaymentInfo(booking),
                        if (booking.canCancel) ...[
                          const SizedBox(height: 12),
                          _buildCancellationPolicy(booking),
                        ],
                        const SizedBox(height: 12),
                        _buildCompactActions(booking),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalAppBar(dynamic booking) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getStatusColor(booking.status).withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(booking.status).withOpacity(0.8),
                            _getStatusColor(booking.status).withOpacity(0.6),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(booking.status)
                                .withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getStatusIcon(booking.status),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تفاصيل الحجز',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      leading: _buildMinimalBackButton(),
      actions: [
        _buildMinimalActionButton(
          icon: Icons.share_rounded,
          onPressed: _shareBooking,
        ),
      ],
    );
  }

  Widget _buildMinimalBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: AppTheme.textWhite.withOpacity(0.9),
              onPressed: () {
                HapticFeedback.selectionClick();
                _refreshUserBookings();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, size: 16),
              color: AppTheme.textWhite.withOpacity(0.9),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusCard(dynamic booking) {
    return Container(
      decoration: BoxDecoration(
        color: _getStatusColor(booking.status).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _getStatusColor(booking.status).withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(booking.status),
                    color: _getStatusColor(booking.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookingStatusWidget(
                        status: booking.status,
                        showIcon: false,
                        animated: false,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم الحجز: ${booking.bookingNumber}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        'تاريخ الحجز: ${DateFormat('dd/MM/yyyy').format(booking.bookingDate)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactQRCodeSection(dynamic booking) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _showQRCode = !_showQRCode;
              if (_showQRCode) {
                _qrAnimationController.forward();
              } else {
                _qrAnimationController.reverse();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.8),
                  AppTheme.primaryPurple.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showQRCode
                      ? Icons.qr_code_2_rounded
                      : Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _showQRCode ? 'إخفاء رمز QR' : 'عرض رمز QR',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showQRCode)
          AnimatedBuilder(
            animation: _qrScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _qrScaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QrImageView(
                          data: booking.bookingNumber,
                          version: QrVersions.auto,
                          size: 120.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'اعرض هذا الكود عند تسجيل الوصول',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCompactPropertyCard(dynamic booking) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.2),
                            AppTheme.primaryPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: AppTheme.primaryBlue.withOpacity(0.9),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تفاصيل العقار',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (booking.unitImages.isNotEmpty)
                  _buildCompactPropertyImage(booking),
                const SizedBox(height: 10),
                Text(
                  booking.propertyName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.95),
                  ),
                ),
                if (booking.unitName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    booking.unitName!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppTheme.primaryCyan.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.propertyAddress ?? 'العنوان غير متوفر',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.7),
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPropertyImage(dynamic booking) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            if (booking.unitImages.isNotEmpty)
              Image.network(
                booking.unitImages.first,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder(),
              )
            else
              _buildImagePlaceholder(),

            // Subtle gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.primaryBlue.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          color: AppTheme.primaryBlue.withOpacity(0.3),
          size: 36,
        ),
      ),
    );
  }

  Widget _buildCompactBookingInfo(dynamic booking) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    return _buildCompactCard(
      title: 'معلومات الإقامة',
      icon: Icons.calendar_today_rounded,
      iconColor: AppTheme.primaryBlue.withOpacity(0.8),
      children: [
        _buildCompactInfoRow(
          icon: Icons.calendar_today_rounded,
          label: 'تاريخ الوصول',
          value: dateFormat.format(booking.checkInDate),
          iconColor: AppTheme.primaryBlue.withOpacity(0.8),
        ),
        _buildSubtleDivider(),
        _buildCompactInfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'تاريخ المغادرة',
          value: dateFormat.format(booking.checkOutDate),
          iconColor: AppTheme.primaryPurple.withOpacity(0.8),
        ),
        _buildSubtleDivider(),
        _buildCompactInfoRow(
          icon: Icons.nights_stay_rounded,
          label: 'عدد الليالي',
          value:
              '${booking.numberOfNights} ${booking.numberOfNights == 1 ? 'ليلة' : 'ليالي'}',
          iconColor: AppTheme.primaryCyan.withOpacity(0.8),
        ),
      ],
    );
  }

  Widget _buildCompactGuestInfo(dynamic booking) {
    return _buildCompactCard(
      title: 'معلومات الضيوف',
      icon: Icons.people_outline_rounded,
      iconColor: AppTheme.neonGreen.withOpacity(0.8),
      children: [
        _buildCompactInfoRow(
          icon: Icons.person_outline_rounded,
          label: 'اسم الضيف',
          value: booking.userName,
          iconColor: AppTheme.neonGreen.withOpacity(0.8),
        ),
        _buildSubtleDivider(),
        _buildCompactInfoRow(
          icon: Icons.people_outline_rounded,
          label: 'عدد الضيوف',
          value:
              '${booking.totalGuests} ضيف (${booking.adultGuests} بالغ${booking.childGuests > 0 ? '، ${booking.childGuests} طفل' : ''})',
          iconColor: AppTheme.neonGreen.withOpacity(0.8),
        ),
        if (booking.specialRequests != null) ...[
          _buildSubtleDivider(),
          _buildCompactInfoRow(
            icon: Icons.note_rounded,
            label: 'طلبات خاصة',
            value: booking.specialRequests!,
            iconColor: AppTheme.warning.withOpacity(0.8),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactServicesCard(dynamic booking) {
    return _buildCompactCard(
      title: 'الخدمات الإضافية',
      icon: Icons.room_service_rounded,
      iconColor: AppTheme.primaryViolet.withOpacity(0.8),
      children: booking.services
          .map<Widget>((service) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${service.serviceName} x${service.quantity}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textWhite.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    PriceWidget(
                      price: service.totalPrice,
                      currency: service.currency,
                      displayType: PriceDisplayType.compact,
                      priceStyle: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryViolet.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCompactPaymentInfo(dynamic booking) {
    // Calculate paid and remaining
    final double total = (booking.totalAmount ?? 0).toDouble();
    final String currency = booking.currency ?? 'YER';
    double paid = 0.0;
    if (booking.payments != null && booking.payments is List && booking.payments.isNotEmpty) {
      for (final p in booking.payments) {
        try {
          if (p.status == PaymentStatus.completed) {
            paid += (p.amount ?? 0).toDouble();
          }
        } catch (_) {
          // ignore malformed payment entries
        }
      }
    }
    final double remaining = (total - paid) > 0 ? (total - paid) : 0.0;

    return _buildCompactCard(
      title: 'معلومات الدفع',
      icon: Icons.payment_rounded,
      iconColor: AppTheme.success.withOpacity(0.8),
      gradient: LinearGradient(
        colors: [
          AppTheme.success.withOpacity(0.05),
          AppTheme.success.withOpacity(0.02),
        ],
      ),
      borderColor: AppTheme.success.withOpacity(0.2),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المبلغ الإجمالي',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.8),
              ),
            ),
            PriceWidget(
              price: total,
              currency: currency,
              displayType: PriceDisplayType.compact,
              priceStyle: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.success.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المدفوع',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.8),
              ),
            ),
            PriceWidget(
              price: paid,
              currency: currency,
              displayType: PriceDisplayType.compact,
              priceStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.info.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المتبقي',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.8),
              ),
            ),
            PriceWidget(
              price: remaining,
              currency: currency,
              displayType: PriceDisplayType.compact,
              priceStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.warning.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancellationPolicy(dynamic booking) {
    final now = DateTime.now();
    final cancellationDeadline =
        booking.checkInDate.subtract(const Duration(hours: 24));
    final canCancelFree = now.isBefore(cancellationDeadline);

    return CancellationDeadlineHasExpiredWidget(
      hasExpired: !canCancelFree,
      deadline: cancellationDeadline,
    );
  }

  Widget _buildCompactActions(dynamic booking) {
    return Column(
      children: [
        if (booking.canModify)
          _buildCompactActionButton(
            icon: Icons.edit_rounded,
            label: 'تعديل الحجز',
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple.withOpacity(0.8),
                AppTheme.primaryViolet.withOpacity(0.6),
              ],
            ),
            onPressed: () => _modifyBooking(booking),
          ),
        if (booking.canCancel) ...[
          const SizedBox(height: 8),
          _buildCompactActionButton(
            icon: Icons.cancel_rounded,
            label: 'إلغاء الحجز',
            gradient: LinearGradient(
              colors: [
                AppTheme.error.withOpacity(0.8),
                AppTheme.error.withOpacity(0.6),
              ],
            ),
            onPressed: () => _cancelBooking(booking),
          ),
        ],
        if (booking.status == BookingStatus.completed && booking.canReview) ...[
          const SizedBox(height: 8),
          _buildCompactActionButton(
            icon: Icons.rate_review_rounded,
            label: 'كتابة تقييم',
            gradient: LinearGradient(
              colors: [
                AppTheme.warning.withOpacity(0.8),
                AppTheme.warning.withOpacity(0.6),
              ],
            ),
            onPressed: () => _writeReview(booking),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    LinearGradient? gradient,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.3),
                AppTheme.darkCard.withOpacity(0.2),
              ],
            ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (borderColor ?? iconColor).withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 12,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.darkBorder.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 42,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildMinimalLoader() {
    return const LoadingWidget(
      type: LoadingType.futuristic,
      message: 'جاري تحميل التفاصيل...',
    );
  }

  Widget _buildMinimalError(BookingError state) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 24,
              color: AppTheme.error.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.error.withOpacity(0.7),
                  AppTheme.error.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadBookingDetails,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'إعادة المحاولة',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppTheme.success.withOpacity(0.8);
      case BookingStatus.pending:
        return AppTheme.warning.withOpacity(0.8);
      case BookingStatus.cancelled:
        return AppTheme.error.withOpacity(0.8);
      case BookingStatus.completed:
        return AppTheme.info.withOpacity(0.8);
      case BookingStatus.checkedIn:
        return AppTheme.primaryBlue.withOpacity(0.8);
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.pending:
        return Icons.hourglass_empty_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.completed:
        return Icons.done_all_rounded;
      case BookingStatus.checkedIn:
        return Icons.login_rounded;
    }
  }

  void _shareBooking() {
    HapticFeedback.selectionClick();
    // Implementation
  }

  void _modifyBooking(dynamic booking) {
    HapticFeedback.selectionClick();
    // Navigate to modify booking
  }

  void _cancelBooking(dynamic booking) {
    HapticFeedback.mediumImpact();
    // Show cancel dialog
  }

  void _writeReview(dynamic booking) {
    HapticFeedback.selectionClick();
    context.push('/review/write', extra: {
      'bookingId': booking.id,
      'propertyId': booking.propertyId,
      'propertyName': booking.propertyName,
    });
  }
}

// Subtle Detail Pattern Painter
class _SubtleDetailPatternPainter extends CustomPainter {
  final double animationValue;
  final double scrollOffset;

  _SubtleDetailPatternPainter({
    required this.animationValue,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    // Draw subtle grid
    const spacing = 40.0;
    final offset = scrollOffset * 0.02 % spacing;

    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      paint.color = AppTheme.primaryBlue.withOpacity(0.02);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = -spacing + offset;
        y < size.height + spacing;
        y += spacing) {
      paint.color = AppTheme.primaryPurple.withOpacity(0.02);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
