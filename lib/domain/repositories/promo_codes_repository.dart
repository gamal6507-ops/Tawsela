import '../models/promo_code.dart';

abstract class PromoCodesRepository {
  Future<List<PromoCode>> getAvailablePromoCodes();
  Future<List<PromoCode>> getExpiredPromoCodes();
  Future<bool> applyPromoCode(String code);
}
