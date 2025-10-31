// import 'package:flutter/material.dart';
// import '../../../../core/utils/image_utils.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'dart:ui';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../domain/entities/search_result.dart';

// class SearchResultsMapPage extends StatefulWidget {
//   final List<SearchResult> results;
//   final VoidCallback? onBackToList;

//   const SearchResultsMapPage({
//     super.key,
//     required this.results,
//     this.onBackToList,
//   });

//   @override
//   State<SearchResultsMapPage> createState() => _SearchResultsMapPageState();
// }

// class _SearchResultsMapPageState extends State<SearchResultsMapPage>
//     with TickerProviderStateMixin {
//   GoogleMapController? _mapController;
//   Set<Marker> _markers = {};
//   String? _selectedMarkerId;
//   final PageController _pageController = PageController(viewportFraction: 0.9);
  
//   // Animation Controllers
//   late AnimationController _cardAnimationController;
//   late AnimationController _fabAnimationController;
//   late Animation<double> _cardSlideAnimation;
//   late Animation<double> _fabScaleAnimation;
  
//   // Yemen coordinates (Sana'a)
//   static const LatLng _defaultLocation = LatLng(15.3694, 44.1910);
  
//   // Map Style
//   static const String _mapStyle = '''
//   [
//     {
//       "elementType": "geometry",
//       "stylers": [{"color": "#1d2c4d"}]
//     },
//     {
//       "elementType": "labels.text.fill",
//       "stylers": [{"color": "#8ec3b9"}]
//     },
//     {
//       "elementType": "labels.text.stroke",
//       "stylers": [{"color": "#1a3646"}]
//     },
//     {
//       "featureType": "poi",
//       "elementType": "labels",
//       "stylers": [{"visibility": "off"}]
//     },
//     {
//       "featureType": "road",
//       "elementType": "geometry",
//       "stylers": [{"color": "#304a7d"}]
//     },
//     {
//       "featureType": "road",
//       "elementType": "geometry.stroke",
//       "stylers": [{"color": "#255763"}]
//     },
//     {
//       "featureType": "water",
//       "elementType": "geometry",
//       "stylers": [{"color": "#0e1626"}]
//     }
//   ]
//   ''';

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _initializeMarkers();
//   }
  
//   void _initializeAnimations() {
//     _cardAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
    
//     _fabAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     )..forward();
    
//     _cardSlideAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.0,
//     ).animate(CurvedAnimation(
//       parent: _cardAnimationController,
//       curve: Curves.easeOutQuart,
//     ));
    
//     _fabScaleAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fabAnimationController,
//       curve: Curves.elasticOut,
//     ));
    
//     _cardAnimationController.forward();
//   }

//   @override
//   void dispose() {
//     _mapController?.dispose();
//     _pageController.dispose();
//     _cardAnimationController.dispose();
//     _fabAnimationController.dispose();
//     super.dispose();
//   }

//   void _initializeMarkers() {
//     _markers = widget.results.map((result) {
//       return Marker(
//         markerId: MarkerId(result.id),
//         position: LatLng(result.latitude, result.longitude),
//         onTap: () => _onMarkerTapped(result),
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//           _selectedMarkerId == result.id
//               ? BitmapDescriptor.hueBlue
//               : BitmapDescriptor.hueRed,
//         ),
//         infoWindow: InfoWindow(
//           title: result.name,
//           snippet: '${result.minPrice} ${result.currency}',
//         ),
//       );
//     }).toSet();
//   }

//   void _onMarkerTapped(SearchResult result) {
//     setState(() {
//       _selectedMarkerId = result.id;
//       _initializeMarkers();
//     });
    
//     final index = widget.results.indexWhere((r) => r.id == result.id);
//     if (index != -1) {
//       _pageController.animateToPage(
//         index,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void _onPropertyCardTapped(SearchResult result) {
//     setState(() {
//       _selectedMarkerId = result.id;
//       _initializeMarkers();
//     });
    
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(
//         LatLng(result.latitude, result.longitude),
//         15,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           _buildMap(),
//           _buildTopBar(),
//           _buildPropertyCards(),
//           _buildMapControls(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMap() {
//     return GoogleMap(
//       onMapCreated: (controller) {
//         _mapController = controller;
//         controller.setMapStyle(_mapStyle);
//       },
//       initialCameraPosition: CameraPosition(
//         target: _calculateCenter(),
//         zoom: 12,
//       ),
//       markers: _markers,
//       myLocationEnabled: true,
//       myLocationButtonEnabled: false,
//       zoomControlsEnabled: false,
//       mapToolbarEnabled: false,
//       compassEnabled: false,
//     );
//   }

//   Widget _buildTopBar() {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               AppTheme.darkBackground.withOpacity(0.9),
//               AppTheme.darkBackground.withOpacity(0.7),
//               AppTheme.darkBackground.withOpacity(0.0),
//             ],
//           ),
//         ),
//         child: ClipRRect(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     _buildCircularButton(
//                       icon: Icons.arrow_back_rounded,
//                       onPressed: widget.onBackToList ?? () => Navigator.pop(context),
//                       isPrimary: true,
//                     ),
//                     const Spacer(),
//                     _buildCircularButton(
//                       icon: Icons.layers_rounded,
//                       onPressed: _showMapTypeSelector,
//                     ),
//                     const SizedBox(width: 12),
//                     _buildCircularButton(
//                       icon: Icons.filter_list_rounded,
//                       onPressed: _showFilterOptions,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPropertyCards() {
//     if (widget.results.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Positioned(
//       bottom: MediaQuery.of(context).padding.bottom + 20,
//       left: 0,
//       right: 0,
//       height: 150,
//       child: AnimatedBuilder(
//         animation: _cardSlideAnimation,
//         builder: (context, child) {
//           return Transform.translate(
//             offset: Offset(0, 200 * _cardSlideAnimation.value),
//             child: PageView.builder(
//               controller: _pageController,
//               onPageChanged: (index) {
//                 final result = widget.results[index];
//                 _onPropertyCardTapped(result);
//               },
//               itemCount: widget.results.length,
//               itemBuilder: (context, index) {
//                 final result = widget.results[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: _MapPropertyCard(
//                     result: result,
//                     isSelected: _selectedMarkerId == result.id,
//                     onTap: () => _onPropertyCardTapped(result),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildMapControls() {
//     return Positioned(
//       right: 16,
//       bottom: 180,
//       child: AnimatedBuilder(
//         animation: _fabScaleAnimation,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: _fabScaleAnimation.value,
//             child: Column(
//               children: [
//                 _buildCircularButton(
//                   icon: Icons.add_rounded,
//                   onPressed: _zoomIn,
//                   size: 48,
//                 ),
//                 const SizedBox(height: 12),
//                 _buildCircularButton(
//                   icon: Icons.remove_rounded,
//                   onPressed: _zoomOut,
//                   size: 48,
//                 ),
//                 const SizedBox(height: 20),
//                 _buildCircularButton(
//                   icon: Icons.my_location_rounded,
//                   onPressed: _goToMyLocation,
//                   size: 48,
//                   isPrimary: true,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCircularButton({
//     required IconData icon,
//     required VoidCallback onPressed,
//     double size = 52,
//     bool isPrimary = false,
//   }) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         gradient: isPrimary
//             ? AppTheme.primaryGradient
//             : LinearGradient(
//                 colors: [
//                   AppTheme.darkCard.withOpacity(0.9),
//                   AppTheme.darkCard.withOpacity(0.7),
//                 ],
//               ),
//         shape: BoxShape.circle,
//         border: Border.all(
//           color: isPrimary
//               ? Colors.transparent
//               : AppTheme.darkBorder.withOpacity(0.3),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: isPrimary
//                 ? AppTheme.primaryBlue.withOpacity(0.4)
//                 : AppTheme.shadowDark.withOpacity(0.5),
//             blurRadius: isPrimary ? 20 : 15,
//             spreadRadius: isPrimary ? 2 : 1,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(size / 2),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: onPressed,
//               child: Icon(
//                 icon,
//                 size: size * 0.45,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   LatLng _calculateCenter() {
//     if (widget.results.isEmpty) {
//       return _defaultLocation;
//     }

//     double sumLat = 0;
//     double sumLng = 0;

//     for (final result in widget.results) {
//       sumLat += result.latitude;
//       sumLng += result.longitude;
//     }

//     return LatLng(
//       sumLat / widget.results.length,
//       sumLng / widget.results.length,
//     );
//   }

//   void _zoomIn() {
//     _mapController?.animateCamera(CameraUpdate.zoomIn());
//   }

//   void _zoomOut() {
//     _mapController?.animateCamera(CameraUpdate.zoomOut());
//   }

//   void _goToMyLocation() {
//     // Implement go to current location
//     // You can use location package to get current location
//     // For now, we'll zoom to default location
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(_defaultLocation, 15),
//     );
//   }

//   void _showMapTypeSelector() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return _MapTypeSelector(
//           onSelectType: (type) {
//             Navigator.pop(context);
//             _changeMapType(type);
//           },
//         );
//       },
//     );
//   }

//   void _changeMapType(String type) {
//     // Change map type based on selection
//     MapType mapType;
//     switch (type) {
//       case 'satellite':
//         mapType = MapType.satellite;
//         break;
//       case 'terrain':
//         mapType = MapType.terrain;
//         break;
//       case 'hybrid':
//         mapType = MapType.hybrid;
//         break;
//       default:
//         mapType = MapType.normal;
//     }
    
//     // Update map type through controller
//     setState(() {
//       // You would need to recreate the map with new type
//       // or use a state variable to control map type
//     });
//   }

//   void _showFilterOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return _MapFilterOptions(
//           onApplyFilters: (filters) {
//             Navigator.pop(context);
//             // Apply filters to map
//             _applyMapFilters(filters);
//           },
//         );
//       },
//     );
//   }

//   void _applyMapFilters(Map<String, dynamic> filters) {
//     // Apply filters and update markers
//     setState(() {
//       // Filter results based on criteria
//     });
//   }
// }

// // Map Property Card Widget
// class _MapPropertyCard extends StatelessWidget {
//   final SearchResult result;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _MapPropertyCard({
//     required this.result,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isSelected
//                 ? [
//                     AppTheme.primaryBlue.withOpacity(0.2),
//                     AppTheme.primaryPurple.withOpacity(0.1),
//                   ]
//                 : [
//                     AppTheme.darkCard.withOpacity(0.95),
//                     AppTheme.darkCard.withOpacity(0.85),
//                   ],
//           ),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected 
//                 ? AppTheme.primaryBlue.withOpacity(0.5)
//                 : AppTheme.darkBorder.withOpacity(0.3),
//             width: isSelected ? 2 : 1,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: isSelected
//                   ? AppTheme.primaryBlue.withOpacity(0.3)
//                   : AppTheme.shadowDark.withOpacity(0.5),
//               blurRadius: isSelected ? 25 : 20,
//               spreadRadius: isSelected ? 3 : 1,
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//             child: Row(
//               children: [
//                 // Property Image
//                 Container(
//                   width: 130,
//                   decoration: BoxDecoration(
//                     borderRadius: const BorderRadius.horizontal(
//                       right: Radius.circular(20),
//                     ),
//                     image: DecorationImage(
//                       image: NetworkImage(ImageUtils.resolveUrl(result.mainImageUrl ?? '')),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   child: Stack(
//                     children: [
//                       // Gradient Overlay
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: const BorderRadius.horizontal(
//                             right: Radius.circular(20),
//                           ),
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [
//                               Colors.transparent,
//                               AppTheme.darkBackground.withOpacity(0.7),
//                             ],
//                           ),
//                         ),
//                       ),
                      
//                       // Featured Badge
//                       if (result.isFeatured)
//                         Positioned(
//                           top: 12,
//                           right: 12,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               gradient: AppTheme.primaryGradient,
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: AppTheme.primaryBlue.withOpacity(0.5),
//                                   blurRadius: 10,
//                                   spreadRadius: 1,
//                                 ),
//                               ],
//                             ),
//                             child: Text(
//                               'مميز',
//                               style: AppTextStyles.overline.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
                
//                 // Property Details
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         Text(
//                           result.name,
//                           style: AppTextStyles.bodyMedium.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: isSelected
//                                 ? AppTheme.primaryBlue
//                                 : AppTheme.textWhite,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
                        
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.location_on_outlined,
//                               size: 14,
//                               color: AppTheme.textMuted.withOpacity(0.7),
//                             ),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 result.address,
//                                 style: AppTextStyles.caption.copyWith(
//                                   color: AppTheme.textMuted,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
                        
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: AppTheme.warning.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Icon(
//                                     Icons.star_rounded,
//                                     size: 14,
//                                     color: AppTheme.warning,
//                                   ),
//                                   const SizedBox(width: 2),
//                                   Text(
//                                     result.averageRating.toStringAsFixed(1),
//                                     style: AppTextStyles.caption.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: AppTheme.warning,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
                            
//                             const Spacer(),
                            
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 if (result.minPrice != result.discountedPrice)
//                                   Text(
//                                     '${result.minPrice.toStringAsFixed(0)} ${result.currency}',
//                                     style: AppTextStyles.overline.copyWith(
//                                       decoration: TextDecoration.lineThrough,
//                                       color: AppTheme.textMuted.withOpacity(0.7),
//                                     ),
//                                   ),
//                                 ShaderMask(
//                                   shaderCallback: (bounds) => 
//                                       AppTheme.primaryGradient.createShader(bounds),
//                                   child: Text(
//                                     '${result.discountedPrice.toStringAsFixed(0)} ${result.currency}',
//                                     style: AppTextStyles.bodyMedium.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Map Type Selector Widget
// class _MapTypeSelector extends StatelessWidget {
//   final Function(String) onSelectType;

//   const _MapTypeSelector({required this.onSelectType});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             AppTheme.darkCard.withOpacity(0.95),
//             AppTheme.darkSurface,
//           ],
//         ),
//         borderRadius: const BorderRadius.vertical(
//           top: Radius.circular(28),
//         ),
//         border: Border.all(
//           color: AppTheme.darkBorder.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(
//           top: Radius.circular(28),
//         ),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: SafeArea(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.only(top: 12),
//                   width: 50,
//                   height: 5,
//                   decoration: BoxDecoration(
//                     gradient: AppTheme.primaryGradient,
//                     borderRadius: BorderRadius.circular(3),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppTheme.primaryBlue.withOpacity(0.5),
//                         blurRadius: 10,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Text(
//                     'نوع الخريطة',
//                     style: AppTextStyles.heading3.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
                
//                 _buildMapTypeOption(
//                   title: 'عادية',
//                   subtitle: 'خريطة الشوارع الافتراضية',
//                   icon: Icons.map_outlined,
//                   onTap: () => onSelectType('normal'),
//                 ),
                
//                 _buildMapTypeOption(
//                   title: 'قمر صناعي',
//                   subtitle: 'صور الأقمار الصناعية',
//                   icon: Icons.satellite_outlined,
//                   onTap: () => onSelectType('satellite'),
//                 ),
                
//                 _buildMapTypeOption(
//                   title: 'تضاريس',
//                   subtitle: 'خريطة طبوغرافية',
//                   icon: Icons.terrain_outlined,
//                   onTap: () => onSelectType('terrain'),
//                 ),
                
//                 _buildMapTypeOption(
//                   title: 'هجين',
//                   subtitle: 'قمر صناعي مع الشوارع',
//                   icon: Icons.layers_outlined,
//                   onTap: () => onSelectType('hybrid'),
//                 ),
                
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildMapTypeOption({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           child: Row(
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   gradient: AppTheme.primaryGradient,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppTheme.primaryBlue.withOpacity(0.3),
//                       blurRadius: 15,
//                       spreadRadius: 1,
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   icon,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: AppTextStyles.bodyMedium.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       subtitle,
//                       style: AppTextStyles.caption.copyWith(
//                         color: AppTheme.textMuted,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_ios_rounded,
//                 size: 16,
//                 color: AppTheme.textMuted.withOpacity(0.5),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Map Filter Options Widget
// class _MapFilterOptions extends StatefulWidget {
//   final Function(Map<String, dynamic>) onApplyFilters;

//   const _MapFilterOptions({required this.onApplyFilters});

//   @override
//   State<_MapFilterOptions> createState() => _MapFilterOptionsState();
// }

// class _MapFilterOptionsState extends State<_MapFilterOptions> {
//   double _radiusKm = 5.0;
//   bool _showFeatured = false;
//   bool _showAvailable = true;
//   String? _selectedPropertyType;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             AppTheme.darkCard.withOpacity(0.95),
//             AppTheme.darkSurface,
//           ],
//         ),
//         borderRadius: const BorderRadius.vertical(
//           top: Radius.circular(28),
//         ),
//         border: Border.all(
//           color: AppTheme.darkBorder.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(
//           top: Radius.circular(28),
//         ),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: SafeArea(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.only(top: 12),
//                   width: 50,
//                   height: 5,
//                   decoration: BoxDecoration(
//                     gradient: AppTheme.primaryGradient,
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
                
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Text(
//                     'فلاتر الخريطة',
//                     style: AppTextStyles.heading3.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
                
//                 // Radius Slider
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'نطاق البحث',
//                             style: AppTextStyles.bodyMedium.copyWith(
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               gradient: AppTheme.primaryGradient,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '${_radiusKm.toStringAsFixed(1)} كم',
//                               style: AppTextStyles.caption.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       SliderTheme(
//                         data: SliderThemeData(
//                           activeTrackColor: AppTheme.primaryBlue,
//                           inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.2),
//                           thumbColor: AppTheme.primaryBlue,
//                           overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
//                         ),
//                         child: Slider(
//                           value: _radiusKm,
//                           min: 1,
//                           max: 20,
//                           onChanged: (value) {
//                             setState(() {
//                               _radiusKm = value;
//                             });
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 const Divider(color: AppTheme.darkBorder),
                
//                 // Toggle Options
//                 _buildSwitchOption(
//                   title: 'العقارات المميزة فقط',
//                   subtitle: 'عرض العقارات المميزة',
//                   value: _showFeatured,
//                   onChanged: (value) {
//                     setState(() {
//                       _showFeatured = value;
//                     });
//                   },
//                 ),
                
//                 _buildSwitchOption(
//                   title: 'المتاح فقط',
//                   subtitle: 'إخفاء العقارات المحجوزة',
//                   value: _showAvailable,
//                   onChanged: (value) {
//                     setState(() {
//                       _showAvailable = value;
//                     });
//                   },
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 // Apply Button
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Container(
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       gradient: AppTheme.primaryGradient,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppTheme.primaryBlue.withOpacity(0.4),
//                           blurRadius: 20,
//                           spreadRadius: 2,
//                         ),
//                       ],
//                     ),
//                     child: Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         onTap: () {
//                           widget.onApplyFilters({
//                             'radius': _radiusKm,
//                             'featured': _showFeatured,
//                             'available': _showAvailable,
//                             'propertyType': _selectedPropertyType,
//                           });
//                         },
//                         borderRadius: BorderRadius.circular(16),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           child: Text(
//                             'تطبيق الفلاتر',
//                             style: AppTextStyles.buttonLarge.copyWith(
//                               color: Colors.white,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
                
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildSwitchOption({
//     required String title,
//     required String subtitle,
//     required bool value,
//     required Function(bool) onChanged,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppTheme.textMuted,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Switch(
//             value: value,
//             onChanged: onChanged,
//             activeColor: AppTheme.primaryBlue,
//             activeTrackColor: AppTheme.primaryBlue.withOpacity(0.3),
//             inactiveThumbColor: AppTheme.textMuted,
//             inactiveTrackColor: AppTheme.darkCard,
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/image_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/search_result.dart';

class SearchResultsMapPage extends StatefulWidget {
  final List<SearchResult> results;
  final VoidCallback? onBackToList;

  const SearchResultsMapPage({
    super.key,
    required this.results,
    this.onBackToList,
  });

  @override
  State<SearchResultsMapPage> createState() => _SearchResultsMapPageState();
}

class _SearchResultsMapPageState extends State<SearchResultsMapPage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String? _selectedMarkerId;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  static const LatLng _defaultLocation = LatLng(15.3694, 44.1910);
  
  // Minimal map style
  static const String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "featureType": "poi",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#ffffff"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _initializeMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeMarkers() {
    _markers = widget.results.map((result) {
      return Marker(
        markerId: MarkerId(result.id),
        position: LatLng(result.latitude, result.longitude),
        onTap: () => _onMarkerTapped(result),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _selectedMarkerId == result.id
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  void _onMarkerTapped(SearchResult result) {
    setState(() {
      _selectedMarkerId = result.id;
      _initializeMarkers();
    });
    
    final index = widget.results.indexWhere((r) => r.id == result.id);
    if (index != -1) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPropertyCardTapped(SearchResult result) {
    setState(() {
      _selectedMarkerId = result.id;
      _initializeMarkers();
    });
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(result.latitude, result.longitude),
        15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildMinimalTopBar(),
          _buildMinimalPropertyCards(),
          _buildMinimalMapControls(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        controller.setMapStyle(_mapStyle);
      },
      initialCameraPosition: CameraPosition(
        target: _calculateCenter(),
        zoom: 12,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  Widget _buildMinimalTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground.withOpacity(0.7),
              AppTheme.darkBackground.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildMinimalButton(
                  icon: Icons.arrow_back,
                  onPressed: widget.onBackToList ?? () => Navigator.pop(context),
                ),
                const Spacer(),
                _buildMinimalButton(
                  icon: Icons.layers_outlined,
                  onPressed: _showMapTypeSelector,
                ),
                const SizedBox(width: 8),
                _buildMinimalButton(
                  icon: Icons.tune,
                  onPressed: _showFilterOptions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalPropertyCards() {
    if (widget.results.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 0,
      right: 0,
      height: 110,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            final result = widget.results[index];
            _onPropertyCardTapped(result);
          },
          itemCount: widget.results.length,
          itemBuilder: (context, index) {
            final result = widget.results[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MinimalMapPropertyCard(
                result: result,
                isSelected: _selectedMarkerId == result.id,
                onTap: () => _onPropertyCardTapped(result),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMinimalMapControls() {
    return Positioned(
      right: 12,
      bottom: 140,
      child: Column(
        children: [
          _buildMinimalButton(
            icon: Icons.add,
            onPressed: _zoomIn,
            size: 36,
          ),
          const SizedBox(height: 8),
          _buildMinimalButton(
            icon: Icons.remove,
            onPressed: _zoomOut,
            size: 36,
          ),
          const SizedBox(height: 12),
          _buildMinimalButton(
            icon: Icons.my_location,
            onPressed: _goToMyLocation,
            size: 36,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 40,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.primaryBlue.withOpacity(0.9)
              : AppTheme.darkCard.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary
                ? AppTheme.primaryBlue
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: AppTheme.textWhite,
        ),
      ),
    );
  }

  LatLng _calculateCenter() {
    if (widget.results.isEmpty) return _defaultLocation;

    double sumLat = 0;
    double sumLng = 0;

    for (final result in widget.results) {
      sumLat += result.latitude;
      sumLng += result.longitude;
    }

    return LatLng(
      sumLat / widget.results.length,
      sumLng / widget.results.length,
    );
  }

  void _zoomIn() => _mapController?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());
  
  void _goToMyLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_defaultLocation, 15),
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MinimalMapTypeSelector(
        onSelectType: (type) {
          Navigator.pop(context);
          // Handle map type change
        },
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MinimalMapFilterOptions(
        onApplyFilters: (filters) {
          Navigator.pop(context);
          // Apply filters
        },
      ),
    );
  }
}

// Minimal Map Property Card
class _MinimalMapPropertyCard extends StatelessWidget {
  final SearchResult result;
  final bool isSelected;
  final VoidCallback onTap;

  const _MinimalMapPropertyCard({
    required this.result,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(isSelected ? 0.9 : 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.1),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Fixed width image with dynamic height
              SizedBox(
                width: 90,
                child: AspectRatio(
                  aspectRatio: 3/4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12),
                      ),
                      image: (ImageUtils.resolveUrl(result.mainImageUrl ?? '').isEmpty)
                          ? null
                          : DecorationImage(
                              image: NetworkImage(
                                ImageUtils.resolveUrl(result.mainImageUrl ?? ''),
                              ),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        if (result.isFeatured)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'مميز',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 10,
                            color: AppTheme.textMuted.withOpacity(0.6),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              result.address,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 10,
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  result.averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: AppTheme.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (result.minPrice != result.discountedPrice)
                                Text(
                                  '${result.minPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textMuted.withOpacity(0.5),
                                  ),
                                ),
                              Text(
                                '${result.discountedPrice.toStringAsFixed(0)} ${result.currency}',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Minimal Map Type Selector
class _MinimalMapTypeSelector extends StatelessWidget {
  final Function(String) onSelectType;

  const _MinimalMapTypeSelector({required this.onSelectType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkBorder.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'نوع الخريطة',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildOption('عادية', Icons.map_outlined, () => onSelectType('normal')),
            _buildOption('قمر صناعي', Icons.satellite_outlined, () => onSelectType('satellite')),
            _buildOption('تضاريس', Icons.terrain_outlined, () => onSelectType('terrain')),
            _buildOption('هجين', Icons.layers_outlined, () => onSelectType('hybrid')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Icon(icon, size: 20, color: AppTheme.primaryBlue),
      title: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textWhite,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppTheme.textMuted.withOpacity(0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: VisualDensity.compact,
    );
  }
}

// Minimal Map Filter Options
class _MinimalMapFilterOptions extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;

  const _MinimalMapFilterOptions({required this.onApplyFilters});

  @override
  State<_MinimalMapFilterOptions> createState() => _MinimalMapFilterOptionsState();
}

class _MinimalMapFilterOptionsState extends State<_MinimalMapFilterOptions> {
  double _radiusKm = 5.0;
  bool _showFeatured = false;
  bool _showAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkBorder.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'فلاتر الخريطة',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Radius Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نطاق البحث',
                        style: AppTextStyles.bodySmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_radiusKm.toStringAsFixed(1)} كم',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryBlue,
                      inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.2),
                      thumbColor: AppTheme.primaryBlue,
                      overlayColor: AppTheme.primaryBlue.withOpacity(0.1),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: _radiusKm,
                      min: 1,
                      max: 20,
                      onChanged: (value) => setState(() => _radiusKm = value),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Toggle Options
            _buildSwitch('العقارات المميزة فقط', _showFeatured, (v) => setState(() => _showFeatured = v)),
            _buildSwitch('المتاح فقط', _showAvailable, (v) => setState(() => _showAvailable = v)),
            
            const SizedBox(height: 20),
            
            // Apply Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onApplyFilters({
                    'radius': _radiusKm,
                    'featured': _showFeatured,
                    'available': _showAvailable,
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.9),
                        AppTheme.primaryPurple.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'تطبيق',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryBlue,
              activeTrackColor: AppTheme.primaryBlue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}