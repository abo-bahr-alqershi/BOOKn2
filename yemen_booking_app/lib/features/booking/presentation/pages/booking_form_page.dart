import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/date_picker_widget.dart';
import '../widgets/guest_selector_widget.dart';
import '../widgets/services_selector_widget.dart';

class BookingFormPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final String? unitId;
  final double? pricePerNight;

  const BookingFormPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    this.unitId,
    this.pricePerNight,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _specialRequestsController = TextEditingController();
  
  // Animation Controllers - Minimized
  late AnimationController _backgroundAnimationController;
  late AnimationController _formAnimationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Booking Data
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adultsCount = 1;
  int _childrenCount = 0;
  List<Map<String, dynamic>> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Slow Background Animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 50),
      vsync: this,
    )..repeat();
    
    // Form Animation
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOut,
    ));
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildMinimalAppBar(),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is AvailabilityChecked) {
            if (state.isAvailable) {
              _navigateToSummary();
            } else {
              _showUnavailableDialog();
            }
          } else if (state is BookingError) {
            _showMinimalSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is CheckingAvailability) {
            return Center(
              child: _buildMinimalLoader(),
            );
          }
          
          return Stack(
            children: [
              // Subtle animated background
              _buildSubtleBackground(),
              
              // Main Content
              SafeArea(
                child: _buildForm(),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildMinimalAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkCard.withOpacity(0.5),
      elevation: 0,
      toolbarHeight: 56,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: _buildMinimalBackButton(),
      title: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حجز ${widget.propertyName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.95),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'الخطوة 1 من 3',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          child: LinearProgressIndicator(
            value: 0.33,
            backgroundColor: AppTheme.darkBorder.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue.withOpacity(0.6),
            ),
          ),
        ),
      ),
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
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
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
            painter: _SubtlePatternPainter(
              rotation: _backgroundAnimationController.value * 2 * math.pi,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: AnimatedBuilder(
          animation: _formAnimationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('تواريخ الإقامة', 0),
                    const SizedBox(height: 10),
                    _buildCompactDateSelection(),
                    
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('عدد الضيوف', 1),
                    const SizedBox(height: 10),
                    _buildCompactGuestSelection(),
                    
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('الخدمات الإضافية', 2),
                    const SizedBox(height: 10),
                    _buildServicesSelection(),
                    
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('طلبات خاصة (اختياري)', 3),
                    const SizedBox(height: 10),
                    _buildCompactSpecialRequests(),
                    
                    const SizedBox(height: 20),
                    _buildCompactContinueButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactSectionTitle(String title, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * -20, 0),
          child: Opacity(
            opacity: value,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.2),
                        AppTheme.primaryPurple.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryBlue.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactDateSelection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              DatePickerWidget(
                label: 'تاريخ الوصول',
                selectedDate: _checkInDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _checkInDate = date;
                    if (_checkOutDate != null && _checkOutDate!.isBefore(date)) {
                      _checkOutDate = null;
                    }
                  });
                },
                icon: Icons.calendar_today_rounded,
              ),
              Container(
                height: 0.5,
                color: AppTheme.darkBorder.withOpacity(0.1),
              ),
              DatePickerWidget(
                label: 'تاريخ المغادرة',
                selectedDate: _checkOutDate,
                firstDate: _checkInDate?.add(const Duration(days: 1)) ?? 
                         DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _checkOutDate = date;
                  });
                },
                enabled: _checkInDate != null,
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGuestSelection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              GuestSelectorWidget(
                label: 'البالغين',
                count: _adultsCount,
                minCount: 1,
                maxCount: 10,
                onChanged: (count) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _adultsCount = count;
                  });
                },
              ),
              const SizedBox(height: 10),
              GuestSelectorWidget(
                label: 'الأطفال',
                subtitle: '(أقل من 12 سنة)',
                count: _childrenCount,
                minCount: 0,
                maxCount: 5,
                onChanged: (count) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _childrenCount = count;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSelection() {
    return ServicesSelectorWidget(
      propertyId: widget.propertyId,
      onServicesChanged: (services) {
        setState(() {
          _selectedServices = services;
        });
      },
    );
  }

  Widget _buildCompactSpecialRequests() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: _specialRequestsController,
            maxLines: 3,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textWhite.withOpacity(0.9),
            ),
            decoration: InputDecoration(
              hintText: 'أضف أي طلبات أو ملاحظات خاصة...',
              hintStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
                fontSize: 11,
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContinueButton() {
    final isValid = _checkInDate != null && _checkOutDate != null;
    
    return GestureDetector(
      onTapDown: isValid ? (_) => HapticFeedback.selectionClick() : null,
      onTap: isValid ? _onContinue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          gradient: isValid
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.9),
                    AppTheme.primaryPurple.withOpacity(0.7),
                  ],
                )
              : LinearGradient(
                  colors: [
                    AppTheme.darkBorder.withOpacity(0.3),
                    AppTheme.darkBorder.withOpacity(0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isValid ? _onContinue : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: isValid 
                            ? Colors.white 
                            : AppTheme.textMuted.withOpacity(0.5),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المتابعة إلى الملخص',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isValid 
                              ? Colors.white 
                              : AppTheme.textMuted.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildMinimalLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.darkCard.withOpacity(0.5),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جاري التحقق من التوفر...',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      
      if (context.read<AuthBloc>().state is AuthAuthenticated) {
        // Check availability first
        context.read<BookingBloc>().add(
          CheckAvailabilityEvent(
            unitId: widget.unitId ?? '',
            checkIn: _checkInDate!,
            checkOut: _checkOutDate!,
            guestsCount: _adultsCount + _childrenCount,
          ),
        );
      }
    }
  }

  void _navigateToSummary() {
    final formData = {
      'propertyId': widget.propertyId,
      'propertyName': widget.propertyName,
      'unitId': widget.unitId,
      'checkIn': _checkInDate,
      'checkOut': _checkOutDate,
      'adultsCount': _adultsCount,
      'childrenCount': _childrenCount,
      'selectedServices': _selectedServices,
      'specialRequests': _specialRequestsController.text,
      'pricePerNight': widget.pricePerNight,
    };

    context.push('/booking/summary', extra: formData);
  }

  void _showUnavailableDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildMinimalDialog(
        title: 'غير متاح',
        content: 'عذراً، الوحدة غير متاحة في التواريخ المحددة. يرجى اختيار تواريخ أخرى.',
        icon: Icons.event_busy_rounded,
        iconColor: AppTheme.error.withOpacity(0.8),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Text(
              'حسناً',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalDialog({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMinimalSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isError ? AppTheme.error : AppTheme.success)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isError 
                      ? AppTheme.error.withOpacity(0.8) 
                      : AppTheme.success.withOpacity(0.8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.darkCard.withOpacity(0.9),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Subtle Pattern Painter
class _SubtlePatternPainter extends CustomPainter {
  final double rotation;
  
  _SubtlePatternPainter({
    required this.rotation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw subtle rotating squares
    for (int i = 0; i < 2; i++) {
      paint.color = AppTheme.primaryBlue.withOpacity(0.02);
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation + (i * math.pi / 4));
      
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 150 + i * 100,
        height: 150 + i * 100,
      );
      
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}