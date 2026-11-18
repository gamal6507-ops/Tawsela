import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/domain/models/promo_code.dart';

class PromoCodeCard extends StatelessWidget {
  final PromoCode promoCode;
  final VoidCallback? onApply;

  const PromoCodeCard({
    super.key,
    required this.promoCode,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = promoCode.gradientColors != null && promoCode.gradientColors!.isNotEmpty
        ? promoCode.gradientColors![0]
        : [0xFFF5B840, 0xFFF5A623];
    final gradientColors = Color(colors[0]).withValues(alpha: promoCode.isActive ? 1 : 0.3);
    final gradientColors2 = Color(colors.length > 1 ? colors[1] : colors[0]).withValues(alpha: promoCode.isActive ? 1 : 0.3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientColors, gradientColors2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  promoCode.code,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                promoCode.discountText,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            promoCode.condition,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          if (promoCode.expiryDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'ينتهي في ${promoCode.expiryDate.toString().substring(0, 10)}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
          if (promoCode.isActive && onApply != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onApply,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'تطبيق الكود',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
