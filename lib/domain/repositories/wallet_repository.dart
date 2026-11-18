import '../models/transaction.dart';
import '../models/wallet.dart';

abstract class WalletRepository {
  Future<Wallet> getWallet();
  Future<List<Transaction>> getTransactions();
  Future<Wallet> topUp(double amount);
  Future<Wallet> deduct(double amount);
}
