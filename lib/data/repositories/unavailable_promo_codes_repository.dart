import 'package:toktok/domain/models/promo_code.dart';
import 'package:toktok/domain/repositories/promo_codes_repository.dart';

class UnavailablePromoCodesRepository implements PromoCodesRepository {
  @override
  Future<List<PromoCode>> getAvailablePromoCodes() async => [];
  @override
  Future<List<PromoCode>> getExpiredPromoCodes() async => [];
  @override
  Future<bool> applyPromoCode(String code) async => false;
}
