// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';

// class PaymentMethodsWidget extends StatefulWidget {
//   final String? selectedMethod;
//   final Function(String) onMethodSelected;

//   const PaymentMethodsWidget({
//     super.key,
//     this.selectedMethod,
//     required this.onMethodSelected,
//   });

//   @override
//   State<PaymentMethodsWidget> createState() => _PaymentMethodsWidgetState();
// }

// class _PaymentMethodsWidgetState extends State<PaymentMethodsWidget>
//     with TickerProviderStateMixin {
//   final List<Map<String, dynamic>> _paymentMethods = [
//     {
//       'id': 'cash',
//       'name': 'الدفع نقداً عند الوصول',
//       'description': 'ادفع مباشرة عند تسجيل الوصول',
//       'icon': Icons.money,
//       'color': const Color(0xFF4CAF50),
//       'available': true,
//       'popular': true,
//     },
//     {
//       'id': 'card',
//       'name': 'بطاقة الائتمان / الخصم',
//       'description': 'Visa, Mastercard, American Express',
//       'icon': Icons.credit_card,
//       'color': const Color(0xFF2196F3),
//       'available': true,
//       'popular': false,
//     },
//     {
//       'id': 'wallet',
//       'name': 'المحفظة الإلكترونية',
//       'description': 'فلوسي، كاش، موبي كاش',
//       'icon': Icons.account_balance_wallet,
//       'color': const Color(0xFF9C27B0),
//       'available': true,
//       'popular': true,
//     },
//     {
//       'id': 'bank',
//       'name': 'التحويل البنكي',
//       'description': 'تحويل مباشر من حسابك البنكي',
//       'icon': Icons.account_balance,
//       'color': const Color(0xFFFF9800),
//       'available': true,
//       'popular': false,
//     },
//     {
//       'id': 'paypal',
//       'name': 'PayPal',
//       'description': 'ادفع باستخدام حساب PayPal',
//       'icon': Icons.payment,
//       'color': const Color(0xFF00457C),
//       'available': false,
//       'popular': false,
//     },
//   ];

//   final Map<String, AnimationController> _animationControllers = {};
//   final Map<String, Animation<double>> _scaleAnimations = {};
//   late AnimationController _shimmerController;

//   @override
//   void initState() {
//     super.initState();
    
//     _shimmerController = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     )..repeat();
    
//     for (var method in _paymentMethods) {
//       _animationControllers[method['id']] = AnimationController(
//         duration: const Duration(milliseconds: 300),
//         vsync: this,
//       );
      
//       _scaleAnimations[method['id']] = Tween<double>(
//         begin: 1.0,
//         end: 1.05,
//       ).animate(CurvedAnimation(
//         parent: _animationControllers[method['id']]!,
//         curve: Curves.easeOutBack,
//       ));
//     }
//   }

//   @override
//   void dispose() {
//     _shimmerController.dispose();
//     _animationControllers.forEach((key, controller) {
//       controller.dispose();
//     });
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: _paymentMethods.map((method) {
//         final isSelected = widget.selectedMethod == method['id'];
//         final isAvailable = method['available'] as bool;
//         final isPopular = method['popular'] as bool;
//         final controller = _animationControllers[method['id']]!;
//         final scaleAnimation = _scaleAnimations[method['id']]!;
        
//         if (isSelected && !controller.isCompleted) {
//           controller.forward();
//         } else if (!isSelected && controller.isCompleted) {
//           controller.reverse();
//         }
        
//         return AnimatedBuilder(
//           animation: scaleAnimation,
//           builder: (context, child) {
//             return Transform.scale(
//               scale: scaleAnimation.value,
//               child: Opacity(
//                 opacity: isAvailable ? 1.0 : 0.5,
//                 child: GestureDetector(
//                   onTap: isAvailable 
//                       ? () {
//                           HapticFeedback.lightImpact();
//                           widget.onMethodSelected(method['id']);
//                         }
//                       : null,
//                   child: Container(
//                     margin: const EdgeInsets.only(bottom: 16),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: isSelected
//                             ? [
//                                 method['color'].withOpacity(0.2),
//                                 method['color'].withOpacity(0.1),
//                               ]
//                             : [
//                                 AppTheme.darkCard.withOpacity(0.8),
//                                 AppTheme.darkCard.withOpacity(0.5),
//                               ],
//                       ),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: isSelected
//                             ? method['color'].withOpacity(0.5)
//                             : AppTheme.darkBorder.withOpacity(0.3),
//                         width: isSelected ? 2 : 1,
//                       ),
//                       boxShadow: isSelected
//                           ? [
//                               BoxShadow(
//                                 color: method['color'].withOpacity(0.3),
//                                 blurRadius: 20,
//                                 spreadRadius: 2,
//                               ),
//                             ]
//                           : [],
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                         child: Stack(
//                           children: [
//                             // Shimmer effect for selected
//                             if (isSelected)
//                               AnimatedBuilder(
//                                 animation: _shimmerController,
//                                 builder: (context, child) {
//                                   return Positioned.fill(
//                                     child: CustomPaint(
//                                       painter: _PaymentShimmerPainter(
//                                         animationValue: _shimmerController.value,
//                                         color: method['color'],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
                            
//                             // Content
//                             Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Row(
//                                 children: [
//                                   _buildSelectionIndicator(isSelected, method['color']),
//                                   const SizedBox(width: 16),
//                                   _buildMethodIcon(method, isSelected),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Text(
//                                               method['name'],
//                                               style: AppTextStyles.bodyMedium.copyWith(
//                                                 fontWeight: FontWeight.bold,
//                                                 color: isSelected
//                                                     ? AppTheme.textWhite
//                                                     : AppTheme.textWhite.withOpacity(0.9),
//                                               ),
//                                             ),
//                                             if (isPopular) ...[
//                                               const SizedBox(width: 8),
//                                               _buildPopularBadge(),
//                                             ],
//                                             if (!isAvailable) ...[
//                                               const SizedBox(width: 8),
//                                               _buildUnavailableBadge(),
//                                             ],
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           method['description'],
//                                           style: AppTextStyles.caption.copyWith(
//                                             color: AppTheme.textMuted,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   if (isSelected)
//                                     Container(
//                                       padding: const EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             method['color'],
//                                             method['color'].withOpacity(0.7),
//                                           ],
//                                         ),
//                                         shape: BoxShape.circle,
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: method['color'].withOpacity(0.4),
//                                             blurRadius: 10,
//                                             spreadRadius: 1,
//                                           ),
//                                         ],
//                                       ),
//                                       child: const Icon(
//                                         Icons.check,
//                                         color: Colors.white,
//                                         size: 16,
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildSelectionIndicator(bool isSelected, Color color) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: 24,
//       height: 24,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: isSelected
//             ? LinearGradient(
//                 colors: [color, color.withOpacity(0.7)],
//               )
//             : null,
//         border: Border.all(
//           color: isSelected ? Colors.transparent : AppTheme.darkBorder,
//           width: 2,
//         ),
//         boxShadow: isSelected
//             ? [
//                 BoxShadow(
//                   color: color.withOpacity(0.4),
//                   blurRadius: 8,
//                   spreadRadius: 1,
//                 ),
//               ]
//             : [],
//       ),
//       child: isSelected
//           ? const Icon(
//               Icons.check,
//               size: 14,
//               color: Colors.white,
//             )
//           : null,
//     );
//   }

//   Widget _buildMethodIcon(Map<String, dynamic> method, bool isSelected) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isSelected
//               ? [
//                   method['color'].withOpacity(0.3),
//                   method['color'].withOpacity(0.2),
//                 ]
//               : [
//                   method['color'].withOpacity(0.2),
//                   method['color'].withOpacity(0.1),
//                 ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: isSelected
//             ? [
//                 BoxShadow(
//                   color: method['color'].withOpacity(0.3),
//                   blurRadius: 10,
//                   spreadRadius: 1,
//                 ),
//               ]
//             : [],
//       ),
//       child: Icon(
//         method['icon'] as IconData,
//         color: method['color'] as Color,
//         size: 24,
//       ),
//     );
//   }

//   Widget _buildPopularBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         gradient: AppTheme.primaryGradient,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: AppTheme.primaryBlue.withOpacity(0.3),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Text(
//         'الأكثر استخداماً',
//         style: AppTextStyles.caption.copyWith(
//           color: Colors.white,
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildUnavailableBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: AppTheme.darkBorder.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         'غير متاح',
//         style: AppTextStyles.caption.copyWith(
//           color: AppTheme.darkBorder,
//           fontSize: 10,
//         ),
//       ),
//     );
//   }
// }

// // Payment Shimmer Painter
// class _PaymentShimmerPainter extends CustomPainter {
//   final double animationValue;
//   final Color color;
  
//   _PaymentShimmerPainter({
//     required this.animationValue,
//     required this.color,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..shader = LinearGradient(
//         begin: Alignment(-1 + animationValue * 3, -1),
//         end: Alignment(-0.5 + animationValue * 3, 1),
//         colors: [
//           Colors.transparent,
//           color.withOpacity(0.1),
//           Colors.transparent,
//         ],
//       ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
//   }
  
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentMethodsWidget extends StatelessWidget {
  final String? selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodsWidget({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
  });

  final List<Map<String, dynamic>> _paymentMethods = const [
    {
      'id': 'cash',
      'name': 'نقداً عند الوصول',
      'icon': Icons.payments_outlined,
      'color': Color(0xFF4CAF50),
      'available': true,
      'popular': true,
    },
    {
      'id': 'card',
      'name': 'بطاقة بنكية',
      'icon': Icons.credit_card,
      'color': Color(0xFF2196F3),
      'available': true,
      'popular': false,
    },
    {
      'id': 'wallet',
      'name': 'محفظة إلكترونية',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFF9C27B0),
      'available': true,
      'popular': true,
    },
    {
      'id': 'bank',
      'name': 'تحويل بنكي',
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFFFF9800),
      'available': true,
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = selectedMethod == method['id'];
        final isAvailable = method['available'] as bool;
        final isPopular = method['popular'] as bool;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCompactMethodCard(
            method: method,
            isSelected: isSelected,
            isAvailable: isAvailable,
            isPopular: isPopular,
            onTap: isAvailable
                ? () {
                    HapticFeedback.lightImpact();
                    onMethodSelected(method['id']);
                  }
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactMethodCard({
    required Map<String, dynamic> method,
    required bool isSelected,
    required bool isAvailable,
    required bool isPopular,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (method['color'] as Color).withOpacity(0.08)
              : AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (method['color'] as Color).withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? method['color'] as Color
                      : AppTheme.darkBorder.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: method['color'] as Color,
                        ),
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (method['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'] as IconData,
                size: 18,
                color: method['color'] as Color,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Name
            Expanded(
              child: Text(
                method['name'],
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? AppTheme.textWhite 
                      : AppTheme.textLight,
                ),
              ),
            ),
            
            // Popular badge
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'شائع',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}