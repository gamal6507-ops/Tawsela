import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/repositories/wallet_repository.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _repository;

  WalletCubit(this._repository) : super(WalletInitial());

  Future<void> loadWallet() async {
    emit(WalletLoading());
    try {
      final wallet = await _repository.getWallet();
      final transactions = await _repository.getTransactions();
      emit(WalletLoaded(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> topUp(double amount) async {
    final current = state is WalletLoaded ? (state as WalletLoaded) : null;
    if (current != null) {
      emit(
        WalletToppingUp(
          wallet: current.wallet,
          transactions: current.transactions,
        ),
      );
    }
    try {
      final wallet = await _repository.topUp(amount);
      final transactions = await _repository.getTransactions();
      emit(WalletToppedUp(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }
}
