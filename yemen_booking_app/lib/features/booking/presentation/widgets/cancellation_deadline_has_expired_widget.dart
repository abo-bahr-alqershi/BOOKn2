// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:ui';
// import 'dart:math' as math;
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';

// class CancellationDeadlineHasExpiredWidget extends StatefulWidget {
//   final bool hasExpired;
//   final DateTime deadline;
//   final String? policy;

//   const CancellationDeadlineHasExpiredWidget({
//     super.key,
//     required this.hasExpired,
//     required this.deadline,
//     this.policy,
//   });

//   @override
//   State<CancellationDeadlineHasExpiredWidget> createState() => 
//       _CancellationDeadlineHasExpiredWidgetState();
// }

// class _CancellationDeadlineHasExpiredWidgetState 
//     extends State<CancellationDeadlineHasExpiredWidget>
//     with TickerProviderStateMixin {
//   late AnimationController _pulseController;
//   late AnimationController _warningController;
//   late AnimationController _clockController;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _warningAnimation;
//   late Animation<double> _clockAnimation;
  
//   Timer? _countdownTimer;
//   Duration _remainingTime = Duration.zero;

//   @override
//   void initState() {
//     super.initState();
    
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _warningController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _clockController = AnimationController(
//       duration: const Duration(seconds: 60),
//       vsync: this,
//     )..repeat();
    
//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.1,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
    
//     _warningAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _warningController,
//       curve: Curves.easeInOut,
//     ));
    
//     _clockAnimation = Tween<double>(
//       begin: 0,
//       end: 2 * math.pi,
//     ).animate(_clockController);
    
//     _startCountdown();
//   }

//   void _startCountdown() {
//     if (!widget.hasExpired) {
//       _updateRemainingTime();
//       _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//         _updateRemainingTime();
//       });
//     }
//   }

//   void _updateRemainingTime() {
//     final now = DateTime.now();
//     setState(() {
//       _remainingTime = widget.deadline.difference(now);
//       if (_remainingTime.isNegative) {
//         _remainingTime = Duration.zero;
//         _countdownTimer?.cancel();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _warningController.dispose();
//     _clockController.dispose();
//     _countdownTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'ar');
    
//     return AnimatedBuilder(
//       animation: widget.hasExpired ? _warningAnimation : _pulseAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: widget.hasExpired ? _warningAnimation.value : 1.0,
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: widget.hasExpired
//                     ? [
//                         AppTheme.error.withOpacity(0.2),
//                         AppTheme.error.withOpacity(0.1),
//                       ]
//                     : [
//                         AppTheme.warning.withOpacity(0.2),
//                         AppTheme.warning.withOpacity(0.1),
//                       ],
//               ),
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(
//                 color: widget.hasExpired 
//                     ? AppTheme.error.withOpacity(0.5)
//                     : AppTheme.warning.withOpacity(0.5),
//                 width: 2,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: (widget.hasExpired ? AppTheme.error : AppTheme.warning)
//                       .withOpacity(0.3),
//                   blurRadius: 20,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                 child: Stack(
//                   children: [
//                     // Animated background pattern
//                     CustomPaint(
//                       painter: _WarningPatternPainter(
//                         animationValue: _clockController.value,
//                         color: widget.hasExpired ? AppTheme.error : AppTheme.warning,
//                       ),
//                       size: Size.infinite,
//                     ),
                    
//                     // Content
//                     Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _buildHeader(),
//                           const SizedBox(height: 20),
                          
//                           if (widget.hasExpired) ...[
//                             _buildExpiredContent(),
//                           ] else ...[
//                             _buildActiveContent(dateFormat),
//                             if (_remainingTime.inDays <= 2) ...[
//                               const SizedBox(height: 20),
//                               _buildTimeRemaining(),
//                             ],
//                           ],
                          
//                           if (widget.policy != null) ...[
//                             const SizedBox(height: 20),
//                             _buildPolicyDetails(),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         AnimatedBuilder(
//           animation: widget.hasExpired ? _warningAnimation : _pulseAnimation,
//           builder: (context, child) {
//             return Transform.scale(
//               scale: widget.hasExpired 
//                   ? _warningAnimation.value 
//                   : _pulseAnimation.value,
//               child: Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: widget.hasExpired
//                         ? [AppTheme.error, AppTheme.error.withOpacity(0.7)]
//                         : [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: (widget.hasExpired ? AppTheme.error : AppTheme.warning)
//                           .withOpacity(0.4),
//                       blurRadius: 15,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   widget.hasExpired ? Icons.cancel : Icons.warning_amber_rounded,
//                   color: Colors.white,
//                   size: 28,
//                 ),
//               ),
//             );
//           },
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ShaderMask(
//                 shaderCallback: (bounds) => LinearGradient(
//                   colors: widget.hasExpired
//                       ? [AppTheme.error, AppTheme.error]
//                       : [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
//                 ).createShader(bounds),
//                 child: Text(
//                   widget.hasExpired
//                       ? 'انتهت مهلة الإلغاء المجاني'
//                       : 'سياسة الإلغاء',
//                   style: AppTextStyles.heading3.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               if (!widget.hasExpired && _remainingTime.inHours <= 24) ...[
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: AppTheme.error.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     'عاجل!',
//                     style: AppTextStyles.caption.copyWith(
//                       color: AppTheme.error,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildExpiredContent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 AppTheme.error.withOpacity(0.1),
//                 AppTheme.error.withOpacity(0.05),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: AppTheme.error.withOpacity(0.3),
//               width: 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 color: AppTheme.error,
//                 size: 24,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'لقد انتهت المهلة المسموح بها للإلغاء المجاني.',
//                       style: AppTextStyles.bodyMedium.copyWith(
//                         color: AppTheme.textWhite,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'في حالة الإلغاء الآن، سيتم تطبيق رسوم إلغاء وفقاً لسياسة العقار.',
//                       style: AppTextStyles.caption.copyWith(
//                         color: AppTheme.textMuted,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActiveContent(DateFormat dateFormat) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'يمكنك إلغاء الحجز مجاناً حتى:',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: AppTheme.textWhite,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 AppTheme.darkCard.withOpacity(0.8),
//                 AppTheme.darkCard.withOpacity(0.5),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: AppTheme.warning.withOpacity(0.3),
//               width: 1,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               AnimatedBuilder(
//                 animation: _clockAnimation,
//                 builder: (context, child) {
//                   return Transform.rotate(
//                     angle: _clockAnimation.value,
//                     child: const Icon(
//                       Icons.access_time,
//                       color: AppTheme.warning,
//                       size: 24,
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(width: 12),
//               ShaderMask(
//                 shaderCallback: (bounds) => LinearGradient(
//                   colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
//                 ).createShader(bounds),
//                 child: Text(
//                   dateFormat.format(widget.deadline),
//                   style: AppTextStyles.heading3.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTimeRemaining() {
//     String timeText;
//     IconData icon;
//     Color color;
    
//     if (_remainingTime.inHours <= 0) {
//       timeText = 'انتهت المهلة';
//       icon = Icons.timer_off;
//       color = AppTheme.error;
//     } else if (_remainingTime.inHours <= 24) {
//       timeText = 'متبقي ${_remainingTime.inHours} ساعة و ${_remainingTime.inMinutes % 60} دقيقة';
//       icon = Icons.timer;
//       color = AppTheme.error;
//     } else {
//       timeText = 'متبقي ${_remainingTime.inDays} يوم';
//       icon = Icons.calendar_today;
//       color = AppTheme.warning;
//     }

//     return AnimatedBuilder(
//       animation: _pulseAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _pulseAnimation.value,
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   color.withOpacity(0.2),
//                   color.withOpacity(0.1),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: color.withOpacity(0.5),
//                 width: 2,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: color.withOpacity(0.3),
//                   blurRadius: 15,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   icon,
//                   color: color,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   timeText,
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPolicyDetails() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.darkCard.withOpacity(0.6),
//             AppTheme.darkCard.withOpacity(0.3),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(
//                 Icons.policy,
//                 color: AppTheme.primaryBlue,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'تفاصيل السياسة:',
//                 style: AppTextStyles.caption.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: AppTheme.primaryBlue,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             widget.policy!,
//             style: AppTextStyles.caption.copyWith(
//               color: AppTheme.textMuted,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Warning Pattern Painter
// class _WarningPatternPainter extends CustomPainter {
//   final double animationValue;
//   final Color color;
  
//   _WarningPatternPainter({
//     required this.animationValue,
//     required this.color,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
    
//     // Draw animated warning lines
//     for (int i = 0; i < 3; i++) {
//       final offset = animationValue * 20 + (i * 20);
//       paint.color = color.withOpacity(0.05);
      
//       canvas.drawLine(
//         Offset(offset % size.width, 0),
//         Offset((offset - 20) % size.width, size.height),
//         paint,
//       );
//     }
//   }
  
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class CancellationDeadlineHasExpiredWidget extends StatefulWidget {
  final bool hasExpired;
  final DateTime deadline;
  final String? policy;

  const CancellationDeadlineHasExpiredWidget({
    super.key,
    required this.hasExpired,
    required this.deadline,
    this.policy,
  });

  @override
  State<CancellationDeadlineHasExpiredWidget> createState() => 
      _CancellationDeadlineHasExpiredWidgetState();
}

class _CancellationDeadlineHasExpiredWidgetState 
    extends State<CancellationDeadlineHasExpiredWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    if (widget.hasExpired) {
      _pulseController.repeat(reverse: true);
    }
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _startCountdown();
  }

  void _startCountdown() {
    if (!widget.hasExpired) {
      _updateRemainingTime();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemainingTime();
      });
    }
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    setState(() {
      _remainingTime = widget.deadline.difference(now);
      if (_remainingTime.isNegative) {
        _remainingTime = Duration.zero;
        _countdownTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'ar');
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.hasExpired ? _pulseAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: widget.hasExpired
                  ? AppTheme.error.withOpacity(0.05)
                  : AppTheme.warning.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.hasExpired 
                    ? AppTheme.error.withOpacity(0.2)
                    : AppTheme.warning.withOpacity(0.2),
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
                      _buildCompactHeader(),
                      const SizedBox(height: 10),
                      
                      if (widget.hasExpired) ...[
                        _buildExpiredContent(),
                      ] else ...[
                        _buildActiveContent(dateFormat),
                        if (_remainingTime.inDays <= 2) ...[
                          const SizedBox(height: 10),
                          _buildTimeRemaining(),
                        ],
                      ],
                      
                      if (widget.policy != null) ...[
                        const SizedBox(height: 10),
                        _buildPolicyDetails(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (widget.hasExpired ? AppTheme.error : AppTheme.warning)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.hasExpired ? Icons.cancel_rounded : Icons.warning_amber_rounded,
            color: (widget.hasExpired ? AppTheme.error : AppTheme.warning)
                .withOpacity(0.8),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hasExpired
                    ? 'انتهت مهلة الإلغاء المجاني'
                    : 'سياسة الإلغاء',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: (widget.hasExpired ? AppTheme.error : AppTheme.warning)
                      .withOpacity(0.9),
                ),
              ),
              if (!widget.hasExpired && _remainingTime.inHours <= 24) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'عاجل!',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.error.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredContent() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error.withOpacity(0.8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لقد انتهت المهلة المسموح بها للإلغاء المجاني.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'في حالة الإلغاء الآن، سيتم تطبيق رسوم إلغاء وفقاً لسياسة العقار.',
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
    );
  }

  Widget _buildActiveContent(DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'يمكنك إلغاء الحجز مجاناً حتى:',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textWhite.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.warning.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppTheme.warning.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(widget.deadline),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRemaining() {
    String timeText;
    IconData icon;
    Color color;
    
    if (_remainingTime.inHours <= 0) {
      timeText = 'انتهت المهلة';
      icon = Icons.timer_off_rounded;
      color = AppTheme.error.withOpacity(0.8);
    } else if (_remainingTime.inHours <= 24) {
      timeText = 'متبقي ${_remainingTime.inHours} ساعة و ${_remainingTime.inMinutes % 60} دقيقة';
      icon = Icons.timer_rounded;
      color = AppTheme.error.withOpacity(0.8);
    } else {
      timeText = 'متبقي ${_remainingTime.inDays} يوم';
      icon = Icons.calendar_today_rounded;
      color = AppTheme.warning.withOpacity(0.8);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            timeText,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetails() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.policy_rounded,
                color: AppTheme.primaryBlue.withOpacity(0.7),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'تفاصيل السياسة:',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.policy!,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}