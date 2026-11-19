import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/models/ride_request.dart';

abstract class RideBookingEvent extends Equatable {
  const RideBookingEvent();
  @override
  List<Object?> get props => [];
}

class RideBookingStarted extends RideBookingEvent {
  final String from;
  final String to;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;
  final double? distanceKm;

  const RideBookingStarted({
    required this.from,
    required this.to,
    this.pickupLatLng,
    this.dropoffLatLng,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
    from,
    to,
    pickupLatLng,
    dropoffLatLng,
    distanceKm,
  ];
}

class RideTypeSelected extends RideBookingEvent {
  final RideType rideType;
  const RideTypeSelected(this.rideType);
  @override
  List<Object?> get props => [rideType];
}

class PaymentMethodSelected extends RideBookingEvent {
  final PaymentMethod method;
  const PaymentMethodSelected(this.method);
  @override
  List<Object?> get props => [method];
}

class BookingConfirmed extends RideBookingEvent {
  const BookingConfirmed();
}

class DriverSearchStarted extends RideBookingEvent {
  const DriverSearchStarted();
}

class DriverFound extends RideBookingEvent {
  const DriverFound();
}

class RideStarted extends RideBookingEvent {
  const RideStarted();
}

class RideCompleted extends RideBookingEvent {
  const RideCompleted();
}

class RideArrived extends RideBookingEvent {
  const RideArrived();
}

class BookingCancelled extends RideBookingEvent {
  const BookingCancelled();
}

class RestoreBooking extends RideBookingEvent {
  const RestoreBooking();
}

class RemoteRideChanged extends RideBookingEvent {
  final RideRequest request;
  const RemoteRideChanged(this.request);
  @override
  List<Object?> get props => [request];
}

class BookingFailure extends RideBookingEvent {
  final String message;
  const BookingFailure(this.message);
}
