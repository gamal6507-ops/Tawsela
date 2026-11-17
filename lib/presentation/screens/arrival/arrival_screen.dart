import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';
import 'package:toktok/domain/models/trip.dart';

class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBookingBloc, RideBookingState>(
      listener: (context, state) {
        if (state is RideBookingInitial) {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: BlocBuilder<RideBookingBloc, RideBookingState>(
          builder: (context, state) {
            if (state is! RideArrivedState) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'وصلت بالسلامة! 🎉',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildDetailsCard(state),
                      const SizedBox(height: 20),
                      _buildPaymentInfo(state.paymentMethod),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/rate-trip');
                          },
                          child: Text('قيم الرحلة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          context.read<RideBookingBloc>().add(BookingCancelled());
                          context.go('/home');
                        },
                        child: Text('تخطي', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsCard(RideArrivedState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildDetailRow('المسافة', '${state.distanceKm.toStringAsFixed(1)} كم'),
          const Divider(color: AppColors.border),
          _buildDetailRow('المدة', '${state.durationMinutes} دقيقة'),
          const Divider(color: AppColors.border),
          _buildDetailRow('الإجمالي', '${state.price} ج', valueColor: AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 15, color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(PaymentMethod method) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            method == PaymentMethod.wallet ? Icons.account_balance_wallet : Icons.credit_card,
            color: AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            method == PaymentMethod.wallet ? 'تم الدفع من المحفظة' : 'تم الدفع بالبطاقة',
            style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
