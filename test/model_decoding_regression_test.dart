import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/models/promo_code.dart';

void main() {
  test('Firestore integer numeric values decode safely as doubles', () {
    final trip = Trip.fromMap({
      'id': 'r1',
      'from': 'A',
      'to': 'B',
      'rideType': 'car',
      'price': 21,
      'driverName': 'Captain',
      'driverRating': 0,
      'driverPlate': 'ABC',
      'date': 0,
      'durationMinutes': 5,
      'distanceKm': 1,
      'paymentMethod': 'cash',
    });
    expect(trip.distanceKm, 1.0);
    expect(trip.driverRating, 0.0);
  });
  test('promo gradient lists round trip without an invalid generic cast', () {
    const code = PromoCode(
      code: 'TEST',
      discountText: 'Test',
      condition: 'Test',
      gradientColors: [
        [1, 2],
      ],
    );
    expect(PromoCode.fromMap(code.toMap()).gradientColors, [
      [1, 2],
    ]);
  });
}
