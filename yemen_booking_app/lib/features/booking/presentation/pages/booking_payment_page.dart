// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'dart:ui';
// import 'dart:math' as math;
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_dimensions.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../../../core/enums/payment_method_enum.dart';
// import '../../../auth/presentation/bloc/auth_bloc.dart';
// import '../../../auth/presentation/bloc/auth_state.dart';
// import '../../../payment/presentation/bloc/payment_bloc.dart';
// import '../../../payment/presentation/bloc/payment_event.dart';
// import '../bloc/booking_bloc.dart';
// import '../bloc/booking_state.dart';
// import '../widgets/payment_methods_widget.dart';

// class BookingPaymentPage extends StatefulWidget {
//   final Map<String, dynamic> bookingData;

//   const BookingPaymentPage({
//     super.key,
//     required this.bookingData,
//   });

//   @override
//   State<BookingPaymentPage> createState() => _BookingPaymentPageState();
// }

// class _BookingPaymentPageState extends State<BookingPaymentPage>
//     with TickerProviderStateMixin {
//   // Animation Controllers
//   late AnimationController _backgroundAnimationController;
//   late AnimationController _cardAnimationController;
//   late AnimationController _pulseAnimationController;
//   late AnimationController _securityAnimationController;
//   late AnimationController _checkAnimationController;
  
//   // Animations
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _rotationAnimation;
//   late Animation<double> _securityPulseAnimation;
  
//   // State
//   String? _selectedPaymentMethod;
//   bool _acceptTerms = false;
  
//   // Holographic Effect
//   final List<_HolographicParticle> _particles = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _generateParticles();
//     _startAnimations();
//   }

//   void _initializeAnimations() {
//     // Background Animation
//     _backgroundAnimationController = AnimationController(
//       duration: const Duration(seconds: 25),
//       vsync: this,
//     )..repeat();
    
//     _rotationAnimation = Tween<double>(
//       begin: 0,
//       end: 2 * math.pi,
//     ).animate(_backgroundAnimationController);
    
//     // Card Animation
//     _cardAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
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
    
//     _scaleAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _cardAnimationController,
//       curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
//     ));
    
//     // Pulse Animation
//     _pulseAnimationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     // Security Animation
//     _securityAnimationController = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _securityPulseAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _securityAnimationController,
//       curve: Curves.easeInOut,
//     ));
    
//     // Check Animation
//     _checkAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }
  
//   void _generateParticles() {
//     for (int i = 0; i < 30; i++) {
//       _particles.add(_HolographicParticle());
//     }
//   }
  
//   void _startAnimations() {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _cardAnimationController.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _backgroundAnimationController.dispose();
//     _cardAnimationController.dispose();
//     _pulseAnimationController.dispose();
//     _securityAnimationController.dispose();
//     _checkAnimationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.darkBackground,
//       extendBodyBehindAppBar: true,
//       appBar: _buildFuturisticAppBar(),
//       body: BlocConsumer<BookingBloc, BookingState>(
//         listener: (context, state) {
//           if (state is BookingCreated) {
//             context.push(
//               '/booking/confirmation',
//               extra: state.booking,
//             );
//           } else if (state is BookingError) {
//             _showFuturisticSnackBar(state.message, isError: true);
//           }
//         },
//         builder: (context, state) {
//           if (state is BookingLoading) {
//             return Center(
//               child: _buildFuturisticLoader(),
//             );
//           }
          
//           return Stack(
//             children: [
//               // Animated Background
//               _buildAnimatedBackground(),
              
//               // Holographic Particles
//               _buildHolographicParticles(),
              
//               // Main Content
//               SafeArea(
//                 child: _buildContent(),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   PreferredSizeWidget _buildFuturisticAppBar() {
//     return AppBar(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       systemOverlayStyle: const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.light,
//       ),
//       leading: _buildGlassBackButton(),
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ShaderMask(
//             shaderCallback: (bounds) =>
//                 AppTheme.primaryGradient.createShader(bounds),
//             child: Text(
//               'الدفع',
//               style: AppTextStyles.heading2.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//           Text(
//             'الخطوة 3 من 3',
//             style: AppTextStyles.caption.copyWith(
//               color: AppTheme.textMuted,
//             ),
//           ),
//         ],
//       ),
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(4),
//         child: AnimatedBuilder(
//           animation: _pulseAnimationController,
//           builder: (context, child) {
//             return Container(
//               height: 4,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppTheme.primaryBlue.withOpacity(0.3),
//                     AppTheme.neonGreen.withOpacity(
//                       0.6 + (_pulseAnimationController.value * 0.4),
//                     ),
//                     AppTheme.primaryCyan.withOpacity(0.3),
//                   ],
//                 ),
//               ),
//               child: LinearProgressIndicator(
//                 value: 1.0,
//                 backgroundColor: Colors.transparent,
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   AppTheme.neonGreen.withOpacity(0.8),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildGlassBackButton() {
//     return Container(
//       margin: const EdgeInsets.all(8),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   AppTheme.darkCard.withOpacity(0.6),
//                   AppTheme.darkCard.withOpacity(0.3),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: AppTheme.primaryBlue.withOpacity(0.2),
//                 width: 1,
//               ),
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back_ios_new, size: 20),
//               color: AppTheme.textWhite,
//               onPressed: () {
//                 HapticFeedback.lightImpact();
//                 Navigator.pop(context);
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimatedBackground() {
//     return AnimatedBuilder(
//       animation: _rotationAnimation,
//       builder: (context, child) {
//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment(
//                 math.cos(_rotationAnimation.value * 0.3),
//                 math.sin(_rotationAnimation.value * 0.3),
//               ),
//               end: Alignment(
//                 -math.cos(_rotationAnimation.value * 0.3),
//                 -math.sin(_rotationAnimation.value * 0.3),
//               ),
//               colors: [
//                 AppTheme.darkBackground,
//                 const Color(0xFF0A1929),
//                 AppTheme.darkBackground3.withOpacity(0.9),
//               ],
//             ),
//           ),
//           child: CustomPaint(
//             painter: _SecureNetworkPainter(
//               animationValue: _rotationAnimation.value,
//               pulseValue: _pulseAnimationController.value,
//             ),
//             size: Size.infinite,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHolographicParticles() {
//     return AnimatedBuilder(
//       animation: _securityAnimationController,
//       builder: (context, child) {
//         return CustomPaint(
//           painter: _HolographicPainter(
//             particles: _particles,
//             animationValue: _securityAnimationController.value,
//           ),
//           size: Size.infinite,
//         );
//       },
//     );
//   }

//   Widget _buildContent() {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//       child: AnimatedBuilder(
//         animation: _cardAnimationController,
//         builder: (context, child) {
//           return FadeTransition(
//             opacity: _fadeAnimation,
//             child: SlideTransition(
//               position: _slideAnimation,
//               child: Transform.scale(
//                 scale: _scaleAnimation.value,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 20),
//                     _buildFuturisticPaymentMethodsSection(),
//                     const SizedBox(height: AppDimensions.spacingLg),
//                     _buildFuturisticBookingSummary(),
//                     const SizedBox(height: AppDimensions.spacingLg),
//                     _buildFuturisticTermsAndConditions(),
//                     const SizedBox(height: AppDimensions.spacingXl),
//                     _buildFuturisticPayButton(),
//                     const SizedBox(height: AppDimensions.spacingLg),
//                     _buildFuturisticSecurityInfo(),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildFuturisticPaymentMethodsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 gradient: AppTheme.primaryGradient,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppTheme.primaryBlue.withOpacity(0.4),
//                     blurRadius: 15,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.payment,
//                 color: Colors.white,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 16),
//             ShaderMask(
//               shaderCallback: (bounds) =>
//                   AppTheme.primaryGradient.createShader(bounds),
//               child: Text(
//                 'طريقة الدفع',
//                 style: AppTextStyles.heading2.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: AppDimensions.spacingMd),
//         PaymentMethodsWidget(
//           selectedMethod: _selectedPaymentMethod,
//           onMethodSelected: (method) {
//             HapticFeedback.lightImpact();
//             setState(() {
//               _selectedPaymentMethod = method;
//             });
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildFuturisticBookingSummary() {
//     final checkIn = widget.bookingData['checkIn'] as DateTime;
//     final checkOut = widget.bookingData['checkOut'] as DateTime;
//     final nights = checkOut.difference(checkIn).inDays;
//     final pricePerNight = (widget.bookingData['pricePerNight'] ?? 0.0) as double;
//     final services = widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
//     final servicesTotal = services.fold<double>(
//       0,
//       (sum, service) => sum + (service['price'] as num).toDouble(),
//     );
//     final subtotal = (nights * pricePerNight) + servicesTotal;
//     final tax = subtotal * 0.05;
//     final total = subtotal + tax;

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
//           color: AppTheme.primaryPurple.withOpacity(0.3),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: AppTheme.primaryPurple.withOpacity(0.2),
//             blurRadius: 30,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: Padding(
//             padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         gradient: AppTheme.primaryGradient,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.receipt_long,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       'ملخص الحجز',
//                       style: AppTextStyles.heading3.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.textWhite,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: AppDimensions.spacingMd),
//                 _buildSummaryRow(
//                   label: 'الإقامة ($nights ليالي)',
//                   value: '${(nights * pricePerNight).toStringAsFixed(0)} ريال',
//                   isAnimated: true,
//                 ),
//                 if (servicesTotal > 0) ...[
//                   const SizedBox(height: AppDimensions.spacingSm),
//                   _buildSummaryRow(
//                     label: 'الخدمات الإضافية',
//                     value: '${servicesTotal.toStringAsFixed(0)} ريال',
//                     isAnimated: true,
//                   ),
//                 ],
//                 const SizedBox(height: AppDimensions.spacingSm),
//                 _buildSummaryRow(
//                   label: 'الضرائب (5%)',
//                   value: '${tax.toStringAsFixed(0)} ريال',
//                   isAnimated: true,
//                 ),
//                 _buildGradientDivider(),
//                 _buildSummaryRow(
//                   label: 'المجموع الكلي',
//                   value: '${total.toStringAsFixed(0)} ريال',
//                   isTotal: true,
//                   isAnimated: true,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryRow({
//     required String label,
//     required String value,
//     bool isTotal = false,
//     bool isAnimated = false,
//   }) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0, end: 1),
//       duration: Duration(milliseconds: isAnimated ? 800 : 0),
//       curve: Curves.easeOutBack,
//       builder: (context, animValue, child) {
//         return Transform.translate(
//           offset: Offset((1 - animValue) * 50, 0),
//           child: Opacity(
//             opacity: animValue.clamp(0.0, 1.0).toDouble(),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   label,
//                   style: isTotal
//                       ? AppTextStyles.heading3.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.textWhite,
//                         )
//                       : AppTextStyles.bodyMedium.copyWith(
//                           color: AppTheme.textMuted,
//                         ),
//                 ),
//                 isTotal
//                     ? ShaderMask(
//                         shaderCallback: (bounds) =>
//                             AppTheme.primaryGradient.createShader(bounds),
//                         child: Text(
//                           value,
//                           style: AppTextStyles.heading2.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       )
//                     : Text(
//                         value,
//                         style: AppTextStyles.bodyMedium.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.textWhite,
//                         ),
//                       ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildGradientDivider() {
//     return Container(
//       height: 1,
//       margin: const EdgeInsets.symmetric(vertical: 16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.transparent,
//             AppTheme.primaryBlue.withOpacity(0.3),
//             AppTheme.primaryPurple.withOpacity(0.3),
//             Colors.transparent,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFuturisticTermsAndConditions() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.warning.withOpacity(0.15),
//             AppTheme.warning.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: AppTheme.warning.withOpacity(0.5),
//           width: 1,
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Padding(
//             padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         HapticFeedback.lightImpact();
//                         setState(() {
//                           _acceptTerms = !_acceptTerms;
//                           if (_acceptTerms) {
//                             _checkAnimationController.forward();
//                           } else {
//                             _checkAnimationController.reverse();
//                           }
//                         });
//                       },
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 300),
//                         width: 24,
//                         height: 24,
//                         decoration: BoxDecoration(
//                           gradient: _acceptTerms
//                               ? AppTheme.primaryGradient
//                               : null,
//                           color: !_acceptTerms
//                               ? AppTheme.darkCard.withOpacity(0.5)
//                               : null,
//                           borderRadius: BorderRadius.circular(6),
//                           border: Border.all(
//                             color: _acceptTerms
//                                 ? Colors.transparent
//                                 : AppTheme.warning,
//                             width: 2,
//                           ),
//                         ),
//                         child: _acceptTerms
//                             ? const Icon(
//                                 Icons.check,
//                                 size: 16,
//                                 color: Colors.white,
//                               )
//                             : null,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'أوافق على الشروط والأحكام وسياسة الإلغاء',
//                         style: AppTextStyles.bodyMedium.copyWith(
//                           color: AppTheme.textWhite,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: AppDimensions.spacingSm),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: AppTheme.darkCard.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.info_outline,
//                         color: AppTheme.warning,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'يمكن إلغاء الحجز مجاناً قبل 24 ساعة من تاريخ الوصول',
//                           style: AppTextStyles.caption.copyWith(
//                             color: AppTheme.textMuted,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFuturisticPayButton() {
//     final isValid = _selectedPaymentMethod != null && _acceptTerms;

//     return GestureDetector(
//       onTapDown: isValid ? (_) => HapticFeedback.lightImpact() : null,
//       onTap: isValid ? _processPayment : null,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         height: 60,
//         decoration: BoxDecoration(
//           gradient: isValid
//               ? AppTheme.primaryGradient
//               : LinearGradient(
//                   colors: [
//                     AppTheme.darkBorder.withOpacity(0.5),
//                     AppTheme.darkBorder.withOpacity(0.3),
//                   ],
//                 ),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: isValid
//               ? [
//                   BoxShadow(
//                     color: AppTheme.primaryBlue.withOpacity(0.4),
//                     blurRadius: 20,
//                     spreadRadius: 2,
//                     offset: const Offset(0, 4),
//                   ),
//                   BoxShadow(
//                     color: AppTheme.neonGreen.withOpacity(0.3),
//                     blurRadius: 30,
//                     spreadRadius: 5,
//                   ),
//                 ]
//               : [],
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: isValid ? _processPayment : null,
//             borderRadius: BorderRadius.circular(20),
//             child: Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.lock,
//                     color: isValid ? Colors.white : AppTheme.textMuted,
//                     size: 20,
//                   ),
//                   const SizedBox(width: AppDimensions.spacingSm),
//                   Text(
//                     'دفع وتأكيد الحجز',
//                     style: AppTextStyles.buttonLarge.copyWith(
//                       color: isValid ? Colors.white : AppTheme.textMuted,
//                       fontWeight: FontWeight.bold,
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

//   Widget _buildFuturisticSecurityInfo() {
//     return AnimatedBuilder(
//       animation: _securityPulseAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _securityPulseAnimation.value,
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   AppTheme.info.withOpacity(0.15),
//                   AppTheme.info.withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: AppTheme.info.withOpacity(0.5),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppTheme.info.withOpacity(0.2),
//                   blurRadius: 20,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                 child: Padding(
//                   padding: const EdgeInsets.all(AppDimensions.paddingMedium),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           gradient: AppTheme.primaryGradient,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: AppTheme.primaryBlue.withOpacity(0.4),
//                               blurRadius: 15,
//                               spreadRadius: 2,
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.security,
//                           color: Colors.white,
//                           size: AppDimensions.iconMedium,
//                         ),
//                       ),
//                       const SizedBox(width: AppDimensions.spacingSm),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             ShaderMask(
//                               shaderCallback: (bounds) =>
//                                   AppTheme.primaryGradient.createShader(bounds),
//                               child: Text(
//                                 'الدفع الآمن',
//                                 style: AppTextStyles.caption.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                             Text(
//                               'جميع معلومات الدفع محمية ومشفرة بتقنية SSL 256-bit',
//                               style: AppTextStyles.caption.copyWith(
//                                 color: AppTheme.textMuted,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildFuturisticLoader() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           width: 120,
//           height: 120,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: AppTheme.primaryGradient,
//             boxShadow: [
//               BoxShadow(
//                 color: AppTheme.primaryBlue.withOpacity(0.5),
//                 blurRadius: 30,
//                 spreadRadius: 10,
//               ),
//             ],
//           ),
//           child: const Center(
//             child: CircularProgressIndicator(
//               strokeWidth: 3,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ),
//         ),
//         const SizedBox(height: 24),
//         ShaderMask(
//           shaderCallback: (bounds) =>
//               AppTheme.primaryGradient.createShader(bounds),
//           child: Text(
//             'جاري معالجة الدفع...',
//             style: AppTextStyles.bodyLarge.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _processPayment() {
//     HapticFeedback.mediumImpact();
    
//     final authState = context.read<AuthBloc>().state;
//     if (authState is! AuthAuthenticated) {
//       context.push('/login');
//       return;
//     }

//     // Convert string to PaymentMethod enum
//     final paymentMethod = PaymentMethodExtension.fromString(_selectedPaymentMethod ?? 'cash');

//     // Calculate total amount
//     final checkIn = widget.bookingData['checkIn'] as DateTime;
//     final checkOut = widget.bookingData['checkOut'] as DateTime;
//     final nights = checkOut.difference(checkIn).inDays;
//     final pricePerNight = (widget.bookingData['pricePerNight'] ?? 0.0) as double;
//     final services = widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
//     final servicesTotal = services.fold<double>(
//       0,
//       (sum, service) => sum + (service['price'] as num).toDouble(),
//     );
//     final subtotal = (nights * pricePerNight) + servicesTotal;
//     final tax = subtotal * 0.05;
//     final total = subtotal + tax;

//     // Process payment through PaymentBloc
//     context.read<PaymentBloc>().add(
//       ProcessPaymentEvent(
//         bookingId: widget.bookingData['bookingId'] ?? '',
//         userId: authState.user.userId,
//         amount: total,
//         paymentMethod: paymentMethod,
//         currency: 'YER',
//         paymentDetails: _getPaymentDetails(paymentMethod),
//       ),
//     );
//   }

//   Map<String, dynamic>? _getPaymentDetails(PaymentMethod method) {
//     // Get payment details based on method
//     if (method == PaymentMethod.creditCard) {
//       return {
//         'cardNumber': '4111111111111111',
//         'cardHolderName': 'John Doe',
//         'expiryDate': '12/25',
//         'cvv': '123',
//       };
//     } else if (method.isWallet) {
//       return {
//         'walletNumber': '773123456',
//         'walletPin': '1234',
//       };
//     }
//     return null;
//   }

//   void _showFuturisticSnackBar(String message, {bool isError = false}) {
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
//                     colors: isError
//                         ? [AppTheme.error.withOpacity(0.8), AppTheme.error]
//                         : [AppTheme.success.withOpacity(0.8), AppTheme.success],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   isError ? Icons.error_outline : Icons.check_circle_outline,
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
//         duration: const Duration(seconds: 4),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),
//     );
//   }
// }

// // Secure Network Painter
// class _SecureNetworkPainter extends CustomPainter {
//   final double animationValue;
//   final double pulseValue;
  
//   _SecureNetworkPainter({
//     required this.animationValue,
//     required this.pulseValue,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
    
//     // Draw network grid
//     for (int i = 0; i < 10; i++) {
//       for (int j = 0; j < 10; j++) {
//         final x = size.width / 10 * i;
//         final y = size.height / 10 * j;
        
//         paint.color = AppTheme.primaryBlue.withOpacity(
//           0.05 + (math.sin(animationValue + i + j) * 0.05).abs(),
//         );
        
//         // Draw connections
//         if (i < 9) {
//           canvas.drawLine(
//             Offset(x, y),
//             Offset(x + size.width / 10, y),
//             paint,
//           );
//         }
//         if (j < 9) {
//           canvas.drawLine(
//             Offset(x, y),
//             Offset(x, y + size.height / 10),
//             paint,
//           );
//         }
        
//         // Draw nodes
//         final nodeRadius = 2 + pulseValue * 2;
//         paint.style = PaintingStyle.fill;
//         paint.color = AppTheme.primaryCyan.withOpacity(0.3);
//         canvas.drawCircle(Offset(x, y), nodeRadius, paint);
//         paint.style = PaintingStyle.stroke;
//       }
//     }
//   }
  
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// // Holographic Particle Model
// class _HolographicParticle {
//   late double x;
//   late double y;
//   late double z;
//   late double size;
//   late Color color;
//   late double speed;
  
//   _HolographicParticle() {
//     reset();
//   }
  
//   void reset() {
//     x = math.Random().nextDouble();
//     y = math.Random().nextDouble();
//     z = math.Random().nextDouble();
//     size = math.Random().nextDouble() * 3 + 1;
//     speed = math.Random().nextDouble() * 0.02 + 0.01;
    
//     final colors = [
//       AppTheme.neonBlue,
//       AppTheme.neonPurple,
//       AppTheme.neonGreen,
//     ];
//     color = colors[math.Random().nextInt(colors.length)];
//   }
  
//   void update(double animationValue) {
//     z += speed;
//     if (z > 1) {
//       z = 0;
//       x = math.Random().nextDouble();
//       y = math.Random().nextDouble();
//     }
//   }
// }

// // Holographic Painter
// class _HolographicPainter extends CustomPainter {
//   final List<_HolographicParticle> particles;
//   final double animationValue;
  
//   _HolographicPainter({
//     required this.particles,
//     required this.animationValue,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     for (var particle in particles) {
//       particle.update(animationValue);
      
//       final scale = particle.z;
//       final opacity = scale * 0.5;
      
//       final paint = Paint()
//         ..color = particle.color.withOpacity(opacity)
//         ..style = PaintingStyle.fill
//         ..maskFilter = MaskFilter.blur(
//           BlurStyle.normal,
//           10 * (1 - scale),
//         );
      
//       canvas.drawCircle(
//         Offset(
//           particle.x * size.width,
//           particle.y * size.height,
//         ),
//         particle.size * scale,
//         paint,
//       );
//     }
//   }
  
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../../../payment/presentation/bloc/payment_event.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_state.dart';
import '../widgets/payment_methods_widget.dart';

class BookingPaymentPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingPaymentPage({
    super.key,
    required this.bookingData,
  });

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage>
    with SingleTickerProviderStateMixin {
  // Simplified Animation
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  // State
  String? _selectedPaymentMethod;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));
    
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildMinimalAppBar(),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            context.push(
              '/booking/confirmation',
              extra: state.booking,
            );
          } else if (state is BookingError) {
            _showMinimalSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return Center(
              child: _buildMinimalLoader(),
            );
          }
          
          return _buildContent();
        },
      ),
    );
  }

  PreferredSizeWidget _buildMinimalAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkBackground,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppTheme.textWhite,
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الدفع',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
          ),
          Text(
            'الخطوة الأخيرة',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.darkBorder.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildCompactSummary(),
                  const SizedBox(height: 20),
                  _buildPaymentMethodsSection(),
                  const SizedBox(height: 20),
                  _buildTermsSection(),
                  const SizedBox(height: 24),
                  _buildPayButton(),
                  const SizedBox(height: 16),
                  _buildSecurityNote(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSummary() {
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final nights = checkOut.difference(checkIn).inDays;
    final pricePerNight = (widget.bookingData['pricePerNight'] ?? 0.0) as double;
    final services = widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
    final servicesTotal = services.fold<double>(
      0,
      (sum, service) => sum + (service['price'] as num).toDouble(),
    );
    final subtotal = (nights * pricePerNight) + servicesTotal;
    final tax = subtotal * 0.05;
    final total = subtotal + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ملخص الحجز',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$nights ليالي',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Compact price rows
          _buildPriceRow('الإقامة', nights * pricePerNight),
          if (servicesTotal > 0)
            _buildPriceRow('الخدمات', servicesTotal),
          _buildPriceRow('الضرائب', tax),
          
          const SizedBox(height: 8),
          Container(
            height: 0.5,
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} ريال',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} ريال',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        PaymentMethodsWidget(
          selectedMethod: _selectedPaymentMethod,
          onMethodSelected: (method) {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _acceptTerms = !_acceptTerms;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _acceptTerms 
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _acceptTerms
                    ? AppTheme.primaryBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _acceptTerms
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: _acceptTerms
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أوافق على الشروط والأحكام',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'يمكن الإلغاء مجاناً قبل 24 ساعة',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    final isValid = _selectedPaymentMethod != null && _acceptTerms;

    return GestureDetector(
      onTap: isValid ? _processPayment : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          gradient: isValid
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.9),
                    AppTheme.primaryPurple.withOpacity(0.9),
                  ],
                )
              : null,
          color: !isValid ? AppTheme.darkCard.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: isValid ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'دفع وتأكيد',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isValid ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_outlined,
            size: 16,
            color: AppTheme.info.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'معلوماتك محمية بتشفير SSL 256-bit',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
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
            color: AppTheme.darkCard.withOpacity(0.3),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جاري المعالجة...',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  void _processPayment() {
    HapticFeedback.mediumImpact();
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login');
      return;
    }

    final paymentMethod = PaymentMethodExtension.fromString(_selectedPaymentMethod ?? 'cash');

    // Calculate total
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final nights = checkOut.difference(checkIn).inDays;
    final pricePerNight = (widget.bookingData['pricePerNight'] ?? 0.0) as double;
    final services = widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
    final servicesTotal = services.fold<double>(
      0,
      (sum, service) => sum + (service['price'] as num).toDouble(),
    );
    final subtotal = (nights * pricePerNight) + servicesTotal;
    final tax = subtotal * 0.05;
    final total = subtotal + tax;

    context.read<PaymentBloc>().add(
      ProcessPaymentEvent(
        bookingId: widget.bookingData['bookingId'] ?? '',
        userId: authState.user.userId,
        amount: total,
        paymentMethod: paymentMethod,
        currency: 'YER',
        paymentDetails: _getPaymentDetails(paymentMethod),
      ),
    );
  }

  Map<String, dynamic>? _getPaymentDetails(PaymentMethod method) {
    if (method == PaymentMethod.creditCard) {
      return {
        'cardNumber': '4111111111111111',
        'cardHolderName': 'John Doe',
        'expiryDate': '12/25',
        'cvv': '123',
      };
    } else if (method.isWallet) {
      return {
        'walletNumber': '773123456',
        'walletPin': '1234',
      };
    }
    return null;
  }

  void _showMinimalSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.darkCard,
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