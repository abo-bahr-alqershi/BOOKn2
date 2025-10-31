// lib/features/admin_properties/presentation/widgets/property_map_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PropertyMapView extends StatefulWidget {
  final Function(LatLng)? onLocationSelected;
  final LatLng? initialLocation;
  final bool isReadOnly;

  const PropertyMapView({
    super.key,
    this.onLocationSelected,
    this.initialLocation,
    this.isReadOnly = false,
  });

  @override
  State<PropertyMapView> createState() => _PropertyMapViewState();
}

class _PropertyMapViewState extends State<PropertyMapView> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLocation ?? const LatLng(15.3694, 44.1910);
    _updateMarker();
  }

  void _updateMarker() {
    if (_selectedLocation != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('property_location'),
            position: _selectedLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Container with Rounded Corners
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation!,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _setMapStyle();
            },
            markers: _markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
            },
            onTap: widget.isReadOnly
                ? null
                : (position) {
                    setState(() {
                      _selectedLocation = position;
                      _updateMarker();
                    });
                    widget.onLocationSelected?.call(position);
                  },
            mapType: MapType.normal,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
        ),

        // Glass Overlay for Instructions
        if (!widget.isReadOnly)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.hand_raised,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'انقر على الخريطة لتحديد الموقع',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Map Controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapControl(
                icon: CupertinoIcons.plus,
                onTap: () => _mapController?.animateCamera(
                  CameraUpdate.zoomIn(),
                ),
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: CupertinoIcons.minus,
                onTap: () => _mapController?.animateCamera(
                  CameraUpdate.zoomOut(),
                ),
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: CupertinoIcons.location_fill,
                onTap: () {
                  if (_selectedLocation != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _selectedLocation!,
                          zoom: 16,
                        ),
                      ),
                    );
                  }
                },
                isPrimary: true,
              ),
            ],
          ),
        ),

        // Location Info Card
        if (_selectedLocation != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الإحداثيات',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                        '${_selectedLocation!.longitude.toStringAsFixed(4)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.darkCard.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.2),
                ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : AppTheme.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _setMapStyle() {
    // Dark mode map style
    const String mapStyle = '''
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
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#0e1626"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#2f3948"}]
      }
    ]
    ''';

    _mapController?.setMapStyle(mapStyle);
  }
}
