import 'package:toktok/domain/models/promo_code.dart';
import 'package:toktok/domain/repositories/promo_codes_repository.dart';

class FakePromoCodesRepository implements PromoCodesRepository {
  final List<PromoCode> _available = [
    const PromoCode(
      code: 'TAWSELA50',
      discountText: 'خصم 50 ج',
      condition: 'للطلبات فوق 100 ج',
      expiryDate: null,
      isActive: true,
      gradientColors: [
        [0xFFF5B840, 0xFFF5A623],
      ],
    ),
    const PromoCode(
      code: 'NEWUSER',
      discountText: 'خصم 25%',
      condition: 'للمستخدمين الجدد فقط',
      expiryDate: null,
      isActive: true,
      gradientColors: [
        [0xFF6C63FF, 0xFF5A52D5],
      ],
    ),
    const PromoCode(
      code: 'SPECIAL20',
      discountText: 'خصم 20%',
      condition: 'على الرحلات الكومفورت',
      expiryDate: null,
      isActive: true,
      gradientColors: [
        [0xFF4CAF50, 0xFF388E3C],
      ],
    ),
  ];

  final List<PromoCode> _expired = [
    const PromoCode(
      code: 'SUMMER23',
      discountText: 'خصم 30%',
      condition: 'عرض الصيف',
      expiryDate: null,
      isActive: false,
      gradientColors: [
        [0xFF78909C, 0xFF546E7A],
      ],
    ),
  ];

  @override
  Future<List<PromoCode>> getAvailablePromoCodes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_available);
  }

  @override
  Future<List<PromoCode>> getExpiredPromoCodes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_expired);
  }

  @override
  Future<bool> applyPromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final normalized = code.trim().toUpperCase();
    return _available.any((p) => p.code == normalized);
  }
}
