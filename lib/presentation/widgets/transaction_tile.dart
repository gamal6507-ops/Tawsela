import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/domain/models/transaction.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.ride:
        return Icons.directions_car_outlined;
      case TransactionType.topup:
        return Icons.add_circle_outline;
      case TransactionType.withdraw:
        return Icons.remove_circle_outline;
      case TransactionType.promo:
        return Icons.local_offer_outlined;
    }
  }

  Color _colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.ride:
        return AppColors.error;
      case TransactionType.topup:
        return AppColors.success;
      case TransactionType.withdraw:
        return AppColors.error;
      case TransactionType.promo:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _colorForType(transaction.type).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForType(transaction.type),
              size: 20,
              color: _colorForType(transaction.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (transaction.subtitle != null)
                  Text(
                    transaction.subtitle!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${transaction.amount.toStringAsFixed(0)} ج',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.success : AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormat('MM/dd', 'ar').format(transaction.date),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
