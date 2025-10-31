import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ServicesSelectorWidget extends StatefulWidget {
  final String propertyId;
  final Function(List<Map<String, dynamic>>) onServicesChanged;

  const ServicesSelectorWidget({
    super.key,
    required this.propertyId,
    required this.onServicesChanged,
  });

  @override
  State<ServicesSelectorWidget> createState() => _ServicesSelectorWidgetState();
}

class _ServicesSelectorWidgetState extends State<ServicesSelectorWidget>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _services = [
    {
      'id': '1',
      'name': 'خدمة التنظيف اليومية',
      'price': 50.0,
      'description': 'تنظيف الغرفة وترتيبها يومياً',
      'icon': Icons.cleaning_services,
      'color': AppTheme.primaryBlue,
    },
    {
      'id': '2',
      'name': 'وجبة الإفطار',
      'price': 30.0,
      'description': 'وجبة إفطار كاملة',
      'icon': Icons.breakfast_dining,
      'color': AppTheme.warning,
    },
    {
      'id': '3',
      'name': 'خدمة النقل من/إلى المطار',
      'price': 100.0,
      'description': 'سيارة خاصة مع سائق',
      'icon': Icons.airport_shuttle,
      'color': AppTheme.primaryPurple,
    },
    {
      'id': '4',
      'name': 'موقف سيارة خاص',
      'price': 20.0,
      'description': 'موقف آمن للسيارة',
      'icon': Icons.local_parking,
      'color': AppTheme.success,
    },
    {
      'id': '5',
      'name': 'واي فاي عالي السرعة',
      'price': 15.0,
      'description': 'انترنت فائق السرعة',
      'icon': Icons.wifi,
      'color': AppTheme.info,
    },
  ];

  final Map<String, bool> _selectedServices = {};
  final Map<String, int> _serviceQuantities = {};
  final Map<String, AnimationController> _animationControllers = {};
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    for (var service in _services) {
      _selectedServices[service['id']] = false;
      _serviceQuantities[service['id']] = 1;
      _animationControllers[service['id']] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _animationControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_isExpanded) ..._services.map((service) => _buildServiceItem(service)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final selectedCount = _selectedServices.values.where((selected) => selected).length;
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _expandController.forward();
          } else {
            _expandController.reverse();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryCyan.withOpacity(0.1),
              AppTheme.primaryCyan.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.room_service,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الخدمات الإضافية',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    selectedCount > 0
                        ? 'تم اختيار $selectedCount خدمة'
                        : 'اختر الخدمات الإضافية (اختياري)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: AppTheme.primaryCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final isSelected = _selectedServices[service['id']] ?? false;
    final quantity = _serviceQuantities[service['id']] ?? 1;
    final animationController = _animationControllers[service['id']]!;
    
    if (isSelected && !animationController.isCompleted) {
      animationController.forward();
    } else if (!isSelected && animationController.isCompleted) {
      animationController.reverse();
    }

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [
                      service['color'].withOpacity(0.2),
                      service['color'].withOpacity(0.1),
                    ]
                  : [
                      AppTheme.darkCard.withOpacity(0.5),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? service['color'].withOpacity(0.5)
                  : AppTheme.darkBorder.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: service['color'].withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedServices[service['id']] = !isSelected;
                  _updateSelectedServices();
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCheckbox(isSelected, service['color']),
                        const SizedBox(width: 12),
                        _buildServiceIcon(service),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['name'],
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppTheme.textWhite
                                      : AppTheme.textWhite.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service['description'],
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  service['color'],
                                  service['color'].withOpacity(0.7),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                '${service['price'].toStringAsFixed(0)} ريال',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isSelected)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: animationController.value * 50,
                        child: animationController.value > 0.5
                            ? _buildQuantitySelector(service, quantity)
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckbox(bool isSelected, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              )
            : null,
        color: !isSelected ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? Colors.transparent : AppTheme.darkBorder,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildServiceIcon(Map<String, dynamic> service) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            service['color'].withOpacity(0.3),
            service['color'].withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        service['icon'],
        color: service['color'],
        size: 20,
      ),
    );
  }

  Widget _buildQuantitySelector(Map<String, dynamic> service, int quantity) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'الكمية:',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.8),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: service['color'].withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onTap: quantity > 1
                      ? () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _serviceQuantities[service['id']] = quantity - 1;
                            _updateSelectedServices();
                          });
                        }
                      : null,
                  color: service['color'],
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    quantity.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: service['color'],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _serviceQuantities[service['id']] = quantity + 1;
                      _updateSelectedServices();
                    });
                  },
                  color: service['color'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null ? color : AppTheme.darkBorder,
          ),
        ),
      ),
    );
  }

  void _updateSelectedServices() {
    final selectedList = <Map<String, dynamic>>[];
    
    _selectedServices.forEach((id, isSelected) {
      if (isSelected) {
        final service = _services.firstWhere((s) => s['id'] == id);
        selectedList.add({
          'id': id,
          'name': service['name'],
          'price': service['price'] * (_serviceQuantities[id] ?? 1),
          'quantity': _serviceQuantities[id] ?? 1,
        });
      }
    });
    
    widget.onServicesChanged(selectedList);
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../../../core/widgets/price_widget.dart';

// class ServicesSelectorWidget extends StatefulWidget {
//   final String propertyId;
//   final Function(List<Map<String, dynamic>>) onServicesChanged;

//   const ServicesSelectorWidget({
//     super.key,
//     required this.propertyId,
//     required this.onServicesChanged,
//   });

//   @override
//   State<ServicesSelectorWidget> createState() => _ServicesSelectorWidgetState();
// }

// class _ServicesSelectorWidgetState extends State<ServicesSelectorWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
  
//   final List<Map<String, dynamic>> _availableServices = [
//     {
//       'id': '1',
//       'name': 'وجبة إفطار',
//       'icon': Icons.breakfast_dining_rounded,
//       'price': 50.0,
//       'color': AppTheme.warning,
//     },
//     {
//       'id': '2',
//       'name': 'موقف سيارة',
//       'icon': Icons.local_parking_rounded,
//       'price': 30.0,
//       'color': AppTheme.primaryBlue,
//     },
//     {
//       'id': '3',
//       'name': 'واي فاي سريع',
//       'icon': Icons.wifi_rounded,
//       'price': 20.0,
//       'color': AppTheme.primaryCyan,
//     },
//     {
//       'id': '4',
//       'name': 'تنظيف يومي',
//       'icon': Icons.cleaning_services_rounded,
//       'price': 40.0,
//       'color': AppTheme.success,
//     },
//   ];
  
//   final List<Map<String, dynamic>> _selectedServices = [];

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeIn,
//     ));
    
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _toggleService(Map<String, dynamic> service) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       final index = _selectedServices.indexWhere((s) => s['id'] == service['id']);
//       if (index >= 0) {
//         _selectedServices.removeAt(index);
//       } else {
//         _selectedServices.add(service);
//       }
//     });
//     widget.onServicesChanged(_selectedServices);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppTheme.darkCard.withOpacity(0.3),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: AppTheme.primaryViolet.withOpacity(0.1),
//             width: 0.5,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.room_service_rounded,
//                         color: AppTheme.primaryViolet.withOpacity(0.7),
//                         size: 14,
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         'اختر الخدمات التي تريدها',
//                         style: AppTextStyles.caption.copyWith(
//                           color: AppTheme.textMuted.withOpacity(0.8),
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   height: 0.5,
//                   color: AppTheme.darkBorder.withOpacity(0.1),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _availableServices.map((service) {
//                       final isSelected = _selectedServices.any((s) => s['id'] == service['id']);
//                       return _buildServiceChip(service, isSelected);
//                     }).toList(),
//                   ),
//                 ),
//                 if (_selectedServices.isNotEmpty) ...[
//                   Container(
//                     height: 0.5,
//                     color: AppTheme.darkBorder.withOpacity(0.1),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'المجموع:',
//                           style: AppTextStyles.caption.copyWith(
//                             color: AppTheme.textMuted.withOpacity(0.7),
//                           ),
//                         ),
//                         PriceWidget(
//                           price: _selectedServices.fold(0.0, (sum, s) => sum + s['price']),
//                           currency: 'ريال',
//                           displayType: PriceDisplayType.compact,
//                           priceStyle: AppTextStyles.bodySmall.copyWith(
//                             color: AppTheme.primaryViolet.withOpacity(0.9),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceChip(Map<String, dynamic> service, bool isSelected) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//       builder: (context, value, child) {
//         return Transform.scale(
//           scale: 0.9 + (0.1 * value),
//           child: GestureDetector(
//             onTap: () => _toggleService(service),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 gradient: isSelected
//                     ? LinearGradient(
//                         colors: [
//                           (service['color'] as Color).withOpacity(0.2),
//                           (service['color'] as Color).withOpacity(0.1),
//                         ],
//                       )
//                     : null,
//                 color: !isSelected ? AppTheme.darkCard.withOpacity(0.2) : null,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: isSelected
//                       ? (service['color'] as Color).withOpacity(0.3)
//                       : AppTheme.darkBorder.withOpacity(0.1),
//                   width: 0.5,
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     service['icon'] as IconData,
//                     size: 14,
//                     color: isSelected
//                         ? (service['color'] as Color).withOpacity(0.8)
//                         : AppTheme.textMuted.withOpacity(0.5),
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     service['name'],
//                     style: AppTextStyles.caption.copyWith(
//                       color: isSelected
//                           ? AppTheme.textWhite.withOpacity(0.9)
//                           : AppTheme.textMuted.withOpacity(0.6),
//                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                       fontSize: 10,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? (service['color'] as Color).withOpacity(0.1)
//                           : AppTheme.darkBorder.withOpacity(0.05),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       '${service['price'].toStringAsFixed(0)} ريال',
//                       style: AppTextStyles.caption.copyWith(
//                         color: isSelected
//                             ? (service['color'] as Color).withOpacity(0.9)
//                             : AppTheme.textMuted.withOpacity(0.5),
//                         fontSize: 9,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   if (isSelected) ...[
//                     const SizedBox(width: 4),
//                     Icon(
//                       Icons.check_circle_rounded,
//                       size: 12,
//                       color: (service['color'] as Color).withOpacity(0.8),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }