// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'dart:ui';
// import 'dart:math' as math;
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_dimensions.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../domain/entities/booking.dart';

// class BookingConfirmationPage extends StatefulWidget {
//   final Booking booking;

//   const BookingConfirmationPage({
//     super.key,
//     required this.booking,
//   });

//   @override
//   State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
// }

// class _BookingConfirmationPageState extends State<BookingConfirmationPage>
//     with TickerProviderStateMixin {
//   // Animation Controllers
//   late AnimationController _successAnimationController;
//   late AnimationController _cardAnimationController;
//   late AnimationController _confettiAnimationController;
//   late AnimationController _pulseAnimationController;
//   late AnimationController _shimmerAnimationController;
  
//   // Animations
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _rotationAnimation;
//   late Animation<double> _checkAnimation;
  
//   // Confetti Particles
//   final List<_ConfettiParticle> _confettiParticles = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _generateConfetti();
//     _startAnimations();
//   }

//   void _initializeAnimations() {
//     // Success Animation
//     _successAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
    
//     _scaleAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _successAnimationController,
//       curve: Curves.elasticOut,
//     ));
    
//     _checkAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _successAnimationController,
//       curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
//     ));
    
//     // Card Animation
//     _cardAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _cardAnimationController,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//     ));
    
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.5),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _cardAnimationController,
//       curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
//     ));
    
//     // Confetti Animation
//     _confettiAnimationController = AnimationController(
//       duration: const Duration(seconds: 5),
//       vsync: this,
//     );
    
//     _rotationAnimation = Tween<double>(
//       begin: 0,
//       end: 2 * math.pi,
//     ).animate(_confettiAnimationController);
    
//     // Pulse Animation
//     _pulseAnimationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     // Shimmer Animation
//     _shimmerAnimationController = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     )..repeat();
//   }
  
//   void _generateConfetti() {
//     for (int i = 0; i < 50; i++) {
//       _confettiParticles.add(_ConfettiParticle());
//     }
//   }
  
//   void _startAnimations() async {
//     await Future.delayed(const Duration(milliseconds: 100));
//     _successAnimationController.forward();
//     await Future.delayed(const Duration(milliseconds: 300));
//     _cardAnimationController.forward();
//     _confettiAnimationController.forward();
    
//     // Haptic feedback for success
//     HapticFeedback.heavyImpact();
//   }

//   @override
//   void dispose() {
//     _successAnimationController.dispose();
//     _cardAnimationController.dispose();
//     _confettiAnimationController.dispose();
//     _pulseAnimationController.dispose();
//     _shimmerAnimationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: true,
//       onPopInvokedWithResult: (didPop, result) {
//         if (!didPop) {
//           context.go('/home');
//         }
//       },
//       child: Scaffold(
//         backgroundColor: AppTheme.darkBackground,
//         body: Stack(
//           children: [
//             // Animated Background
//             _buildAnimatedBackground(),
            
//             // Confetti Animation
//             AnimatedBuilder(
//               animation: _confettiAnimationController,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _ConfettiPainter(
//                     particles: _confettiParticles,
//                     animationValue: _confettiAnimationController.value,
//                   ),
//                   size: Size.infinite,
//                 );
//               },
//             ),
            
//             // Main Content
//             SafeArea(
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: AppDimensions.spacingXl),
//                     _buildSuccessAnimation(),
//                     const SizedBox(height: AppDimensions.spacingLg),
//                     _buildSuccessMessage(),
//                     const SizedBox(height: AppDimensions.spacingXl),
//                     AnimatedBuilder(
//                       animation: _cardAnimationController,
//                       builder: (context, child) {
//                         return FadeTransition(
//                           opacity: _fadeAnimation,
//                           child: SlideTransition(
//                             position: _slideAnimation,
//                             child: Column(
//                               children: [
//                                 _buildFuturisticBookingDetails(),
//                                 const SizedBox(height: AppDimensions.spacingLg),
//                                 _buildActionButtons(),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(height: AppDimensions.spacingXl),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimatedBackground() {
//     return AnimatedBuilder(
//       animation: _pulseAnimationController,
//       builder: (context, child) {
//         return Container(
//           decoration: BoxDecoration(
//             gradient: RadialGradient(
//               center: const Alignment(0, -0.5),
//               radius: 1.5,
//               colors: [
//                 AppTheme.success.withOpacity(0.1 + (_pulseAnimationController.value * 0.05)),
//                 AppTheme.darkBackground,
//               ],
//             ),
//           ),
//           child: CustomPaint(
//             painter: _CelebrationPatternPainter(
//               animationValue: _shimmerAnimationController.value,
//             ),
//             size: Size.infinite,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSuccessAnimation() {
//     return AnimatedBuilder(
//       animation: _successAnimationController,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Container(
//             width: 150,
//             height: 150,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [
//                   AppTheme.success,
//                   AppTheme.success.withOpacity(0.7),
//                 ],
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppTheme.success.withOpacity(0.5),
//                   blurRadius: 30,
//                   spreadRadius: 10,
//                 ),
//                 BoxShadow(
//                   color: AppTheme.neonGreen.withOpacity(0.3),
//                   blurRadius: 50,
//                   spreadRadius: 20,
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(75),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                 child: Container(
//                   color: Colors.transparent,
//                   child: Center(
//                     child: AnimatedBuilder(
//                       animation: _checkAnimation,
//                       builder: (context, child) {
//                         return CustomPaint(
//                           size: const Size(80, 80),
//                           painter: _CheckmarkPainter(
//                             progress: _checkAnimation.value,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSuccessMessage() {
//     return AnimatedBuilder(
//       animation: _fadeAnimation,
//       builder: (context, child) {
//         return FadeTransition(
//           opacity: _fadeAnimation,
//           child: Column(
//             children: [
//               ShaderMask(
//                 shaderCallback: (bounds) =>
//                     AppTheme.primaryGradient.createShader(bounds),
//                 child: Text(
//                   'تم الحجز بنجاح!',
//                   style: AppTextStyles.displaySmall.copyWith(
//                     fontWeight: FontWeight.w900,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: AppDimensions.spacingSm),
//               Text(
//                 'تم تأكيد حجزك وسيتم إرسال التفاصيل إلى بريدك الإلكتروني',
//                 style: AppTextStyles.bodyMedium.copyWith(
//                   color: AppTheme.textMuted,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildFuturisticBookingDetails() {
//     final dateFormat = DateFormat('dd MMM yyyy', 'ar');
    
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.darkCard.withOpacity(0.9),
//             AppTheme.darkCard.withOpacity(0.6),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//           color: AppTheme.success.withOpacity(0.3),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: AppTheme.success.withOpacity(0.2),
//             blurRadius: 30,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: Column(
//             children: [
//               _buildDetailHeader(),
//               Container(
//                 height: 1,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.transparent,
//                       AppTheme.success.withOpacity(0.3),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//                 child: Column(
//                   children: [
//                     _buildAnimatedDetailItem(
//                       'رقم الحجز',
//                       widget.booking.bookingNumber,
//                       canCopy: true,
//                       delay: 0,
//                     ),
//                     _buildGradientDivider(),
//                     _buildAnimatedDetailItem(
//                       'اسم العقار',
//                       widget.booking.propertyName,
//                       delay: 100,
//                     ),
//                     if (widget.booking.unitName != null) ...[
//                       _buildGradientDivider(),
//                       _buildAnimatedDetailItem(
//                         'الوحدة',
//                         widget.booking.unitName!,
//                         delay: 200,
//                       ),
//                     ],
//                     _buildGradientDivider(),
//                     _buildAnimatedDetailItem(
//                       'تاريخ الوصول',
//                       dateFormat.format(widget.booking.checkInDate),
//                       delay: 300,
//                     ),
//                     _buildGradientDivider(),
//                     _buildAnimatedDetailItem(
//                       'تاريخ المغادرة',
//                       dateFormat.format(widget.booking.checkOutDate),
//                       delay: 400,
//                     ),
//                     _buildGradientDivider(),
//                     _buildAnimatedDetailItem(
//                       'عدد الضيوف',
//                       '${widget.booking.totalGuests} ضيف',
//                       delay: 500,
//                     ),
//                     _buildGradientDivider(),
//                     _buildAnimatedDetailItem(
//                       'المبلغ الإجمالي',
//                       '${widget.booking.totalAmount.toStringAsFixed(0)} ${widget.booking.currency}',
//                       highlight: true,
//                       delay: 600,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailHeader() {
//     return Container(
//       padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.success.withOpacity(0.2),
//             AppTheme.success.withOpacity(0.1),
//           ],
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(AppDimensions.paddingSmall),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [
//                   AppTheme.success,
//                   AppTheme.neonGreen,
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppTheme.success.withOpacity(0.4),
//                   blurRadius: 10,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: const Icon(
//               Icons.confirmation_number,
//               color: Colors.white,
//               size: AppDimensions.iconMedium,
//             ),
//           ),
//           const SizedBox(width: AppDimensions.spacingMd),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ShaderMask(
//                 shaderCallback: (bounds) =>
//                     AppTheme.primaryGradient.createShader(bounds),
//                 child: Text(
//                   'تفاصيل الحجز',
//                   style: AppTextStyles.heading2.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               Text(
//                 'احتفظ بهذه المعلومات للرجوع إليها',
//                 style: AppTextStyles.caption.copyWith(
//                   color: AppTheme.textMuted,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnimatedDetailItem(
//     String label,
//     String value, {
//     bool canCopy = false,
//     bool highlight = false,
//     int delay = 0,
//   }) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0, end: 1),
//       duration: Duration(milliseconds: 800 + delay),
//       curve: Curves.easeOutBack,
//       builder: (context, animValue, child) {
//         return Transform.translate(
//           offset: Offset((1 - animValue) * 50, 0),
//           child: Opacity(
//             opacity: animValue.clamp(0.0, 1.0).toDouble(),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     label,
//                     style: AppTextStyles.bodyMedium.copyWith(
//                       color: AppTheme.textMuted,
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       highlight
//                           ? ShaderMask(
//                               shaderCallback: (bounds) =>
//                                   AppTheme.primaryGradient.createShader(bounds),
//                               child: Text(
//                                 value,
//                                 style: AppTextStyles.heading2.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             )
//                           : Text(
//                               value,
//                               style: AppTextStyles.bodyMedium.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: AppTheme.textWhite,
//                               ),
//                             ),
//                       if (canCopy) ...[
//                         const SizedBox(width: AppDimensions.spacingSm),
//                         InkWell(
//                           onTap: () => _copyToClipboard(value),
//                           child: Container(
//                             padding: const EdgeInsets.all(6),
//                             decoration: BoxDecoration(
//                               gradient: AppTheme.primaryGradient,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(
//                               Icons.copy,
//                               size: AppDimensions.iconSmall,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildGradientDivider() {
//     return Container(
//       height: 1,
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.transparent,
//             AppTheme.primaryBlue.withOpacity(0.2),
//             AppTheme.primaryPurple.withOpacity(0.2),
//             Colors.transparent,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Column(
//       children: [
//         // View Booking Details Button
//         _buildFuturisticButton(
//           icon: Icons.description_outlined,
//           label: 'عرض تفاصيل الحجز',
//           gradient: AppTheme.primaryGradient,
//           onPressed: () => context.push('/booking/${widget.booking.id}'),
//         ),
        
//         const SizedBox(height: AppDimensions.spacingMd),
        
//         // Add to Calendar Button
//         _buildFuturisticButton(
//           icon: Icons.calendar_today,
//           label: 'إضافة إلى التقويم',
//           gradient: const LinearGradient(
//             colors: [
//               AppTheme.primaryPurple,
//               AppTheme.primaryViolet,
//             ],
//           ),
//           isOutlined: true,
//           onPressed: _addToCalendar,
//         ),
        
//         const SizedBox(height: AppDimensions.spacingMd),
        
//         // Share Booking Button
//         _buildFuturisticButton(
//           icon: Icons.share,
//           label: 'مشاركة الحجز',
//           gradient: const LinearGradient(
//             colors: [
//               AppTheme.primaryCyan,
//               AppTheme.neonBlue,
//             ],
//           ),
//           isOutlined: true,
//           onPressed: _shareBooking,
//         ),
        
//         const SizedBox(height: AppDimensions.spacingLg),
        
//         // Home Button
//         TextButton(
//           onPressed: () {
//             HapticFeedback.lightImpact();
//             context.go('/home');
//           },
//           child: ShaderMask(
//             shaderCallback: (bounds) =>
//                 AppTheme.primaryGradient.createShader(bounds),
//             child: Text(
//               'العودة إلى الرئيسية',
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: Colors.white,
//                 decoration: TextDecoration.underline,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFuturisticButton({
//     required IconData icon,
//     required String label,
//     required Gradient gradient,
//     required VoidCallback onPressed,
//     bool isOutlined = false,
//   }) {
//     return GestureDetector(
//       onTapDown: (_) => HapticFeedback.lightImpact(),
//       onTap: onPressed,
//       child: Container(
//         width: double.infinity,
//         height: 56,
//         decoration: BoxDecoration(
//           gradient: isOutlined ? null : gradient,
//           borderRadius: BorderRadius.circular(20),
//           border: isOutlined
//               ? Border.all(
//                   width: 2,
//                   color: gradient.colors.first,
//                 )
//               : null,
//           boxShadow: !isOutlined
//               ? [
//                   BoxShadow(
//                     color: gradient.colors.first.withOpacity(0.4),
//                     blurRadius: 20,
//                     spreadRadius: 2,
//                     offset: const Offset(0, 4),
//                   ),
//                 ]
//               : [],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: onPressed,
//                 borderRadius: BorderRadius.circular(20),
//                 child: Center(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         icon,
//                         color: isOutlined ? gradient.colors.first : Colors.white,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         label,
//                         style: AppTextStyles.buttonLarge.copyWith(
//                           color: isOutlined ? gradient.colors.first : Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _copyToClipboard(String text) {
//     HapticFeedback.mediumImpact();
//     Clipboard.setData(ClipboardData(text: text));
//     _showFuturisticSnackBar('تم نسخ $text');
//   }

//   void _addToCalendar() {
//     HapticFeedback.lightImpact();
//     _showFuturisticDialog(
//       title: 'إضافة إلى التقويم',
//       content: 'سيتم إضافة موعد الحجز إلى تقويمك',
//       icon: Icons.calendar_today,
//       iconColor: AppTheme.primaryPurple,
//       onConfirm: () {
//         Navigator.pop(context);
//         _showFuturisticSnackBar('تمت الإضافة إلى التقويم بنجاح');
//       },
//     );
//   }

//   void _shareBooking() {
//     HapticFeedback.lightImpact();
//     final dateFormat = DateFormat('dd MMM yyyy', 'ar');
//     final shareText = '''
// 🎉 تم تأكيد الحجز!

// 📍 العقار: ${widget.booking.propertyName}
// ${widget.booking.unitName != null ? '🏠 الوحدة: ${widget.booking.unitName}' : ''}
// 📅 الوصول: ${dateFormat.format(widget.booking.checkInDate)}
// 📅 المغادرة: ${dateFormat.format(widget.booking.checkOutDate)}
// 👥 عدد الضيوف: ${widget.booking.totalGuests}
// 💰 المبلغ الإجمالي: ${widget.booking.totalAmount.toStringAsFixed(0)} ${widget.booking.currency}
// 🎫 رقم الحجز: ${widget.booking.bookingNumber}

// تم الحجز عبر تطبيق bookn
//     ''';

//     _showShareBottomSheet(shareText);
//   }

//   void _showShareBottomSheet(String shareText) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               AppTheme.darkCard,
//               AppTheme.darkSurface,
//             ],
//           ),
//           borderRadius: const BorderRadius.vertical(
//             top: Radius.circular(30),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: AppTheme.primaryBlue.withOpacity(0.3),
//               blurRadius: 30,
//               offset: const Offset(0, -10),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: const BorderRadius.vertical(
//             top: Radius.circular(30),
//           ),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//             child: Container(
//               padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 50,
//                     height: 5,
//                     margin: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
//                     decoration: BoxDecoration(
//                       gradient: AppTheme.primaryGradient,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   ShaderMask(
//                     shaderCallback: (bounds) =>
//                         AppTheme.primaryGradient.createShader(bounds),
//                     child: Text(
//                       'مشاركة تفاصيل الحجز',
//                       style: AppTextStyles.heading2.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: AppDimensions.spacingLg),
//                   Container(
//                     padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           AppTheme.darkCard.withOpacity(0.8),
//                           AppTheme.darkCard.withOpacity(0.5),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: AppTheme.primaryBlue.withOpacity(0.3),
//                       ),
//                     ),
//                     child: Text(
//                       shareText,
//                       style: AppTextStyles.bodyMedium,
//                     ),
//                   ),
//                   const SizedBox(height: AppDimensions.spacingLg),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildShareOption(
//                           icon: Icons.message,
//                           label: 'رسالة',
//                           color: AppTheme.success,
//                           onTap: () {
//                             Navigator.pop(context);
//                             _showFuturisticSnackBar('تم إرسال الرسالة');
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: AppDimensions.spacingMd),
//                       Expanded(
//                         child: _buildShareOption(
//                           icon: Icons.email,
//                           label: 'بريد',
//                           color: AppTheme.info,
//                           onTap: () {
//                             Navigator.pop(context);
//                             _showFuturisticSnackBar('تم إرسال البريد');
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: AppDimensions.spacingMd),
//                       Expanded(
//                         child: _buildShareOption(
//                           icon: Icons.copy,
//                           label: 'نسخ',
//                           color: AppTheme.primaryBlue,
//                           onTap: () {
//                             Navigator.pop(context);
//                             _copyToClipboard(shareText);
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   SafeArea(
//                     child: TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: Text(
//                         'إلغاء',
//                         style: AppTextStyles.bodyMedium.copyWith(
//                           color: AppTheme.textMuted,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildShareOption({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           vertical: AppDimensions.paddingMedium,
//         ),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               color.withOpacity(0.2),
//               color.withOpacity(0.1),
//             ],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: color.withOpacity(0.5),
//           ),
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 color: color,
//                 size: AppDimensions.iconMedium,
//               ),
//             ),
//             const SizedBox(height: AppDimensions.spacingXs),
//             Text(
//               label,
//               style: AppTextStyles.caption.copyWith(
//                 color: color,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showFuturisticDialog({
//     required String title,
//     required String content,
//     required IconData icon,
//     required Color iconColor,
//     required VoidCallback onConfirm,
//   }) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 AppTheme.darkCard.withOpacity(0.95),
//                 AppTheme.darkCard.withOpacity(0.85),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(
//               color: iconColor.withOpacity(0.3),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: iconColor.withOpacity(0.2),
//                 blurRadius: 30,
//                 spreadRadius: 5,
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(24),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       gradient: RadialGradient(
//                         colors: [
//                           iconColor.withOpacity(0.2),
//                           iconColor.withOpacity(0.05),
//                         ],
//                       ),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       icon,
//                       size: 40,
//                       color: iconColor,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     title,
//                     style: AppTextStyles.heading2.copyWith(
//                       color: iconColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     content,
//                     style: AppTextStyles.bodyMedium.copyWith(
//                       color: AppTheme.textMuted,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 24),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text(
//                           'إلغاء',
//                           style: AppTextStyles.buttonMedium.copyWith(
//                             color: AppTheme.textMuted,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [iconColor, iconColor.withOpacity(0.7)],
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             onTap: onConfirm,
//                             borderRadius: BorderRadius.circular(12),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 10,
//                               ),
//                               child: Text(
//                                 'تأكيد',
//                                 style: AppTextStyles.buttonMedium.copyWith(
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showFuturisticSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Container(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           child: Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       AppTheme.success.withOpacity(0.8),
//                       AppTheme.success,
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.check_circle,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   message,
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(20),
//         padding: EdgeInsets.zero,
//         duration: const Duration(seconds: 3),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),
//     );
//   }
// }

// // Celebration Pattern Painter
// class _CelebrationPatternPainter extends CustomPainter {
//   final double animationValue;
  
//   _CelebrationPatternPainter({required this.animationValue});
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
    
//     for (int i = 0; i < 5; i++) {
//       final radius = 100 + (i * 50) + (animationValue * 100);
//       paint.shader = RadialGradient(
//         colors: [
//           AppTheme.success.withOpacity(0.1 - (i * 0.02)),
//           Colors.transparent,
//         ],
//       ).createShader(Rect.fromCircle(
//         center: Offset(size.width / 2, size.height / 3),
//         radius: radius,
//       ));
      
//       canvas.drawCircle(
//         Offset(size.width / 2, size.height / 3),
//         radius,
//         paint,
//       );
//     }
//   }
  
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// // Checkmark Painter
// class _CheckmarkPainter extends CustomPainter {
//   final double progress;
  
//   _CheckmarkPainter({required this.progress});
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 5
//       ..strokeCap = StrokeCap.round
//       ..style = PaintingStyle.stroke;
    
//     final path = Path();
    
//     if (progress > 0) {
//       path.moveTo(size.width * 0.2, size.height * 0.5);
      
//       if (progress <= 0.5) {
//         final firstProgress = progress * 2;
//         path.lineTo(
//           size.width * 0.2 + (size.width * 0.2 * firstProgress),
//           size.height * 0.5 + (size.height * 0.2 * firstProgress),
//         );
//       } else {
//         path.lineTo(size.width * 0.4, size.height * 0.7);
        
//         final secondProgress = (progress - 0.5) * 2;
//         path.lineTo(
//           size.width * 0.4 + (size.width * 0.4 * secondProgress),
//           size.height * 0.7 - (size.height * 0.4 * secondProgress),
//         );
//       }
//     }
    
//     canvas.drawPath(path, paint);
//   }
  
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// // Confetti Particle
// class _ConfettiParticle {
//   late double x;
//   late double y;
//   late double vx;
//   late double vy;
//   late double rotation;
//   late double rotationSpeed;
//   late Color color;
//   late double size;
  
//   _ConfettiParticle() {
//     reset();
//   }
  
//   void reset() {
//     x = math.Random().nextDouble();
//     y = -0.1;
//     vx = (math.Random().nextDouble() - 0.5) * 0.02;
//     vy = math.Random().nextDouble() * 0.02 + 0.01;
//     rotation = math.Random().nextDouble() * 2 * math.pi;
//     rotationSpeed = (math.Random().nextDouble() - 0.5) * 0.2;
//     size = math.Random().nextDouble() * 10 + 5;
    
//     final colors = [
//       AppTheme.success,
//       AppTheme.primaryBlue,
//       AppTheme.primaryPurple,
//       AppTheme.neonGreen,
//       AppTheme.primaryCyan,
//       AppTheme.warning,
//     ];
//     color = colors[math.Random().nextInt(colors.length)];
//   }
  
//   void update(double animationValue) {
//     x += vx;
//     y += vy;
//     rotation += rotationSpeed;
//     vy += 0.0005; // Gravity
    
//     if (y > 1.1) {
//       reset();
//     }
//   }
// }

// // Confetti Painter
// class _ConfettiPainter extends CustomPainter {
//   final List<_ConfettiParticle> particles;
//   final double animationValue;
  
//   _ConfettiPainter({
//     required this.particles,
//     required this.animationValue,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     for (var particle in particles) {
//       particle.update(animationValue);
      
//       final paint = Paint()
//         ..color = particle.color.withOpacity(0.8)
//         ..style = PaintingStyle.fill;
      
//       canvas.save();
//       canvas.translate(
//         particle.x * size.width,
//         particle.y * size.height,
//       );
//       canvas.rotate(particle.rotation);
      
//       canvas.drawRect(
//         Rect.fromCenter(
//           center: Offset.zero,
//           width: particle.size,
//           height: particle.size * 0.6,
//         ),
//         paint,
//       );
      
//       canvas.restore();
//     }
//   }
  
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Booking booking;

  const BookingConfirmationPage({
    super.key,
    required this.booking,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage>
    with SingleTickerProviderStateMixin {
  // Simplified Animation
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
    ));
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mainController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBackground,
                    AppTheme.darkSurface.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            
            // Subtle success glow
            Positioned(
              top: 100,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.success.withOpacity(0.1 * _scaleAnimation.value),
                          AppTheme.success.withOpacity(0.05 * _scaleAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Main Content
            SafeArea(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildContent(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildCompactSuccessIcon(),
          const SizedBox(height: 24),
          _buildSuccessMessage(),
          const SizedBox(height: 32),
          _buildMinimalBookingCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCompactSuccessIcon() {
    return AnimatedBuilder(
      animation: _checkAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.success.withOpacity(0.1),
            border: Border.all(
              color: AppTheme.success.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(40, 40),
              painter: _MinimalCheckPainter(
                progress: _checkAnimation.value,
                color: AppTheme.success,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Text(
          'تم الحجز بنجاح!',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'رقم الحجز: ${widget.booking.bookingNumber}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalBookingCard() {
    final dateFormat = DateFormat('dd MMM', 'ar');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Property Name
          _buildCompactRow(
            icon: Icons.home_outlined,
            label: widget.booking.propertyName,
            isTitle: true,
          ),
          
          if (widget.booking.unitName != null) ...[
            const SizedBox(height: 12),
            _buildCompactRow(
              icon: Icons.door_back_door_outlined,
              label: widget.booking.unitName!,
            ),
          ],
          
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          
          // Dates Row
          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  title: 'دخول',
                  date: dateFormat.format(widget.booking.checkInDate),
                  icon: Icons.login_rounded,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Expanded(
                child: _buildDateInfo(
                  title: 'خروج',
                  date: dateFormat.format(widget.booking.checkOutDate),
                  icon: Icons.logout_rounded,
                  isEnd: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          
          // Guests and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                icon: Icons.people_outline,
                label: '${widget.booking.totalGuests} ضيف',
              ),
              _buildPriceChip(
                amount: widget.booking.totalAmount,
                currency: widget.booking.currency,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRow({
    required IconData icon,
    required String label,
    bool isTitle = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: isTitle
                ? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  )
                : AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo({
    required String title,
    required String date,
    required IconData icon,
    bool isEnd = false,
  }) {
    return Column(
      crossAxisAlignment: isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip({
    required double amount,
    required String currency,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.15),
            AppTheme.primaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '${amount.toStringAsFixed(0)} $currency',
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.darkBorder.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Action - View Details
        _buildMinimalButton(
          label: 'عرض التفاصيل',
          icon: Icons.description_outlined,
          onPressed: () => context.push('/booking/${widget.booking.id}'),
          isPrimary: true,
        ),
        
        const SizedBox(height: 12),
        
        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: _buildMinimalButton(
                label: 'مشاركة',
                icon: Icons.share_outlined,
                onPressed: _shareBooking,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMinimalButton(
                label: 'حفظ PDF',
                icon: Icons.download_outlined,
                onPressed: _downloadPDF,
                isCompact: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Home Link
        TextButton(
          onPressed: () => context.go('/home'),
          child: Text(
            'العودة للرئيسية',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.textMuted.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        height: isCompact ? 42 : 48,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.9),
                    AppTheme.primaryPurple.withOpacity(0.9),
                  ],
                )
              : null,
          color: !isPrimary ? AppTheme.darkCard.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(12),
          border: !isPrimary
              ? Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 0.5,
                )
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isCompact ? 16 : 18,
                color: isPrimary ? Colors.white : AppTheme.textLight,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: (isCompact ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium).copyWith(
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? Colors.white : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareBooking() {
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');
    final shareText = '''
تم تأكيد الحجز ✅

📍 ${widget.booking.propertyName}
📅 ${dateFormat.format(widget.booking.checkInDate)} - ${dateFormat.format(widget.booking.checkOutDate)}
👥 ${widget.booking.totalGuests} ضيف
💰 ${widget.booking.totalAmount.toStringAsFixed(0)} ${widget.booking.currency}
🎫 ${widget.booking.bookingNumber}
    ''';
    
    Clipboard.setData(ClipboardData(text: shareText));
    _showMinimalSnackBar('تم نسخ التفاصيل');
  }

  void _downloadPDF() {
    _showMinimalSnackBar('جاري تحميل PDF...');
  }

  void _showMinimalSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Minimal Check Painter
class _MinimalCheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  _MinimalCheckPainter({
    required this.progress,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    if (progress > 0) {
      path.moveTo(size.width * 0.25, size.height * 0.5);
      
      if (progress <= 0.5) {
        final firstProgress = progress * 2;
        path.lineTo(
          size.width * 0.25 + (size.width * 0.15 * firstProgress),
          size.height * 0.5 + (size.height * 0.15 * firstProgress),
        );
      } else {
        path.lineTo(size.width * 0.4, size.height * 0.65);
        
        final secondProgress = (progress - 0.5) * 2;
        path.lineTo(
          size.width * 0.4 + (size.width * 0.35 * secondProgress),
          size.height * 0.65 - (size.height * 0.35 * secondProgress),
        );
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}