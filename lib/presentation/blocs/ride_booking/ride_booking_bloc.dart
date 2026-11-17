import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/repositories/ride_repository.dart';
import 'ride_booking_event.dart';
import 'ride_booking_state.dart';

class RideBookingBloc extends Bloc<RideBookingEvent, RideBookingState> {
  final RideRepository _rideRepository;

  RideBookingBloc(this._rideRepository) : super(RideBookingInitial()) {
    on<RideBookingStarted>(_onRideBookingStarted);
    on<RideTypeSelected>(_onRideTypeSelected);
    on<PaymentMethodSelected>(_onPaymentMethodSelected);
    on<BookingConfirmed>(_onBookingConfirmed);
    on<DriverSearchStarted>(_onDriverSearchStarted);
    on<DriverFound>(_onDriverFound);
    on<RideStarted>(_onRideStarted);
    on<RideCompleted>(_onRideCompleted);
    on<RideArrived>(_onRideArrived);
    on<BookingCancelled>(_onBookingCancelled);
  }

  Future<void> _onRideBookingStarted(
    RideBookingStarted event,
    Emitter<RideBookingState> emit,
  ) async {
    final options = await _rideRepository.getRideTypes(
      distanceKm: event.distanceKm,
    );
    final selected = options.first;
    emit(SelectingRide(
      from: event.from,
      to: event.to,
      rideOptions: options,
      selectedType: selected.type,
      selectedPrice: selected.price,
      pickupLatLng: event.pickupLatLng,
      dropoffLatLng: event.dropoffLatLng,
      distanceKm: event.distanceKm,
    ));
  }

  void _onRideTypeSelected(
    RideTypeSelected event,
    Emitter<RideBookingState> emit,
  ) {
    final current = state;
    if (current is SelectingRide) {
      final option =
          current.rideOptions.firstWhere((o) => o.type == event.rideType);
      emit(current.copyWith(
        selectedType: event.rideType,
        selectedPrice: option.price,
      ));
    }
  }

  void _onPaymentMethodSelected(
    PaymentMethodSelected event,
    Emitter<RideBookingState> emit,
  ) {
    final current = state;
    if (current is SelectingRide) {
      emit(current.copyWith(selectedPayment: event.method));
    }
  }

  Future<void> _onBookingConfirmed(
    BookingConfirmed event,
    Emitter<RideBookingState> emit,
  ) async {
    final current = state;
    if (current is SelectingRide) {
      final requestId = await _rideRepository.createRideRequest(
        from: current.from,
        to: current.to,
        rideType: current.selectedType,
        price: current.selectedPrice,
        paymentMethod: current.selectedPayment,
        pickupLatLng: current.pickupLatLng,
        dropoffLatLng: current.dropoffLatLng,
        distanceKm: current.distanceKm,
      );
      emit(SearchingDriver(
        from: current.from,
        to: current.to,
        rideType: current.selectedType,
        price: current.selectedPrice,
        paymentMethod: current.selectedPayment,
        requestId: requestId,
        pickupLatLng: current.pickupLatLng,
        dropoffLatLng: current.dropoffLatLng,
        distanceKm: current.distanceKm,
      ));
      add(const DriverSearchStarted());
    }
  }

  Future<void> _onDriverSearchStarted(
    DriverSearchStarted event,
    Emitter<RideBookingState> emit,
  ) async {
    final current = state;
    if (current is SearchingDriver) {
      try {
        final driver = await _rideRepository.searchForDriver(
          current.rideType,
          requestId: current.requestId,
        );
        if (state is! SearchingDriver) return;
        emit(DriverFoundState(
          from: current.from,
          to: current.to,
          driver: driver,
          rideType: current.rideType,
          price: current.price,
          paymentMethod: current.paymentMethod,
          requestId: current.requestId,
          pickupLatLng: current.pickupLatLng,
          dropoffLatLng: current.dropoffLatLng,
          distanceKm: current.distanceKm,
        ));
      } catch (e) {
        if (state is! SearchingDriver) return;
        emit(RideBookingError(e.toString()));
      }
    }
  }

  void _onDriverFound(DriverFound event, Emitter<RideBookingState> emit) {
    final current = state;
    if (current is DriverFoundState) {
      if (current.requestId != null) {
        _rideRepository.updateRideStatus(current.requestId!, 'in_progress');
      }
      emit(RideInProgress(
        from: current.from,
        to: current.to,
        driver: current.driver,
        rideType: current.rideType,
        price: current.price,
        paymentMethod: current.paymentMethod,
        requestId: current.requestId,
        pickupLatLng: current.pickupLatLng,
        dropoffLatLng: current.dropoffLatLng,
        distanceKm: current.distanceKm,
      ));
    }
  }

  void _onRideStarted(RideStarted event, Emitter<RideBookingState> emit) {
    final current = state;
    if (current is DriverFoundState) {
      if (current.requestId != null) {
        _rideRepository.updateRideStatus(current.requestId!, 'in_progress');
      }
      emit(RideInProgress(
        from: current.from,
        to: current.to,
        driver: current.driver,
        rideType: current.rideType,
        price: current.price,
        paymentMethod: current.paymentMethod,
        requestId: current.requestId,
        pickupLatLng: current.pickupLatLng,
        dropoffLatLng: current.dropoffLatLng,
        distanceKm: current.distanceKm,
      ));
    }
  }

  Future<void> _onRideCompleted(
    RideCompleted event,
    Emitter<RideBookingState> emit,
  ) async {
    final current = state;
    if (current is RideArrivedState) {
      await _rideRepository.completeRideAndSaveTrip(
        requestId: current.requestId,
        from: current.from,
        to: current.to,
        rideType: current.rideType,
        price: current.price,
        driver: current.driver,
        paymentMethod: current.paymentMethod,
        distanceKm: current.distanceKm,
      );
    }
    emit(RideBookingInitial());
  }

  void _onRideArrived(RideArrived event, Emitter<RideBookingState> emit) {
    final current = state;
    if (current is RideInProgress) {
      if (current.requestId != null) {
        _rideRepository.updateRideStatus(current.requestId!, 'arrived');
      }
      final km = current.distanceKm ?? 4.0;
      emit(RideArrivedState(
        from: current.from,
        to: current.to,
        driver: current.driver,
        rideType: current.rideType,
        price: current.price,
        paymentMethod: current.paymentMethod,
        requestId: current.requestId,
        pickupLatLng: current.pickupLatLng,
        dropoffLatLng: current.dropoffLatLng,
        distanceKm: km,
        durationMinutes: (km * 3).round(),
      ));
    } else if (current is DriverFoundState) {
      if (current.requestId != null) {
        _rideRepository.updateRideStatus(current.requestId!, 'arrived');
      }
      final km = current.distanceKm ?? 4.0;
      emit(RideArrivedState(
        from: current.from,
        to: current.to,
        driver: current.driver,
        rideType: current.rideType,
        price: current.price,
        paymentMethod: current.paymentMethod,
        requestId: current.requestId,
        pickupLatLng: current.pickupLatLng,
        dropoffLatLng: current.dropoffLatLng,
        distanceKm: km,
        durationMinutes: (km * 3).round(),
      ));
    }
  }

  void _onBookingCancelled(
    BookingCancelled event,
    Emitter<RideBookingState> emit,
  ) {
    final current = state;
    String? requestId;
    if (current is SearchingDriver) requestId = current.requestId;
    if (current is DriverFoundState) requestId = current.requestId;
    if (current is RideInProgress) requestId = current.requestId;
    _rideRepository.cancelSearch(requestId: requestId);
    emit(RideBookingInitial());
  }
}
