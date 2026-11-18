// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final double balance;
  final String currency;

  const Wallet({required this.balance, this.currency = 'ج'});

  Wallet copyWith({double? balance}) {
    return Wallet(balance: balance ?? this.balance, currency: currency);
  }

  @override
  List<Object?> get props => [balance, currency];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'balance': balance, 'currency': currency};
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      balance: map['balance'] as double,
      currency: map['currency'] as String,
    );
  }
}
