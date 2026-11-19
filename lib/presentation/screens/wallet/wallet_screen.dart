import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/presentation/blocs/trip_history/trip_history_cubit.dart';
import 'package:toktok/presentation/blocs/trip_history/trip_history_state.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TripHistoryCubit>().loadTrips();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مدفوعاتي')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.payments_outlined, size: 60),
            const SizedBox(height: 20),
            const Text('الدفع كاش عند الوصول', style: TextStyle(fontSize: 24)),
            const Text(
              'لا يوجد رصيد إلكتروني أو شحن أو خصم تلقائي. المبالغ التالية هي أجرة رحلاتك المسجلة، وليست إثبات تحصيل نقدي.',
            ),
            BlocBuilder<TripHistoryCubit, TripHistoryState>(
              builder: (context, state) {
                if (state is TripHistoryLoading) {
                  return const LinearProgressIndicator();
                }
                if (state is TripHistoryError) {
                  return TextButton(
                    onPressed:
                        () => context.read<TripHistoryCubit>().loadTrips(),
                    child: const Text('تعذر التحميل • حاول تاني'),
                  );
                }
                if (state is TripHistoryLoaded) {
                  return Column(
                    children: [
                      ListTile(
                        title: const Text('إجمالي آخر ١٠٠ رحلة بحد أقصى'),
                        trailing: Text(
                          '${state.totalSpent.toStringAsFixed(0)} ج',
                        ),
                      ),
                      ...state.trips.map(
                        (t) => ListTile(
                          title: Text('${t.from} ← ${t.to}'),
                          subtitle: const Text('كاش'),
                          trailing: Text('${t.price} ج'),
                        ),
                      ),
                    ],
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لسه مفيش مدفوعات مسجلة'),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
