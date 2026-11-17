import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';
import 'package:toktok/presentation/widgets/star_rating.dart';
import 'package:toktok/presentation/widgets/tawsela_map_widget.dart';

class DriverFoundScreen extends StatelessWidget {
  const DriverFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBookingBloc, RideBookingState>(
      listenWhen: (prev, curr) => prev is DriverFoundState && curr is! DriverFoundState,
      listener: (context, state) {
        if (state is RideArrivedState) {
          context.push('/arrival');
        } else if (state is RideBookingInitial) {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: BlocBuilder<RideBookingBloc, RideBookingState>(
          builder: (context, state) {
            if (state is! DriverFoundState) {
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
                          children: [
                            const SizedBox(height: 40),
                            SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  TawselaMapWidget(
                                    height: 220,
                                    center: state.pickupLatLng ??
                                        const LatLng(30.0444, 31.2357),
                                    zoom: 14.0,
                                    pickupPoint: state.pickupLatLng ??
                                        const LatLng(30.0444, 31.2357),
                                    dropoffPoint: state.dropoffLatLng,
                                    driverPoint: LatLng(
                                      (state.pickupLatLng?.latitude ?? 30.0444) +
                                          0.0036,
                                      (state.pickupLatLng?.longitude ??
                                              31.2357) +
                                          0.0033,
                                    ),
                                    driverIcon: state.rideType.icon,
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${state.price} ج',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 20),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'وصول خلال ${state.driver.name.isNotEmpty ? '5' : '5'} دقيقة',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDriverCard(state),
                            const SizedBox(height: 20),
                            _buildRouteCard(state),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => context.read<RideBookingBloc>().add(RideArrived()),
                                child: const Text('وصلت ✓'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  context.read<RideBookingBloc>().add(BookingCancelled());
                                  context.go('/home');
                                },
                                child: const Text('إلغاء'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverFoundState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            child: Text(
              state.driver.name.isNotEmpty ? state.driver.name[0] : '?',
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.driver.name,
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    StarRating(rating: state.driver.rating.round(), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      state.driver.rating.toString(),
                      style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'اللوحة: ${state.driver.plateNumber}',
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildCircleButton(Icons.call, Colors.green),
              const SizedBox(height: 8),
              _buildCircleButton(Icons.chat_bubble_outline, AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildRouteCard(DriverFoundState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
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
                Text(state.from, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Text(state.to, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
