import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';

class SearchingScreen extends StatefulWidget {
  const SearchingScreen({super.key});

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBookingBloc, RideBookingState>(
      listenWhen:
          (prev, curr) =>
              curr is DriverFoundState ||
              curr is RideInProgress ||
              curr is RideArrivedState ||
              curr is RideBookingInitial,
      listener: (context, state) {
        if (state is DriverFoundState || state is RideInProgress) {
          context.go('/driver-found');
        } else if (state is RideArrivedState) {
          context.go('/arrival');
        } else if (state is RideBookingInitial) {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                Container(
                  color: AppColors.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Builder(
                                builder: (context) {
                                  final bookingState =
                                      context.watch<RideBookingBloc>().state;
                                  final icon =
                                      bookingState is SearchingDriver
                                          ? bookingState.rideType.icon
                                          : '🚗';
                                  return Text(
                                    icon,
                                    style: const TextStyle(fontSize: 50),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'بندور على كابتن',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildInfoCard('💵', 'الدفع كاش عند الوصول'),
                        const SizedBox(height: 12),
                        _buildInfoCard('📍', 'انتظار قبول سائق معتمد'),
                        BlocBuilder<RideBookingBloc, RideBookingState>(
                          builder:
                              (context, state) =>
                                  state is RideBookingError
                                      ? Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Text(state.message),
                                            TextButton(
                                              onPressed:
                                                  () => context
                                                      .read<RideBookingBloc>()
                                                      .add(
                                                        const RestoreBooking(),
                                                      ),
                                              child: const Text(
                                                'استعادة الطلب',
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      context.read<RideBookingBloc>().add(BookingCancelled());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'إلغاء البحث',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
