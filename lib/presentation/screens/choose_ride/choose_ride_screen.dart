import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';
import 'package:toktok/presentation/widgets/ride_type_card.dart';
import 'package:toktok/presentation/widgets/primary_button.dart';

class ChooseRideScreen extends StatelessWidget {
  const ChooseRideScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('اختار رحلتك')),
    body: BlocConsumer<RideBookingBloc, RideBookingState>(
      listener: (context, state) {
        if (state is SearchingDriver) context.go('/searching');
      },
      builder: (context, state) {
        if (state is RideBookingError) {
          return Center(child: Text(state.message));
        }
        if (state is! SelectingRide) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${state.from} ← ${state.to}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  '${state.distanceKm ?? 0} كم تقريبياً • المسافة بخط مباشر وليست مسار طريق',
                ),
                const SizedBox(height: 20),
                ...state.rideOptions.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RideTypeCard(
                      option: option,
                      isSelected: state.selectedType == option.type,
                      onTap: () {
                        if (!state.isSubmitting) {
                          context.read<RideBookingBloc>().add(
                            RideTypeSelected(option.type),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.payments_outlined),
                  title: Text('كاش عند الوصول'),
                  subtitle: Text(
                    'لا توجد بطاقات أو محفظة إلكترونية في هذه النسخة',
                  ),
                ),
                const Text(
                  'الأجرة المعروضة متفق عليها عند قبول السائق. لا يتم خصم أي مبلغ إلكتروني.',
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'اطلب الرحلة • ${state.selectedPrice} ج',
                  isLoading: state.isSubmitting,
                  onPressed:
                      () => context.read<RideBookingBloc>().add(
                        const BookingConfirmed(),
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
