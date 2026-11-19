import 'package:toktok/domain/models/transaction.dart';
import 'package:toktok/domain/models/wallet.dart';
import 'package:toktok/domain/repositories/wallet_repository.dart';

class CashWalletRepository implements WalletRepository {
  @override
  Future<Wallet> getWallet() async => const Wallet(balance: 0);
  @override
  Future<List<Transaction>> getTransactions() async => [];
  @override
  Future<Wallet> topUp(double amount) => Future.error(
    StateError('الشحن الإلكتروني غير متاح. ادفع كاش عند الوصول'),
  );
  @override
  Future<Wallet> deduct(double amount) =>
      Future.error(StateError('لا توجد محفظة إلكترونية في هذه النسخة'));
}
