import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/domain/models/driver.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/trip.dart';

abstract class RideBookingState extends Equatable {
  const RideBookingState();
  @override
  List<Object?> get props => [];
}

class RideBookingInitial extends RideBookingState {}

class SelectingRide extends RideBookingState {
  final String from;
  final String to;
  final List<RideOption> rideOptions;
  final RideType selectedType;
  final PaymentMethod selectedPayment;
  final int selectedPrice;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;
  final double? distanceKm;

  const SelectingRide({
    required this.from,
    required this.to,
    required this.rideOptions,
    this.selectedType = RideType.car,
    this.selectedPayment = PaymentMethod.cash,
    this.selectedPrice = 25,
    this.pickupLatLng,
    this.dropoffLatLng,
    this.distanceKm,
    this.isSubmitting = false,
    this.error,
  });

  final bool isSubmitting;
  final String? error;

  SelectingRide copyWith({
    RideType? selectedType,
    PaymentMethod? selectedPayment,
    int? selectedPrice,
    bool? isSubmitting,
    String? error,
  }) {
    return SelectingRide(
      from: from,
      to: to,
      rideOptions: rideOptions,
      selectedType: selectedType ?? this.selectedType,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      selectedPrice: selectedPrice ?? this.selectedPrice,
      pickupLatLng: pickupLatLng,
      dropoffLatLng: dropoffLatLng,
      distanceKm: distanceKm,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    from,
    to,
    rideOptions,
    selectedType,
    selectedPayment,
    selectedPrice,
    pickupLatLng,
    dropoffLatLng,
    distanceKm,
    isSubmitting,
    error,
  ];
}

class SearchingDriver extends RideBookingState {
  final String from;
  final String to;
  final RideType rideType;
  final int price;
  final PaymentMethod paymentMethod;
  final String? requestId;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;
  final double? distanceKm;

  const SearchingDriver({
    required this.from,
    required this.to,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    this.requestId,
    this.pickupLatLng,
    this.dropoffLatLng,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
    from,
    to,
    rideType,
    price,
    paymentMethod,
    requestId,
    pickupLatLng,
    dropoffLatLng,
    distanceKm,
  ];
}

class DriverFoundState extends RideBookingState {
  final String from;
  final String to;
  final Driver driver;
  final RideType rideType;
  final int price;
  final PaymentMethod paymentMethod;
  final String? requestId;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;
  final double? distanceKm;

  const DriverFoundState({
    required this.from,
    required this.to,
    required this.driver,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    this.requestId,
    this.pickupLatLng,
    this.dropoffLatLng,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
    from,
    to,
    driver,
    rideType,
    price,
    paymentMethod,
    requestId,
    pickupLatLng,
    dropoffLatLng,
    distanceKm,
  ];
}

class RideInProgress extends RideBookingState {
  final String from;
  final String to;
  final Driver driver;
  final RideType rideType;
  final int price;
  final PaymentMethod paymentMethod;
  final String? requestId;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;
  final double? distanceKm;

  const RideInProgress({
    required this.from,
    required this.to,
    required this.driver,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    this.requestId,
    this.pickupLatLng,
    this.dropoffLatLng,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
    from,
    to,
    driver,
    rideType,
    price,
    paymentMethod,
    requestId,
    pickupLatLng,
    dropoffLatLng,
    distanceKm,
  ];
}

class RideArrivedState extends RideBookingState {
  final String from;
  final String to;
  final Driver driver;
  final RideType rideType;
  final int price;
  final PaymentMethod paymentMethod;
  final String? requestId;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;
  final double distanceKm;
  final int durationMinutes;

  const RideArrivedState({
    required this.from,
    required this.to,
    required this.driver,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    this.requestId,
    this.pickupLatLng,
    this.dropoffLatLng,
    this.distanceKm = 4.0,
    this.durationMinutes = 12,
  });

  @override
  List<Object?> get props => [
    from,
    to,
    driver,
    rideType,
    price,
    paymentMethod,
    requestId,
    pickupLatLng,
    dropoffLatLng,
    distanceKm,
    durationMinutes,
  ];
}

class RideBookingError extends RideBookingState {
  final String message;
  const RideBookingError(this.message);
  @override
  List<Object?> get props => [message];
}
