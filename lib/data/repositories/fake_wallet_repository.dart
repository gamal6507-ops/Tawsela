import 'package:toktok/domain/models/transaction.dart';
import 'package:toktok/domain/models/wallet.dart';
import 'package:toktok/domain/repositories/wallet_repository.dart';

class FakeWalletRepository implements WalletRepository {
  double _balance = 150.0;
  final List<Transaction> _transactions = [
    Transaction(
      id: 't1',
      title: 'شحن رصيد',
      amount: 200,
      type: TransactionType.topup,
      date: DateTime.now().subtract(const Duration(days: 2)),
      subtitle: 'فوري',
    ),
    Transaction(
      id: 't2',
      title: 'رحلة - اسكوتر',
      amount: -15,
      type: TransactionType.ride,
      date: DateTime.now().subtract(const Duration(days: 1)),
      subtitle: 'من المول إلى البيت',
    ),
    Transaction(
      id: 't3',
      title: 'كود خصم',
      amount: 50,
      type: TransactionType.promo,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      subtitle: 'TAWSELA50',
    ),
    Transaction(
      id: 't4',
      title: 'رحلة - عربية',
      amount: -25,
      type: TransactionType.ride,
      date: DateTime.now().subtract(const Duration(hours: 3)),
      subtitle: 'من البيت إلى الشغل',
    ),
  ];

  @override
  Future<Wallet> getWallet() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Wallet(balance: _balance);
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_transactions);
  }

  @override
  Future<Wallet> topUp(double amount) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _balance += amount;
    _transactions.insert(0, Transaction(
      id: 't${_transactions.length + 1}',
      title: 'شحن رصيد',
      amount: amount,
      type: TransactionType.topup,
      date: DateTime.now(),
      subtitle: 'شحن يدوي',
    ));
    return Wallet(balance: _balance);
  }

  @override
  Future<Wallet> deduct(double amount) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _balance -= amount;
    return Wallet(balance: _balance);
  }
}
