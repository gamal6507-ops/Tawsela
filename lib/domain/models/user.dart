// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final double rating;
  final int totalTrips;
  final double totalKm;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.avatarUrl,
    this.dateOfBirth,
    this.rating = 0.0,
    this.totalTrips = 0,
    this.totalKm = 0,
  });

  User copyWith({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    DateTime? dateOfBirth,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      rating: rating,
      totalTrips: totalTrips,
      totalKm: totalKm,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    avatarUrl,
    dateOfBirth,
    rating,
    totalTrips,
    totalKm,
  ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'rating': rating,
      'totalTrips': totalTrips,
      'totalKm': totalKm,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] != null ? map['avatarUrl'] as String : null,
      dateOfBirth:
          map['dateOfBirth'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] as int)
              : null,
      rating: (map['rating'] as num).toDouble(),
      totalTrips: map['totalTrips'] as int,
      totalKm: (map['totalKm'] as num).toDouble(),
    );
  }
}
