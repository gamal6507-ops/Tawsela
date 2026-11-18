import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/models/promo_code.dart';
import 'package:toktok/domain/repositories/promo_codes_repository.dart';
import 'promo_codes_state.dart';

class PromoCodesCubit extends Cubit<PromoCodesState> {
  final PromoCodesRepository _repository;

  PromoCodesCubit(this._repository) : super(PromoCodesInitial());

  Future<void> loadPromoCodes() async {
    emit(PromoCodesLoading());
    try {
      final available = await _repository.getAvailablePromoCodes();
      final expired = await _repository.getExpiredPromoCodes();
      emit(PromoCodesLoaded(available: available, expired: expired));
    } catch (e) {
      emit(PromoCodeFailed(message: e.toString(), available: const [], expired: const []));
    }
  }

  Future<void> applyPromoCode(String code) async {
    final current = state;
    List<PromoCode> available = [];
    List<PromoCode> expired = [];
    if (current is PromoCodesLoaded) {
      available = current.available;
      expired = current.expired;
    } else if (current is PromoCodeApplying) {
      available = current.available;
      expired = current.expired;
    } else if (current is PromoCodeApplied) {
      available = current.available;
      expired = current.expired;
    } else if (current is PromoCodeFailed) {
      available = current.available;
      expired = current.expired;
    }

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      emit(PromoCodeFailed(
        message: 'من فضلك ادخل كود الخصم',
        available: available,
        expired: expired,
      ));
      return;
    }

    emit(PromoCodeApplying(available: available, expired: expired));
    try {
      final success = await _repository.applyPromoCode(trimmedCode);
      if (success) {
        emit(PromoCodeApplied(
          'تم تطبيق الكود بنجاح!',
          available: available,
          expired: expired,
        ));
      } else {
        emit(PromoCodeFailed(
          message: 'الكود غير صالح أو منتهي الصلاحية',
          available: available,
          expired: expired,
        ));
      }
    } catch (e) {
      emit(PromoCodeFailed(
        message: e.toString(),
        available: available,
        expired: expired,
      ));
    }
  }
}
