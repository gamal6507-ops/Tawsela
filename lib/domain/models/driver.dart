// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class Driver extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String plateNumber;
  final double rating;
  final String? avatarUrl;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.plateNumber,
    this.rating = 0.0,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, name, phone, plateNumber, rating, avatarUrl];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'plateNumber': plateNumber,
      'rating': rating,
      'avatarUrl': avatarUrl,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      plateNumber: map['plateNumber'] as String,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      avatarUrl: map['avatarUrl'] != null ? map['avatarUrl'] as String : null,
    );
  }
}
