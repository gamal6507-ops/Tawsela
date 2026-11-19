import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/data/repositories/fake_ride_repository.dart';
import 'package:toktok/domain/models/driver.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/models/ride_request.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';

class ControlledRides extends FakeRideRepository {
  final created = Completer<String?>();
  final driver = Completer<Driver>();
  int createCalls = 0;
  bool failCreate = false;
  bool failSave = false;
  int saves = 0;

  @override
  Future<List<RideOption>> getRideTypes({double? distanceKm}) async => const [
    RideOption(
      type: RideType.car,
      name: 'Car',
      price: 24,
      etaMinutes: 0,
      icon: '',
    ),
  ];

  @override
  Future<String?> createRideRequest({
    required String from,
    required String to,
    required RideType rideType,
    required int price,
    required PaymentMethod paymentMethod,
    LatLng? pickupLatLng,
    LatLng? dropoffLatLng,
    double? distanceKm,
  }) async {
    createCalls++;
    if (failCreate) throw StateError('offline');
    return created.future;
  }

  @override
  Future<Driver> searchForDriver(RideType type, {String? requestId}) =>
      driver.future;

  @override
  Future<void> completeRideAndSaveTrip({
    required String? requestId,
    required String from,
    required String to,
    required RideType rideType,
    required int price,
    required Driver driver,
    required PaymentMethod paymentMethod,
    double distanceKm = 4,
  }) async {
    saves++;
    if (failSave) throw StateError('offline');
  }
}

Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late ControlledRides repository;
  late RideBookingBloc bloc;
  setUp(() {
    repository = ControlledRides();
    bloc = RideBookingBloc(repository);
  });
  tearDown(() async {
    if (!repository.created.isCompleted) {
      repository.created.complete('request-1');
    }
    if (!repository.driver.isCompleted) {
      repository.driver.complete(
        const Driver(
          id: 'driver-1',
          name: 'Driver',
          phone: '01000000000',
          plateNumber: '123',
        ),
      );
    }
    await flush();
    await bloc.close();
  });

  test('rapid double confirmation creates only one request', () async {
    bloc.add(const RideBookingStarted(from: 'A', to: 'B'));
    await flush();
    bloc.add(const BookingConfirmed());
    bloc.add(const BookingConfirmed());
    await flush();
    expect(repository.createCalls, 1);
  });

  test(
    'failed create is recoverable and does not escape as an unhandled error',
    () async {
      repository.failCreate = true;
      final errors = <Object>[];
      final subscription = bloc.stream.listen((_) {}, onError: errors.add);
      bloc.add(const RideBookingStarted(from: 'A', to: 'B'));
      await flush();
      bloc.add(const BookingConfirmed());
      await flush();
      expect(errors, isEmpty);
      expect(bloc.state, isA<SelectingRide>());
      await subscription.cancel();
    },
  );

  test('a cancelled pending create cannot reopen the search', () async {
    bloc.add(const RideBookingStarted(from: 'A', to: 'B'));
    await flush();
    bloc.add(const BookingConfirmed());
    await flush();
    bloc.add(const BookingCancelled());
    await flush();
    repository.created.complete('request-1');
    await flush();
    expect(bloc.state, isA<RideBookingInitial>());
  });

  Future<void> arrive() async {
    bloc.add(const RideBookingStarted(from: 'A', to: 'B'));
    await flush();
    bloc.add(const BookingConfirmed());
    repository.created.complete('request-1');
    await flush();
    bloc.add(
      RemoteRideChanged(
        RideRequest('request-1', {
          'status': 'arrived',
          'from': 'A',
          'to': 'B',
          'rideType': 'car',
          'price': 24,
          'distanceKm': 3.5,
          'pickupLat': 30.0,
          'pickupLng': 31.0,
          'dropoffLat': 30.02,
          'dropoffLng': 31.015,
          'driver': {
            'id': 'driver-1',
            'name': 'Driver',
            'phone': '01000000000',
            'plateNumber': '123',
            'rating': 0,
          },
        }),
      ),
    );
    await flush();
  }

  test('completion acknowledges a persisted arrival exactly once', () async {
    await arrive();
    bloc.add(const RideCompleted());
    bloc.add(const RideCompleted());
    await flush();
    expect(repository.saves, 1);
    expect(bloc.state, isA<RideBookingInitial>());
  });

  test(
    'failed completion cannot report success or erase the active ride',
    () async {
      await arrive();
      repository.failSave = true;
      bloc.add(const RideCompleted());
      await flush();
      expect(bloc.state, isA<RideBookingError>());
      expect(repository.saves, 1);
    },
  );

  test('rider cannot declare arrival without a driver update', () async {
    bloc.add(const RideBookingStarted(from: 'A', to: 'B'));
    await flush();
    bloc.add(const RideArrived());
    await flush();
    expect(bloc.state, isA<SelectingRide>());
    expect(repository.saves, 0);
  });
}
