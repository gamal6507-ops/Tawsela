import 'dart:ui' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng defaultCairoLocation = LatLng(30.0444, 31.2357);
  static const LatLng egyptSouthWest = LatLng(22.0, 25.0);
  static const LatLng egyptNorthEast = LatLng(31.7, 36.9);

  Geocoding? _geocoding;
  Geocoding get _geocoder =>
      _geocoding ??= Geocoding(locale: const Locale('ar'));

  /// Returns true if [point] lies within Egypt's geographic bounds.
  bool isInsideEgypt(LatLng point) {
    return point.latitude >= egyptSouthWest.latitude &&
        point.latitude <= egyptNorthEast.latitude &&
        point.longitude >= egyptSouthWest.longitude &&
        point.longitude <= egyptNorthEast.longitude;
  }

  /// Requests location permission if needed and returns the current GPS position.
  /// Falls back to Cairo center if location services, permissions, or Egypt bounds are unavailable.
  Future<LatLng> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return defaultCairoLocation;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return defaultCairoLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final current = LatLng(position.latitude, position.longitude);
      return isInsideEgypt(current) ? current : defaultCairoLocation;
    } catch (_) {
      return defaultCairoLocation;
    }
  }

  /// Converts coordinates into a human-readable address.
  Future<String> getAddressFromLatLng(LatLng point) async {
    try {
      final placemarks = await _geocoder.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        ];
        if (parts.isNotEmpty) {
          return parts.take(2).join('، ');
        }
      }
    } catch (_) {}
    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  /// Resolves a text address inside Egypt into coordinates, returning null if not found.
  Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      final query = address.contains('مصر') || address.toLowerCase().contains('egypt')
          ? address
          : '$address، مصر';
      final locations = await _geocoder.locationFromAddress(query);
      for (final loc in locations) {
        final point = LatLng(loc.latitude, loc.longitude);
        if (isInsideEgypt(point)) {
          return point;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Returns distance in kilometers between two coordinates (minimum 1.0 km).
  double calculateDistanceKm(LatLng from, LatLng to) {
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    final km = meters / 1000.0;
    return km < 1.0 ? 1.0 : double.parse(km.toStringAsFixed(1));
  }
}
