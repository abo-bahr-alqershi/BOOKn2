// lib/features/admin_properties/presentation/widgets/property_map_cluster_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/property.dart';

class PropertyMapClusterView extends StatefulWidget {
  final List<Property> properties;
  final Function(Property) onPropertySelected;
  final Function(Map<String, dynamic>) onFilterChanged;

  const PropertyMapClusterView({
    super.key,
    required this.properties,
    required this.onPropertySelected,
    required this.onFilterChanged,
  });

  @override
  State<PropertyMapClusterView> createState() => _PropertyMapClusterViewState();
}

class _PropertyMapClusterViewState extends State<PropertyMapClusterView>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polygon> _polygons = {};

  // Animation Controllers
  late AnimationController _markerAnimationController;
  late AnimationController _overlayAnimationController;

  // Animations
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _overlaySlideAnimation;

  // State
  Property? _selectedProperty;
  bool _showFilters = false;
  bool _showStats = true;
  bool _showHeatmap = false;
  bool _showClusters = true;
  MapType _mapType = MapType.normal;
  bool _isUpdatingMarkers = false; // منع التحديث المتزامن

  // Clustering
  Map<String, List<Property>> _clusters = {};
  double _currentZoom = 12;

  // Map Style
  String? _darkMapStyle;
  final bool _isDarkMode = true;

  // Stats
  int _visiblePropertiesCount = 0;
  double _averageRating = 0;
  int _approvedCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMapStyles();
    _processProperties();
  }

  void _initializeAnimations() {
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _markerScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _markerAnimationController,
      curve: Curves.elasticOut,
    ));

    _overlaySlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeOutQuart,
    ));

    _markerAnimationController.forward();
    _overlayAnimationController.forward();
  }

  Future<void> _loadMapStyles() async {
    _darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#1d2c4d"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#8ec3f5"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#1a3646"}]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "poi",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#0e1626"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#2f3948"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#212a37"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#9ca5b3"}]
      }
    ]
    ''';
  }

  void _processProperties() {
    _calculateStats();
    if (_showClusters) {
      _createClusters();
    } else {
      _createMarkers();
    }
  }

  void _calculateStats() {
    _visiblePropertiesCount = widget.properties.length;
    _approvedCount = widget.properties.where((p) => p.isApproved).length;
    _pendingCount = widget.properties.where((p) => !p.isApproved).length;

    if (widget.properties.isNotEmpty) {
      final totalRating = widget.properties
          .fold<double>(0, (sum, property) => sum + property.averageRating);
      _averageRating = totalRating / widget.properties.length;
    } else {
      _averageRating = 0;
    }
  }

  void _createClusters() {
    // إنشاء نسخة جديدة من الخريطة لتجنب التعديل المتزامن
    final newClusters = <String, List<Property>>{};
    const double clusterRadius = 50; // pixels

    for (final property in widget.properties) {
      if (!property.hasLocation) continue;

      bool addedToCluster = false;
      final propertyLocation = LatLng(property.latitude!, property.longitude!);

      for (final clusterId in newClusters.keys) {
        final clusterProperties = newClusters[clusterId]!;
        final firstProperty = clusterProperties.first;
        final clusterLocation =
            LatLng(firstProperty.latitude!, firstProperty.longitude!);

        final distance = _calculateDistance(propertyLocation, clusterLocation);
        if (distance < clusterRadius) {
          newClusters[clusterId]!.add(property);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        newClusters[property.id] = [property];
      }
    }

    // تحديث الحالة مرة واحدة
    setState(() {
      _clusters = newClusters;
    });

    _updateMarkers();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    final double dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final double dLon = (point2.longitude - point1.longitude) * math.pi / 180;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(point1.latitude * math.pi / 180) *
            math.cos(point2.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void _createMarkers() async {
    if (_isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    final Set<Marker> markers = {};

    for (final property in widget.properties) {
      if (!property.hasLocation) continue;

      final BitmapDescriptor icon = await _createCustomMarker(
        property: property,
        isSelected: _selectedProperty?.id == property.id,
      );

      markers.add(Marker(
        markerId: MarkerId(property.id),
        position: LatLng(property.latitude!, property.longitude!),
        icon: icon,
        onTap: () => _onMarkerTapped(property),
        zIndex: _selectedProperty?.id == property.id ? 999 : 1,
      ));
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }

    _isUpdatingMarkers = false;
  }

  Future<void> _updateMarkers() async {
    if (_isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    final Set<Marker> markers = {};

    // إنشاء نسخة من المفاتيح لتجنب التعديل المتزامن
    final clusterKeys = _clusters.keys.toList();

    for (final key in clusterKeys) {
      final properties = _clusters[key];
      if (properties == null || properties.isEmpty) continue;

      final firstProperty = properties.first;

      if (properties.length == 1) {
        // Single property marker
        final BitmapDescriptor icon = await _createCustomMarker(
          property: firstProperty,
          isSelected: _selectedProperty?.id == firstProperty.id,
        );

        markers.add(Marker(
          markerId: MarkerId(firstProperty.id),
          position: LatLng(firstProperty.latitude!, firstProperty.longitude!),
          icon: icon,
          onTap: () => _onMarkerTapped(firstProperty),
          zIndex: _selectedProperty?.id == firstProperty.id ? 999 : 1,
        ));
      } else {
        // Cluster marker
        final clusterLocation = _calculateClusterCenter(properties);
        final BitmapDescriptor icon = await _createClusterMarker(
          count: properties.length,
          isSelected: properties.any((p) => p.id == _selectedProperty?.id),
        );

        markers.add(Marker(
          markerId: MarkerId('cluster_$key'),
          position: clusterLocation,
          icon: icon,
          onTap: () => _onClusterTapped(properties),
          zIndex:
              properties.any((p) => p.id == _selectedProperty?.id) ? 999 : 1,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }

    _isUpdatingMarkers = false;
  }

  LatLng _calculateClusterCenter(List<Property> properties) {
    double sumLat = 0;
    double sumLng = 0;

    for (final property in properties) {
      sumLat += property.latitude!;
      sumLng += property.longitude!;
    }

    return LatLng(sumLat / properties.length, sumLng / properties.length);
  }

  Future<BitmapDescriptor> _createCustomMarker({
    required Property property,
    required bool isSelected,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();

    const double width = 120;
    const double height = 60;

    // Background
    paint.shader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(width, height),
      isSelected
          ? [AppTheme.primaryPurple, AppTheme.primaryBlue]
          : property.isApproved
              ? [AppTheme.success, AppTheme.success.withOpacity(0.8)]
              : [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
    );

    final RRect rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height - 10),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, paint);

    // Triangle pointer
    final Path path = Path()
      ..moveTo(width / 2 - 10, height - 10)
      ..lineTo(width / 2, height)
      ..lineTo(width / 2 + 10, height - 10)
      ..close();
    canvas.drawPath(path, paint);

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: property.starRating > 0 ? '⭐' : '🏢',
        style: const TextStyle(fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, const Offset(10, 10));

    // Details
    final markerTitlePainter = TextPainter(
      text: TextSpan(
        text: property.typeName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    markerTitlePainter.layout(minWidth: 0, maxWidth: 70);
    markerTitlePainter.paint(canvas, const Offset(40, 8));

    final bookingLabel = property.bookingCount > 0
        ? '${property.bookingCount} حجز'
        : 'بدون حجوزات';
    final metricsPainter = TextPainter(
      text: TextSpan(
        text: '⭐ ${property.averageRating.toStringAsFixed(1)} • $bookingLabel',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    metricsPainter.layout(minWidth: 0, maxWidth: 70);
    metricsPainter.paint(canvas, const Offset(40, 32));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List data = bytes!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(data);
  }

  Future<BitmapDescriptor> _createClusterMarker({
    required int count,
    required bool isSelected,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();

    const double size = 80;
    const double radius = size / 2;

    // Outer circle (glow effect)
    paint.shader = ui.Gradient.radial(
      const Offset(radius, radius),
      radius,
      isSelected
          ? [
              AppTheme.primaryPurple.withOpacity(0.4),
              AppTheme.primaryPurple.withOpacity(0.1),
            ]
          : [
              AppTheme.primaryBlue.withOpacity(0.4),
              AppTheme.primaryBlue.withOpacity(0.1),
            ],
    );
    canvas.drawCircle(const Offset(radius, radius), radius, paint);

    // Inner circle
    paint.shader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(size, size),
      isSelected
          ? [AppTheme.primaryPurple, AppTheme.primaryBlue]
          : [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
    );
    canvas.drawCircle(const Offset(radius, radius), radius * 0.7, paint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List data = bytes!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(data);
  }

  void _onMarkerTapped(Property property) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedProperty = property;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(property.latitude!, property.longitude!),
          zoom: 16,
        ),
      ),
    );

    // widget.onPropertySelected(property);
  }

  void _onClusterTapped(List<Property> properties) {
    HapticFeedback.mediumImpact();

    if (properties.length == 1) {
      _onMarkerTapped(properties.first);
      return;
    }

    // Calculate bounds
    double minLat = properties.first.latitude!;
    double maxLat = properties.first.latitude!;
    double minLng = properties.first.longitude!;
    double maxLng = properties.first.longitude!;

    for (final property in properties) {
      minLat = math.min(minLat, property.latitude!);
      maxLat = math.max(maxLat, property.latitude!);
      minLng = math.min(minLng, property.longitude!);
      maxLng = math.max(maxLng, property.longitude!);
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );

    // Show properties list in bottom sheet
    _showClusterProperties(properties);
  }

  void _showClusterProperties(List<Property> properties) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ClusterPropertiesSheet(
        properties: properties,
        onPropertySelected: (property) {
          Navigator.pop(context);
          _onMarkerTapped(property);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidProperties = widget.properties.any((p) => p.hasLocation);
    final center = hasValidProperties && widget.properties.isNotEmpty
        ? LatLng(
            widget.properties.first.latitude ?? 15.3694,
            widget.properties.first.longitude ?? 44.1910,
          )
        : const LatLng(15.3694, 44.1910); // Default Yemen coordinates

    return LayoutBuilder(
      builder: (context, constraints) {
        // التكيف مع المساحة المتاحة
        final isCompact = constraints.maxHeight < 600;

        return Stack(
          children: [
            // Map - ملء كامل المساحة المتاحة
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: center,
                    zoom: _currentZoom,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_isDarkMode && _darkMapStyle != null) {
                      controller.setMapStyle(_darkMapStyle);
                    }
                  },
                  markers: _markers,
                  circles: _showHeatmap ? _circles : {},
                  polygons: _polygons,
                  mapType: _mapType,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer()),
                    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                    Factory<ScaleGestureRecognizer>(
                        () => ScaleGestureRecognizer()),
                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                    Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer()),
                  },
                  onCameraMove: (position) {
                    _currentZoom = position.zoom;
                  },
                  onCameraIdle: () {
                    if (_showClusters && !_isUpdatingMarkers) {
                      _createClusters();
                    }
                  },
                ),
              ),
            ),

            // Top Controls Bar
            Positioned(
              top: isCompact ? 8 : 16,
              left: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _overlaySlideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _overlaySlideAnimation.value * 100),
                    child: _buildTopControls(isCompact: isCompact),
                  );
                },
              ),
            ),

            // Stats Overlay
            if (_showStats)
              Positioned(
                top: isCompact ? 60 : 80,
                left: 16,
                child: AnimatedBuilder(
                  animation: _overlaySlideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_overlaySlideAnimation.value * 100, 0),
                      child: _buildStatsOverlay(isCompact: isCompact),
                    );
                  },
                ),
              ),

            // Map Controls
            Positioned(
              bottom: _selectedProperty != null ? (isCompact ? 180 : 220) : 24,
              right: 16,
              child: _buildMapControls(isCompact: isCompact),
            ),

            // Property Details Card
            if (_selectedProperty != null)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _markerScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _markerScaleAnimation.value,
                      child: _PropertyDetailsCard(
                        property: _selectedProperty!,
                        onClose: () => setState(() => _selectedProperty = null),
                        onViewDetails: () =>
                            widget.onPropertySelected(_selectedProperty!),
                        isCompact: isCompact,
                      ),
                    );
                  },
                ),
              ),

            // Filter Panel
            if (_showFilters)
              Positioned(
                top: isCompact ? 60 : 80,
                right: 16,
                bottom: 24,
                child: _buildFilterPanel(
                    isCompact: isCompact), // تم إضافة البارامتر
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopControls({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: isCompact
              ? _buildCompactControls() // عناصر تحكم مضغوطة للشاشات الصغيرة
              : _buildFullControls(), // عناصر التحكم الكاملة
        ),
      ),
    );
  }

  // عناصر تحكم مضغوطة
  Widget _buildCompactControls() {
    return Row(
      children: [
        // Search icon only
        _buildControlButton(
          icon: CupertinoIcons.search,
          onTap: () {
            // Show search dialog
            _showSearchDialog();
          },
        ),

        const Spacer(),

        // Essential controls only
        _buildControlButton(
          icon: CupertinoIcons.slider_horizontal_3,
          isActive: _showFilters,
          onTap: () => setState(() => _showFilters = !_showFilters),
        ),

        _buildControlButton(
          icon: CupertinoIcons.circle_grid_3x3_fill,
          isActive: _showClusters,
          onTap: () {
            setState(() => _showClusters = !_showClusters);
            _processProperties();
          },
        ),

        // Dropdown menu for more options
        PopupMenuButton<String>(
          icon: Icon(
            CupertinoIcons.ellipsis_circle,
            size: 18,
            color: AppTheme.textMuted,
          ),
          onSelected: (value) {
            switch (value) {
              case 'heatmap':
                setState(() => _showHeatmap = !_showHeatmap);
                break;
              case 'mapType':
                setState(() {
                  _mapType = _mapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal;
                });
                break;
              case 'stats':
                setState(() => _showStats = !_showStats);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'heatmap',
              child: Row(
                children: [
                  Icon(CupertinoIcons.map_fill, size: 16),
                  SizedBox(width: 8),
                  Text('خريطة حرارية'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mapType',
              child: Row(
                children: [
                  Icon(CupertinoIcons.globe, size: 16),
                  SizedBox(width: 8),
                  Text('نوع الخريطة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(CupertinoIcons.chart_bar_square, size: 16),
                  SizedBox(width: 8),
                  Text('الإحصائيات'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // عناصر التحكم الكاملة (الأصلية)
  Widget _buildFullControls() {
    return Row(
      children: [
        // Search
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.darkSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.2),
              ),
            ),
            child: TextField(
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
              ),
              decoration: InputDecoration(
                hintText: 'بحث في الخريطة...',
                hintStyle: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // All control buttons
        _buildControlButton(
          icon: CupertinoIcons.slider_horizontal_3,
          isActive: _showFilters,
          onTap: () => setState(() => _showFilters = !_showFilters),
        ),

        _buildControlButton(
          icon: CupertinoIcons.circle_grid_3x3_fill,
          isActive: _showClusters,
          onTap: () {
            setState(() => _showClusters = !_showClusters);
            _processProperties();
          },
        ),

        _buildControlButton(
          icon: CupertinoIcons.map_fill,
          isActive: _showHeatmap,
          onTap: () => setState(() => _showHeatmap = !_showHeatmap),
        ),

        _buildControlButton(
          icon: _mapType == MapType.satellite
              ? CupertinoIcons.globe
              : CupertinoIcons.map,
          onTap: () {
            setState(() {
              _mapType = _mapType == MapType.normal
                  ? MapType.satellite
                  : MapType.normal;
            });
          },
        ),
      ],
    );
  }

  // دالة البحث المنبثقة للوضع المضغوط
  void _showSearchDialog() {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن عقار...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    color: AppTheme.primaryBlue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.darkBorder.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.darkBorder.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  Navigator.pop(context);
                  // Perform search
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تحديث _buildStatsOverlay
  Widget _buildStatsOverlay({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      width: isCompact ? 180 : 200,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إحصائيات',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 13 : 14,
                ),
              ),
              SizedBox(height: isCompact ? 8 : 12),
              _buildStatRow(
                label: 'العقارات',
                value: _visiblePropertiesCount.toString(),
                color: AppTheme.primaryBlue,
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 6 : 8),
              _buildStatRow(
                label: 'معتمد',
                value: _approvedCount.toString(),
                color: AppTheme.success,
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 6 : 8),
              _buildStatRow(
                label: 'قيد المراجعة',
                value: _pendingCount.toString(),
                color: AppTheme.warning,
                isCompact: isCompact,
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                _buildStatRow(
                  label: 'متوسط التقييم',
                  value: _averageRating.toStringAsFixed(1),
                  color: AppTheme.primaryPurple,
                  isCompact: isCompact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // تحديث _buildMapControls
  Widget _buildMapControls({bool isCompact = false}) {
    return Column(
      children: [
        _buildMapControlButton(
          icon: CupertinoIcons.plus,
          onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
          size: isCompact ? 40 : 44,
        ),
        SizedBox(height: isCompact ? 6 : 8),
        _buildMapControlButton(
          icon: CupertinoIcons.minus,
          onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
          size: isCompact ? 40 : 44,
        ),
        SizedBox(height: isCompact ? 6 : 8),
        _buildMapControlButton(
          icon: CupertinoIcons.location_fill,
          onTap: _centerMap,
          isPrimary: true,
          size: isCompact ? 40 : 44,
        ),
        if (!isCompact) ...[
          const SizedBox(height: 8),
          _buildMapControlButton(
            icon: _showStats
                ? CupertinoIcons.chart_bar_square_fill
                : CupertinoIcons.chart_bar_square,
            onTap: () => setState(() => _showStats = !_showStats),
            size: 44,
          ),
        ],
      ],
    );
  }

  // تحديث _buildMapControlButton
  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    double size = 44,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.darkCard.withOpacity(0.9),
          borderRadius: BorderRadius.circular(size * 0.32),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.2),
                ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppTheme.primaryBlue.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : AppTheme.textWhite,
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: isCompact ? 32 : 36,
        height: isCompact ? 32 : 36,
        margin: EdgeInsets.only(left: isCompact ? 2 : 4),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.primaryGradient : null,
          color: isActive ? null : AppTheme.darkSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          size: isCompact ? 16 : 18,
          color: isActive ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color color,
    bool isCompact = false, // إضافة البارامتر
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: isCompact ? 6 : 8,
                height: isCompact ? 6 : 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: isCompact ? 10 : 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
      ],
    );
  }

  void _centerMap() {
    if (widget.properties.isEmpty) return;

    double minLat = widget.properties.first.latitude ?? 0;
    double maxLat = widget.properties.first.latitude ?? 0;
    double minLng = widget.properties.first.longitude ?? 0;
    double maxLng = widget.properties.first.longitude ?? 0;

    for (final property in widget.properties) {
      if (!property.hasLocation) continue;
      minLat = math.min(minLat, property.latitude!);
      maxLat = math.max(maxLat, property.latitude!);
      minLng = math.min(minLng, property.longitude!);
      maxLng = math.max(maxLng, property.longitude!);
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  Widget _buildFilterPanel({bool isCompact = false}) {
    return Container(
      width: isCompact ? 260 : 280,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * (isCompact ? 0.6 : 0.7),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'فلاتر الخريطة',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 13 : 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = false),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: isCompact ? 16 : 18,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 12 : 16),

                // Rating Range
                Text(
                  'نطاق التقييم',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(isCompact ? 8 : 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      RangeSlider(
                        values: const RangeValues(0, 5),
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: AppTheme.primaryBlue,
                        inactiveColor: AppTheme.darkBorder,
                        onChanged: (values) {},
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textLight,
                              fontSize: isCompact ? 10 : 11,
                            ),
                          ),
                          Text(
                            '5',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textLight,
                              fontSize: isCompact ? 10 : 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isCompact ? 12 : 16),

                // Property Type
                Text(
                  'نوع العقار',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: isCompact ? 6 : 8,
                  runSpacing: isCompact ? 6 : 8,
                  children: [
                    _buildFilterChip('فندق', true, isCompact: isCompact),
                    _buildFilterChip('شقة', false, isCompact: isCompact),
                    _buildFilterChip('فيلا', false, isCompact: isCompact),
                    _buildFilterChip('منتجع', true, isCompact: isCompact),
                  ],
                ),

                SizedBox(height: isCompact ? 12 : 16),

                // Apply Button
                GestureDetector(
                  onTap: () {
                    widget.onFilterChanged({});
                    setState(() => _showFilters = false);
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'تطبيق الفلاتر',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: Colors.white,
                          fontSize: isCompact ? 12 : 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected,
      {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 12,
          vertical: isCompact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _overlayAnimationController.dispose();
    super.dispose();
  }
}

class _PropertyDetailsCard extends StatelessWidget {
  final Property property;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;
  final bool isCompact;

  const _PropertyDetailsCard({
    required this.property,
    required this.onClose,
    required this.onViewDetails,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isCompact ? 150 : 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.05),
                        AppTheme.primaryPurple.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        // Property Image
                        Container(
                          width: isCompact ? 50 : 60,
                          height: isCompact ? 50 : 60,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: property.images.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    property.images.first.thumbnails.medium,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: isCompact ? 24 : 28,
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Property Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.name,
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppTheme.textWhite,
                                  fontSize: isCompact ? 14 : 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.location_solid,
                                    size: isCompact ? 10 : 12,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.formattedAddress,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textMuted,
                                        fontSize: isCompact ? 10 : 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Close Button
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: isCompact ? 28 : 32,
                            height: isCompact ? 28 : 32,
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: isCompact ? 14 : 16,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isCompact ? 8 : 12),

                    // Stats Row
                    Row(
                      children: [
                        _buildStatItem(
                          icon: CupertinoIcons.star_fill,
                          value: property.starRating.toString(),
                          label: 'نجوم',
                          color: AppTheme.warning,
                          isCompact: isCompact,
                        ),
                        const SizedBox(width: 8),
                        _buildStatItem(
                          icon: CupertinoIcons.calendar,
                          value: property.bookingCount.toString(),
                          label: 'الحجوزات',
                          color: AppTheme.primaryBlue,
                          isCompact: isCompact,
                        ),
                        const SizedBox(width: 8),
                        _buildStatItem(
                          icon: property.isApproved
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.clock_fill,
                          value: property.isApproved ? 'معتمد' : 'قيد المراجعة',
                          label: 'الحالة',
                          color: property.isApproved
                              ? AppTheme.success
                              : AppTheme.warning,
                          isCompact: isCompact,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Action Button
                    GestureDetector(
                      onTap: onViewDetails,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: isCompact ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'عرض التفاصيل',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: Colors.white,
                              fontSize: isCompact ? 12 : 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isCompact = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4 : 6,
          vertical: isCompact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isCompact ? 10 : 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 10 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isCompact ? 8 : 9,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cluster Properties Sheet
class _ClusterPropertiesSheet extends StatelessWidget {
  final List<Property> properties;
  final Function(Property) onPropertySelected;

  const _ClusterPropertiesSheet({
    required this.properties,
    required this.onPropertySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'العقارات في هذه المنطقة',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${properties.length} عقار',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Properties List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return GestureDetector(
                  onTap: () => onPropertySelected(property),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.darkBorder.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Image
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: property.images.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    property.images.first.thumbnails.small,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppTheme.textWhite,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.location,
                                    size: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.city,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Metrics
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '⭐ ${property.averageRating.toStringAsFixed(1)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${property.bookingCount} حجز',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
