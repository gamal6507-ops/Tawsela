import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';

class TawselaLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;

  const TawselaLogo({
    super.key,
    this.size = 84,
    this.showWordmark = true,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = size * 0.26;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.32),
                blurRadius: size * 0.28,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              'assets/images/tawsela_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.16),
          Text(
            'توصيلة',
            style: GoogleFonts.cairo(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'مشوارك أسهل وأسرع في مصر',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
