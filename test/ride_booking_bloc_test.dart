import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/data/repositories/fake_ride_repository.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';

void main() {
  late FakeRideRepository repository;

  setUp(() {
    repository = FakeRideRepository();
  });

  group('RideBookingBloc', () {
    test('initial state is RideBookingInitial', () {
      final bloc = RideBookingBloc(repository);
      expect(bloc.state, isA<RideBookingInitial>());
      bloc.close();
    });

    blocTest<RideBookingBloc, RideBookingState>(
      'emits SelectingRide with car selected by default when RideBookingStarted is added',
      build: () => RideBookingBloc(repository),
      act:
          (bloc) =>
              bloc.add(const RideBookingStarted(from: 'المول', to: 'البيت')),
      wait: const Duration(milliseconds: 600),
      expect:
          () => [
            isA<SelectingRide>()
                .having((s) => s.from, 'from', 'المول')
                .having((s) => s.to, 'to', 'البيت')
                .having((s) => s.selectedType, 'selectedType', RideType.car)
                .having((s) => s.selectedPrice, 'selectedPrice', 24)
                .having((s) => s.rideOptions.length, 'options length', 3),
          ],
    );

    blocTest<RideBookingBloc, RideBookingState>(
      'updates selectedType and selectedPrice when RideTypeSelected is added',
      build: () => RideBookingBloc(repository),
      act: (bloc) async {
        bloc.add(const RideBookingStarted(from: 'المول', to: 'البيت'));
        await Future.delayed(const Duration(milliseconds: 600));
        bloc.add(const RideTypeSelected(RideType.motorcycle));
        bloc.add(const PaymentMethodSelected(PaymentMethod.card));
      },
      wait: const Duration(milliseconds: 700),
      expect:
          () => [
            isA<SelectingRide>().having(
              (s) => s.selectedType,
              'selectedType',
              RideType.car,
            ),
            isA<SelectingRide>()
                .having(
                  (s) => s.selectedType,
                  'selectedType',
                  RideType.motorcycle,
                )
                .having((s) => s.selectedPrice, 'selectedPrice', 12),
            isA<SelectingRide>()
                .having(
                  (s) => s.selectedType,
                  'selectedType',
                  RideType.motorcycle,
                )
                .having(
                  (s) => s.selectedPayment,
                  'selectedPayment',
                  PaymentMethod.card,
                ),
          ],
    );

    blocTest<RideBookingBloc, RideBookingState>(
      'does not emit DriverFoundState if search is cancelled while searching',
      build: () => RideBookingBloc(repository),
      act: (bloc) async {
        bloc.add(const RideBookingStarted(from: 'المول', to: 'البيت'));
        await Future.delayed(const Duration(milliseconds: 600));
        bloc.add(BookingConfirmed());
        await Future.delayed(const Duration(milliseconds: 200));
        bloc.add(BookingCancelled());
      },
      wait: const Duration(seconds: 4),
      expect:
          () => [
            isA<SelectingRide>(),
            isA<SelectingRide>().having(
              (s) => s.isSubmitting,
              'submitting',
              true,
            ),
            isA<SearchingDriver>(),
            isA<RideBookingInitial>(),
          ],
    );
  });
}
