import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PropertyMapPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final double latitude;
  final double longitude;
  final String address;

  const PropertyMapPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  State<PropertyMapPage> createState() => _PropertyMapPageState();
}

class _PropertyMapPageState extends State<PropertyMapPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polyline> _polylines = {};
  
  bool _showNearbyPlaces = false;
  String _selectedCategory = 'all';
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<NearbyPlace> _nearbyPlaces = [];
  final List<_MapParticle> _particles = [];
  
  Timer? _locationUpdateTimer;
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMarkers();
    _generateParticles();
    _startAnimations();
    _startLocationUpdates();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }
  
  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_MapParticle());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
  }
  
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Simulate location updates
      _updateUserLocation();
    });
  }
  
  void _updateUserLocation() {
    // Simulate user location
    setState(() {
      _currentUserLocation = LatLng(
        widget.latitude + (math.Random().nextDouble() - 0.5) * 0.01,
        widget.longitude + (math.Random().nextDouble() - 0.5) * 0.01,
      );
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('property'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(
          title: widget.propertyName,
          snippet: widget.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Map with futuristic overlay
          _buildFuturisticMap(),
          
          // Animated overlays
          _buildMapOverlays(),
          
          // Top bar
          _buildFuturisticAppBar(),
          
          // Map controls
          _buildFuturisticMapControls(),
          
          // Nearby places panel
          if (_showNearbyPlaces) _buildFuturisticNearbyPlacesPanel(),
          
          // Location info card
          _buildLocationInfoCard(),
        ],
      ),
    );
  }
  
  Widget _buildFuturisticMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        _setFuturisticMapStyle();
        _addAnimatedElements();
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.latitude, widget.longitude),
        zoom: 15,
        tilt: 45,
        bearing: 30,
      ),
      mapType: _currentMapType,
      markers: _markers,
      circles: _buildAnimatedCircles(),
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      buildingsEnabled: true,
      trafficEnabled: false,
    );
  }
  
  void _setFuturisticMapStyle() {
    const String mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {"color": "#1d2c4d"}
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#8ec3b9"}
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {"color": "#1a3646"}
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {"color": "#304a7d"}
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#98a5be"}
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {"color": "#023e8a"}
        ]
      }
    ]
    ''';
    
    _mapController?.setMapStyle(mapStyle);
  }
  
  Set<Circle> _buildAnimatedCircles() {
    return {
      // Main pulse circle
      Circle(
        circleId: const CircleId('property_pulse'),
        center: LatLng(widget.latitude, widget.longitude),
        radius: 500 * (1 + _pulseAnimation.value * 0.5),
        fillColor: AppTheme.primaryBlue.withOpacity(0.1 * (1 - _pulseAnimation.value)),
        strokeColor: AppTheme.primaryBlue.withOpacity(0.3 * (1 - _pulseAnimation.value)),
        strokeWidth: 2,
      ),
      // Inner circle
      Circle(
        circleId: const CircleId('property_inner'),
        center: LatLng(widget.latitude, widget.longitude),
        radius: 200,
        fillColor: AppTheme.primaryBlue.withOpacity(0.2),
        strokeColor: AppTheme.primaryBlue.withOpacity(0.5),
        strokeWidth: 3,
      ),
      // Rotating scanner circle
      Circle(
        circleId: const CircleId('property_scanner'),
        center: LatLng(widget.latitude, widget.longitude),
        radius: 300 * (1 + math.sin(_rotationAnimation.value) * 0.2),
        fillColor: AppTheme.primaryCyan.withOpacity(0.05),
        strokeColor: AppTheme.primaryCyan.withOpacity(0.3),
        strokeWidth: 1,
      ),
    };
  }
  
  void _addAnimatedElements() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Update animated elements
        });
      }
    });
  }
  
  Widget _buildMapOverlays() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _MapOverlayPainter(
              particles: _particles,
              animationValue: _rotationAnimation.value,
              glowIntensity: _glowController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildFuturisticAppBar() {
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
              AppTheme.darkBackground.withOpacity(0.9),
              AppTheme.darkBackground.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildGlassButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => 
                                AppTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              'الموقع على الخريطة',
                              style: AppTextStyles.heading3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            widget.propertyName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildGlassButton(
                      icon: _currentMapType == MapType.normal
                          ? Icons.satellite_outlined
                          : Icons.map_outlined,
                      onPressed: _toggleMapType,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticMapControls() {
    return Positioned(
      right: 20,
      bottom: 200,
      child: Column(
        children: [
          _buildMapControlButton(
            icon: Icons.add,
            onPressed: _zoomIn,
            gradient: AppTheme.primaryGradient,
          ),
          const SizedBox(height: 12),
          _buildMapControlButton(
            icon: Icons.remove,
            onPressed: _zoomOut,
            gradient: LinearGradient(
              colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
            ),
          ),
          const SizedBox(height: 20),
          _buildMapControlButton(
            icon: Icons.my_location,
            onPressed: _goToMyLocation,
            gradient: LinearGradient(
              colors: [AppTheme.primaryCyan, AppTheme.neonBlue],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _showNearbyPlaces
                          ? AppTheme.primaryBlue.withOpacity(0.4 * _glowController.value)
                          : Colors.transparent,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _buildMapControlButton(
                  icon: Icons.place_outlined,
                  onPressed: () {
                    setState(() {
                      _showNearbyPlaces = !_showNearbyPlaces;
                    });
                    if (_showNearbyPlaces) {
                      _loadNearbyPlaces();
                      _slideController.forward();
                    } else {
                      _slideController.reverse();
                    }
                    HapticFeedback.mediumImpact();
                  },
                  gradient: _showNearbyPlaces
                      ? AppTheme.primaryGradient
                      : null,
                  isActive: _showNearbyPlaces,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMapControlButton(
            icon: Icons.directions,
            onPressed: _getDirections,
            gradient: LinearGradient(
              colors: [AppTheme.success, AppTheme.neonGreen],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    LinearGradient? gradient,
    bool isActive = false,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient ?? 
            (isActive ? AppTheme.primaryGradient : null),
        color: gradient == null && !isActive
            ? AppTheme.darkCard.withOpacity(0.8)
            : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: gradient != null || isActive
              ? Colors.transparent
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient != null
                ? gradient.colors[0].withOpacity(0.3)
                : AppTheme.shadowDark.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onPressed();
                HapticFeedback.lightImpact();
              },
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticNearbyPlacesPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkSurface,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  _buildPanelHeader(),
                  _buildCategoryFilter(),
                  Expanded(
                    child: _buildPlacesList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => 
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'الأماكن القريبة',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildGlassButton(
                icon: Icons.close,
                onPressed: () {
                  setState(() {
                    _showNearbyPlaces = false;
                  });
                  _slideController.reverse();
                },
                size: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'name': 'الكل', 'icon': Icons.apps, 'color': AppTheme.primaryBlue},
      {'id': 'restaurant', 'name': 'مطاعم', 'icon': Icons.restaurant, 'color': AppTheme.primaryViolet},
      {'id': 'cafe', 'name': 'مقاهي', 'icon': Icons.coffee, 'color': Colors.brown},
      {'id': 'shopping', 'name': 'تسوق', 'icon': Icons.shopping_bag, 'color': AppTheme.primaryPurple},
      {'id': 'hospital', 'name': 'مستشفيات', 'icon': Icons.local_hospital, 'color': AppTheme.error},
      {'id': 'atm', 'name': 'صراف', 'icon': Icons.atm, 'color': AppTheme.success},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
              _filterPlaces();
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          (category['color'] as Color),
                          (category['color'] as Color).withOpacity(0.7),
                        ],
                      )
                    : null,
                color: !isSelected
                    ? AppTheme.darkCard.withOpacity(0.5)
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (category['color'] as Color).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 20,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_nearbyPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: AppTheme.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد أماكن قريبة',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _nearbyPlaces.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final place = _nearbyPlaces[index];
        return _buildFuturisticPlaceItem(place, index);
      },
    );
  }

  Widget _buildFuturisticPlaceItem(NearbyPlace place, int index) {
    return GestureDetector(
      onTap: () => _showPlaceOnMap(place),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.8),
              AppTheme.darkCard.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(place.category),
                    _getCategoryColor(place.category).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getCategoryColor(place.category).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                _getCategoryIcon(place.category),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${place.distance.toStringAsFixed(1)} كم',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${place.walkingTime} دقيقة',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildGlassButton(
              icon: Icons.directions,
              onPressed: () => _getDirectionsToPlace(place),
              size: 40,
              gradient: AppTheme.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationInfoCard() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2 * _glowController.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.propertyName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.address,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.directions,
                            label: 'الاتجاهات',
                            onTap: _openDirections,
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.share_location,
                            label: 'مشاركة',
                            onTap: _shareLocation,
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors[0].withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
            HapticFeedback.mediumImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 48,
    LinearGradient? gradient,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 3),
        border: Border.all(
          color: gradient != null
              ? Colors.transparent
              : AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: gradient.colors[0].withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 3),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
    HapticFeedback.lightImpact();
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
    HapticFeedback.lightImpact();
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
    HapticFeedback.lightImpact();
  }

  void _goToMyLocation() {
    if (_currentUserLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentUserLocation!, 16),
      );
    }
    HapticFeedback.mediumImpact();
  }

  void _loadNearbyPlaces() {
    setState(() {
      _nearbyPlaces.clear();
      _nearbyPlaces.addAll([
        NearbyPlace(
          name: 'مطعم الشام',
          category: 'restaurant',
          distance: 0.3,
          walkingTime: 5,
          latitude: widget.latitude + 0.002,
          longitude: widget.longitude + 0.001,
        ),
        NearbyPlace(
          name: 'كافيه السعادة',
          category: 'cafe',
          distance: 0.5,
          walkingTime: 8,
          latitude: widget.latitude - 0.003,
          longitude: widget.longitude + 0.002,
        ),
        NearbyPlace(
          name: 'سوبر ماركت النجمة',
          category: 'shopping',
          distance: 0.8,
          walkingTime: 12,
          latitude: widget.latitude + 0.004,
          longitude: widget.longitude - 0.003,
        ),
        NearbyPlace(
          name: 'مستشفى الأمل',
          category: 'hospital',
          distance: 1.2,
          walkingTime: 18,
          latitude: widget.latitude - 0.005,
          longitude: widget.longitude - 0.004,
        ),
        NearbyPlace(
          name: 'صراف البنك الأهلي',
          category: 'atm',
          distance: 0.2,
          walkingTime: 3,
          latitude: widget.latitude + 0.001,
          longitude: widget.longitude + 0.002,
        ),
      ]);
    });
  }

  void _filterPlaces() {
    // Filter places based on selected category
  }

  void _showPlaceOnMap(NearbyPlace place) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place.latitude, place.longitude),
        17,
      ),
    );

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(place.name),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.distance} كم',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    });
    
    HapticFeedback.mediumImpact();
  }

  void _getDirections() {
    HapticFeedback.heavyImpact();
    // Open directions in maps app
  }

  void _getDirectionsToPlace(NearbyPlace place) {
    HapticFeedback.heavyImpact();
    // Open directions to specific place
  }

  void _openDirections() {
    HapticFeedback.heavyImpact();
    // Open directions
  }

  void _shareLocation() {
    HapticFeedback.mediumImpact();
    // Share location
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'shopping':
        return Icons.shopping_bag;
      case 'hospital':
        return Icons.local_hospital;
      case 'atm':
        return Icons.atm;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'restaurant':
        return AppTheme.primaryViolet;
      case 'cafe':
        return Colors.brown;
      case 'shopping':
        return AppTheme.primaryPurple;
      case 'hospital':
        return AppTheme.error;
      case 'atm':
        return AppTheme.success;
      default:
        return AppTheme.primaryBlue;
    }
  }
}

class NearbyPlace {
  final String name;
  final String category;
  final double distance;
  final int walkingTime;
  final double latitude;
  final double longitude;

  NearbyPlace({
    required this.name,
    required this.category,
    required this.distance,
    required this.walkingTime,
    required this.latitude,
    required this.longitude,
  });
}

// Map particles for visual effects
class _MapParticle {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double opacity;
  
  _MapParticle() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    speed = math.Random().nextDouble() * 0.002 + 0.001;
    size = math.Random().nextDouble() * 3 + 1;
    opacity = math.Random().nextDouble() * 0.3 + 0.1;
  }
  
  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class _MapOverlayPainter extends CustomPainter {
  final List<_MapParticle> particles;
  final double animationValue;
  final double glowIntensity;
  
  _MapOverlayPainter({
    required this.particles,
    required this.animationValue,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw particles
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = AppTheme.primaryBlue.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
    
    // Draw scan line effect
    final scanY = (animationValue * size.height) % size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppTheme.primaryCyan.withOpacity(0.3 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 50, size.width, 100))
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 50, size.width, 100),
      scanPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}