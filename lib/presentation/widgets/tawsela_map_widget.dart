import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/core/services/location_service.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TawselaMapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final double height;
  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;
  final LatLng? driverPoint;
  final String? driverIcon;
  final void Function(LatLng point)? onTap;
  final MapController? mapController;

  const TawselaMapWidget({
    super.key,
    this.center = const LatLng(30.0444, 31.2357),
    this.zoom = 13.0,
    this.height = 240,
    this.pickupPoint,
    this.dropoffPoint,
    this.driverPoint,
    this.driverIcon,
    this.onTap,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (pickupPoint != null)
        Marker(
          point: pickupPoint!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: AppColors.accent,
            size: 30,
          ),
        ),
      if (dropoffPoint != null)
        Marker(
          point: dropoffPoint!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: AppColors.error,
            size: 34,
          ),
        ),
      if (driverPoint != null)
        Marker(
          point: driverPoint!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                driverIcon ?? '🚗',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
    ];

    final polylines = <Polyline>[
      if (pickupPoint != null && dropoffPoint != null)
        Polyline(
          points: [pickupPoint!, dropoffPoint!],
          color: AppColors.accent,
          strokeWidth: 4,
        ),
      if (driverPoint != null && pickupPoint != null)
        Polyline(
          points: [driverPoint!, pickupPoint!],
          color: AppColors.success,
          strokeWidth: 3.5,
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            minZoom: 5.5,
            maxZoom: 18.0,
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                LocationService.egyptSouthWest,
                LocationService.egyptNorthEast,
              ),
            ),
            onTap: onTap != null ? (_, point) => onTap!(point) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.toktok.toktok',
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap:
                      () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
