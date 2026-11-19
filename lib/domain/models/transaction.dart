// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

enum TransactionType { ride, topup, withdraw, promo }

class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? subtitle;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.subtitle,
  });

  @override
  List<Object?> get props => [id, title, amount, type, date, subtitle];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'subtitle': subtitle,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.byName(map['type']),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      subtitle: map['subtitle'] != null ? map['subtitle'] as String : null,
    );
  }
}
