// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class PromoCode extends Equatable {
  final String code;
  final String discountText;
  final String condition;
  final DateTime? expiryDate;
  final bool isActive;
  final List<List<int>>? gradientColors;

  const PromoCode({
    required this.code,
    required this.discountText,
    required this.condition,
    this.expiryDate,
    this.isActive = true,
    this.gradientColors,
  });

  @override
  List<Object?> get props => [
    code,
    discountText,
    condition,
    expiryDate,
    isActive,
    gradientColors,
  ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'discountText': discountText,
      'condition': condition,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'isActive': isActive,
      'gradientColors': gradientColors,
    };
  }

  factory PromoCode.fromMap(Map<String, dynamic> map) {
    return PromoCode(
      code: map['code'] as String,
      discountText: map['discountText'] as String,
      condition: map['condition'] as String,
      expiryDate:
          map['expiryDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] as int)
              : null,
      isActive: map['isActive'] as bool,
      gradientColors:
          map['gradientColors'] != null
              ? List<List<int>>.from(
                (map['gradientColors'] as List).map<List<int>>(
                  (x) => (x as List).map((v) => (v as num).toInt()).toList(),
                ),
              )
              : null,
    );
  }
}
