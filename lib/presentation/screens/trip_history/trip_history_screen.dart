import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/trip_history/trip_history_cubit.dart';
import 'package:toktok/presentation/blocs/trip_history/trip_history_state.dart';
import 'package:toktok/presentation/widgets/trip_history_card.dart';
import 'package:toktok/presentation/widgets/empty_state.dart';
import 'package:go_router/go_router.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TripHistoryCubit>().loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: BlocBuilder<TripHistoryCubit, TripHistoryState>(
                    builder: (context, state) {
                      final count =
                          state is TripHistoryLoaded ? state.trips.length : 0;
                      final total =
                          state is TripHistoryLoaded ? state.totalSpent : 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سجل الرحلات',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count رحلة — إجمالي المصروف: ${total.toStringAsFixed(0)} ج',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: BlocBuilder<TripHistoryCubit, TripHistoryState>(
                    builder: (context, state) {
                      if (state is TripHistoryLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        );
                      }
                      if (state is TripHistoryEmpty) {
                        return const EmptyState(
                          icon: Icons.history,
                          title: 'لسه مفيش رحلات',
                          subtitle: 'ابدأ أول رحلة لك دلوقتي!',
                        );
                      }
                      if (state is TripHistoryLoaded) {
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.trips.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final trip = state.trips[index];
                            return TripHistoryCard(
                              trip: state.trips[index],
                              onRebook:
                                  () => context.go(
                                    '/home',
                                    extra: {'from': trip.from, 'to': trip.to},
                                  ),
                              onDetails:
                                  () => showDialog<void>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('تفاصيل الرحلة'),
                                          content: SelectableText(
                                            'رقم الرحلة: ${trip.id}\n${trip.from} ← ${trip.to}\nالسائق: ${trip.driverName}\nاللوحة: ${trip.driverPlate}\nالأجرة: ${trip.price} ج كاش\nالمسافة التقريبية: ${trip.distanceKm} كم\nالمدة: ${trip.durationMinutes} دقيقة',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('إغلاق'),
                                            ),
                                          ],
                                        ),
                                  ),
                            );
                          },
                        );
                      }
                      if (state is TripHistoryError) {
                        return Center(
                          child: TextButton(
                            onPressed:
                                () =>
                                    context
                                        .read<TripHistoryCubit>()
                                        .loadTrips(),
                            child: const Text('تعذر تحميل الرحلات • حاول تاني'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
