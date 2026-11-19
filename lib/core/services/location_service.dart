import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'fare_calculator.dart';

class LocationService {
  static const defaultCairoLocation = LatLng(30.0444, 31.2357);
  static const egyptSouthWest = LatLng(22, 25);
  static const egyptNorthEast = LatLng(31.7, 36.9);
  bool isInsideEgypt(LatLng point) =>
      point.latitude >= 22 &&
      point.latitude <= 31.7 &&
      point.longitude >= 25 &&
      point.longitude <= 36.9;
  Future<LatLng> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('فعّل خدمة الموقع أو حدد مكانك على الخريطة');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('إذن الموقع غير متاح. حدد نقطة الانطلاق على الخريطة');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    final point = LatLng(position.latitude, position.longitude);
    if (!isInsideEgypt(point)) {
      throw StateError('الخدمة داخل نطاق مصر فقط. حدد المكان على الخريطة');
    }
    return point;
  }

  Future<String> getAddressFromLatLng(LatLng point) async =>
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  Future<LatLng?> getLatLngFromAddress(String address) async {
    final query = address.trim();
    if (query.length < 3 || query.length > 200) return null;
    final endpoint =
        kIsWeb
            ? Uri.base
                .resolve('/api/geocode')
                .replace(queryParameters: {'q': query})
            : Uri.https('photon.komoot.io', '/api/', {
              'q': query,
              'bbox': '25,22,36.9,31.7',
              'limit': '5',
            });
    final response = await http
        .get(endpoint)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('البحث غير متاح الآن. حدد المكان على الخريطة');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    for (final feature in body['features'] as List? ?? []) {
      final coords = feature['geometry']['coordinates'] as List;
      final point = LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
      if (isInsideEgypt(point)) return point;
    }
    return null;
  }

  double calculateDistanceKm(LatLng from, LatLng to) =>
      FareCalculator.distance(from, to);
}
