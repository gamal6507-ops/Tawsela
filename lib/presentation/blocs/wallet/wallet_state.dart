import 'package:equatable/equatable.dart';
import 'package:toktok/domain/models/transaction.dart';
import 'package:toktok/domain/models/wallet.dart';

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}
class WalletLoading extends WalletState {}
class WalletLoaded extends WalletState {
  final Wallet wallet;
  final List<Transaction> transactions;
  const WalletLoaded({required this.wallet, required this.transactions});
  @override
  List<Object?> get props => [wallet, transactions];
}
class WalletToppingUp extends WalletState {
  final Wallet wallet;
  final List<Transaction> transactions;
  const WalletToppingUp({required this.wallet, required this.transactions});
  @override
  List<Object?> get props => [wallet, transactions];
}
class WalletToppedUp extends WalletState {
  final Wallet wallet;
  final List<Transaction> transactions;
  const WalletToppedUp({required this.wallet, required this.transactions});
  @override
  List<Object?> get props => [wallet, transactions];
}
class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
  @override
  List<Object?> get props => [message];
}
