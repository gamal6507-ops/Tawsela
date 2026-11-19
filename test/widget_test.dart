import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/core/services/location_service.dart';
import 'package:toktok/data/repositories/fake_ride_repository.dart';
import 'package:toktok/domain/models/ride.dart';

void main() {
  group('LocationService Egypt bounds', () {
    final service = LocationService();

    test('accepts coordinates inside Egypt', () {
      expect(
        service.isInsideEgypt(const LatLng(30.0444, 31.2357)),
        isTrue,
      ); // Cairo
      expect(
        service.isInsideEgypt(const LatLng(31.2001, 29.9187)),
        isTrue,
      ); // Alexandria
      expect(
        service.isInsideEgypt(const LatLng(24.0889, 32.8998)),
        isTrue,
      ); // Aswan
    });

    test('rejects coordinates outside Egypt', () {
      expect(
        service.isInsideEgypt(const LatLng(37.4220, -122.0841)),
        isFalse,
      ); // Mountain View
      expect(
        service.isInsideEgypt(const LatLng(51.5072, -0.1276)),
        isFalse,
      ); // London
    });
  });

  group('FakeRideRepository', () {
    late FakeRideRepository repository;

    setUp(() {
      repository = FakeRideRepository();
    });

    test('getRideTypes returns 3 ride options', () async {
      final options = await repository.getRideTypes();
      expect(options.length, 3);
      expect(options[0].type, RideType.car);
      expect(options[1].type, RideType.motorcycle);
      expect(options[2].type, RideType.scooter);
    });

    test('searchForDriver returns a driver', () async {
      final driver = await repository.searchForDriver(RideType.car);
      expect(driver.name, isNotEmpty);
      expect(driver.phone, isNotEmpty);
      expect(driver.plateNumber, isNotEmpty);
    });
  });
}
