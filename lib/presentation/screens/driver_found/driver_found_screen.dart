import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:toktok/domain/models/driver.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';
import 'package:toktok/presentation/widgets/tawsela_map_widget.dart';

class DriverFoundScreen extends StatelessWidget {
  const DriverFoundScreen({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RideBookingBloc, RideBookingState>(
    listener: (context, state) {
      if (state is RideArrivedState) context.go('/arrival');
      if (state is RideBookingInitial) context.go('/home');
    },
    builder: (context, state) {
      if (state is RideBookingError) {
        return Scaffold(
          appBar: AppBar(title: const Text('متابعة الرحلة')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                TextButton(
                  onPressed:
                      () => context.read<RideBookingBloc>().add(
                        const RestoreBooking(),
                      ),
                  child: const Text('استعادة الرحلة'),
                ),
              ],
            ),
          ),
        );
      }
      final accepted = state is DriverFoundState ? state : null;
      final progress = state is RideInProgress ? state : null;
      final Driver? driver = accepted?.driver ?? progress?.driver;
      final id = accepted?.requestId ?? progress?.requestId;
      if (driver == null || id == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final pickup = accepted?.pickupLatLng ?? progress?.pickupLatLng;
      final dropoff = accepted?.dropoffLatLng ?? progress?.dropoffLatLng;
      final from = accepted?.from ?? progress!.from;
      final to = accepted?.to ?? progress!.to;
      final price = accepted?.price ?? progress!.price;
      return Scaffold(
        appBar: AppBar(
          title: Text(progress != null ? 'رحلتك بدأت' : 'السائق قبل الرحلة'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('ride_requests')
                          .doc(id)
                          .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    final at = data?['locationAt'] as Timestamp?;
                    final fresh =
                        at != null &&
                        DateTime.now().difference(at.toDate()).inMinutes < 2;
                    final lat = data?['driverLat'] as num?;
                    final lng = data?['driverLng'] as num?;
                    return Column(
                      children: [
                        TawselaMapWidget(
                          center: pickup ?? const LatLng(30.0444, 31.2357),
                          pickupPoint: pickup,
                          dropoffPoint: dropoff,
                          driverPoint:
                              fresh && lat != null && lng != null
                                  ? LatLng(lat.toDouble(), lng.toDouble())
                                  : null,
                        ),
                        Text(
                          fresh
                              ? 'آخر موقع شاركه السائق: ${at.toDate().hour}:${at.toDate().minute.toString().padLeft(2, '0')}'
                              : 'السائق لم يشارك موقعاً حديثاً بعد',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('اللوحة: ${driver.plateNumber}'),
                Text('$from ← $to'),
                Text('$price ج • كاش عند الوصول'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final launched = await launchUrl(
                      Uri(scheme: 'tel', path: driver.phone),
                    );
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('رقم السائق: ${driver.phone}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('اتصل بالسائق'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/chat/$id'),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('محادثة السائق'),
                ),
                const Text(
                  'حالة الرحلة تتحدّث من السائق. لا يوجد وقت وصول مضمون.',
                ),
                if (accepted != null)
                  TextButton(
                    onPressed:
                        () => context.read<RideBookingBloc>().add(
                          const BookingCancelled(),
                        ),
                    child: const Text('إلغاء الرحلة'),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
