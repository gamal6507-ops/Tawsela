import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';
import 'package:toktok/presentation/widgets/ride_type_card.dart';
import 'package:toktok/presentation/widgets/primary_button.dart';

class ChooseRideScreen extends StatelessWidget {
  const ChooseRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختار وسيلة المواصلات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<RideBookingBloc, RideBookingState>(
        listenWhen: (prev, curr) => curr is SearchingDriver || (prev is! RideBookingInitial && curr is RideBookingInitial),
        listener: (context, state) {
          if (state is SearchingDriver) {
            context.push('/searching');
          } else if (state is RideBookingInitial) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is! SelectingRide) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRouteSummary(state.from, state.to),
                          const SizedBox(height: 24),
                          Text(
                            'نوع المركبة',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...state.rideOptions.map((option) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RideTypeCard(
                              option: option,
                              isSelected: state.selectedType == option.type,
                              onTap: () => context.read<RideBookingBloc>().add(RideTypeSelected(option.type)),
                            ),
                          )),
                          const SizedBox(height: 24),
                          Text(
                            'طريقة الدفع',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentOption(
                            context,
                            icon: Icons.account_balance_wallet,
                            label: 'محفظة التطبيق',
                            subtitle: 'الرصيد الحالي: 150 ج',
                            isSelected: state.selectedPayment == PaymentMethod.wallet,
                            onTap: () => context.read<RideBookingBloc>().add(PaymentMethodSelected(PaymentMethod.wallet)),
                          ),
                          const SizedBox(height: 10),
                          _buildPaymentOption(
                            context,
                            icon: Icons.credit_card,
                            label: 'بطاقة ائتمان',
                            subtitle: '**** 1234',
                            isSelected: state.selectedPayment == PaymentMethod.card,
                            onTap: () => context.read<RideBookingBloc>().add(PaymentMethodSelected(PaymentMethod.card)),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: PrimaryButton(
                        text: 'احجز رحلة — ${state.selectedPrice} ج',
                        onPressed: () => context.read<RideBookingBloc>().add(BookingConfirmed()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteSummary(String from, String to) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
              Container(width: 2, height: 24, color: AppColors.border),
              Icon(Icons.location_on, color: AppColors.error, size: 16),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(from, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Text(to, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.accent : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
