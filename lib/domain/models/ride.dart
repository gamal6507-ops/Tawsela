// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

enum RideType { car, motorcycle, scooter }

extension RideTypeX on RideType {
  String get icon {
    switch (this) {
      case RideType.car:
        return '🚗';
      case RideType.motorcycle:
        return '🏍️';
      case RideType.scooter:
        return '🛵';
    }
  }

  String get displayName {
    switch (this) {
      case RideType.car:
        return 'عربية';
      case RideType.motorcycle:
        return 'موتوسيكل';
      case RideType.scooter:
        return 'اسكوتر';
    }
  }
}

class RideOption extends Equatable {
  final RideType type;
  final String name;
  final int price;
  final int etaMinutes;
  final String icon;
  final String? suffix;

  const RideOption({
    required this.type,
    required this.name,
    required this.price,
    required this.etaMinutes,
    required this.icon,
    this.suffix,
  });

  @override
  List<Object?> get props => [type, name, price, etaMinutes, icon, suffix];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'name': name,
      'price': price,
      'etaMinutes': etaMinutes,
      'icon': icon,
      'suffix': suffix,
    };
  }

  factory RideOption.fromMap(Map<String, dynamic> map) {
    return RideOption(
      type: RideType.values.byName(map['type']),
      name: map['name'] as String,
      price: map['price'] as int,
      etaMinutes: map['etaMinutes'] as int,
      icon: map['icon'] as String,
      suffix: map['suffix'] != null ? map['suffix'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RideOption.fromJson(String source) =>
      RideOption.fromMap(json.decode(source) as Map<String, dynamic>);
}
