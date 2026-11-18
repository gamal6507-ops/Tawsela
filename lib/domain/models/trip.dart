// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

import 'ride.dart';

enum PaymentMethod { wallet, card }

class Trip extends Equatable {
  final String id;
  final String from;
  final String to;
  final RideType rideType;
  final int price;
  final String driverName;
  final double driverRating;
  final String driverPlate;
  final DateTime date;
  final int durationMinutes;
  final double distanceKm;
  final PaymentMethod paymentMethod;
  final int? userRating;

  const Trip({
    required this.id,
    required this.from,
    required this.to,
    required this.rideType,
    required this.price,
    required this.driverName,
    required this.driverRating,
    required this.driverPlate,
    required this.date,
    required this.durationMinutes,
    required this.distanceKm,
    required this.paymentMethod,
    this.userRating,
  });

  Trip copyWith({int? userRating}) {
    return Trip(
      id: id,
      from: from,
      to: to,
      rideType: rideType,
      price: price,
      driverName: driverName,
      driverRating: driverRating,
      driverPlate: driverPlate,
      date: date,
      durationMinutes: durationMinutes,
      distanceKm: distanceKm,
      paymentMethod: paymentMethod,
      userRating: userRating ?? this.userRating,
    );
  }

  @override
  List<Object?> get props => [
    id,
    from,
    to,
    rideType,
    price,
    driverName,
    driverRating,
    driverPlate,
    date,
    durationMinutes,
    distanceKm,
    paymentMethod,
    userRating,
  ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'from': from,
      'to': to,
      'rideType': rideType.name,
      'price': price,
      'driverName': driverName,
      'driverRating': driverRating,
      'driverPlate': driverPlate,
      'date': date.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
      'paymentMethod': paymentMethod.name,
      'userRating': userRating,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      rideType: RideType.values.byName(map['rideType']),
      price: map['price'] as int,
      driverName: map['driverName'] as String,
      driverRating: map['driverRating'] as double,
      driverPlate: map['driverPlate'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      durationMinutes: map['durationMinutes'] as int,
      distanceKm: map['distanceKm'] as double,
      paymentMethod: PaymentMethod.values.byName(map['paymentMethod']),
      userRating: map['userRating'] != null ? map['userRating'] as int : null,
    );
  }
}
