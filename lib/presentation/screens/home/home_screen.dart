import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/core/services/location_service.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_state.dart';
import 'package:toktok/presentation/widgets/tawsela_map_widget.dart';
import 'package:toktok/presentation/widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  const HomeScreen({super.key, this.initialFrom, this.initialTo});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _locations = LocationService();
  final _map = MapController();
  LatLng? _pickup;
  LatLng? _dropoff;
  bool _pickStart = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _from.text = widget.initialFrom ?? '';
    _to.text = widget.initialTo ?? '';
    context.read<RideBookingBloc>().add(const RestoreBooking());
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _tap(LatLng point) async {
    if (!_locations.isInsideEgypt(point)) return;
    setState(() {
      if (_pickStart) {
        _pickup = point;
        _from.text =
            'نقطة الانطلاق (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
        _pickStart = false;
      } else {
        _dropoff = point;
        _to.text =
            'الوجهة (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
      }
      _error = null;
    });
  }

  Future<void> _gps() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final point = await _locations.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _pickup = point;
        _from.text =
            'موقعي (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
        _pickStart = false;
      });
      _map.move(point, 15);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error =
                  'تعذر تحديد موقعك. فعّل إذن الموقع أو اختار نقطة الانطلاق من الخريطة',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolve(bool pickup) async {
    final text = pickup ? _from.text : _to.text;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final point = await _locations.getLatLngFromAddress(text);
      if (!mounted) return;
      if ((pickup ? _from.text : _to.text) != text) return;
      if (point == null) {
        setState(() => _error = 'مش لاقيين العنوان. اختاره من الخريطة');
        return;
      }
      setState(() {
        if (pickup) {
          _pickup = point;
        } else {
          _dropoff = point;
        }
      });
      _map.move(point, 14);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'البحث غير متاح الآن. تقدر تحدد المكان على الخريطة',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _book() {
    if (_pickup == null || _dropoff == null) {
      setState(
        () =>
            _error =
                'ابحث عن كل عنوان بعلامة البحث أو اختار النقطتين على الخريطة',
      );
      return;
    }
    final km = _locations.calculateDistanceKm(_pickup!, _dropoff!);
    if (km > 200) {
      setState(() => _error = 'الحد الأقصى للمسافة التقريبية ٢٠٠ كم');
      return;
    }
    context.read<RideBookingBloc>().add(
      RideBookingStarted(
        from: _from.text.trim(),
        to: _to.text.trim(),
        pickupLatLng: _pickup,
        dropoffLatLng: _dropoff,
        distanceKm: km,
      ),
    );
    context.push('/choose-ride');
  }

  void _navigate(RideBookingState state) {
    if (state is SearchingDriver) context.go('/searching');
    if (state is DriverFoundState || state is RideInProgress) {
      context.go('/driver-found');
    }
    if (state is RideArrivedState) context.go('/arrival');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'توصيلة • نوصلك ببساطة',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'الإشعارات',
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('اختار منين ورايح فين. الدفع كاش عند الوصول.'),
              const SizedBox(height: 20),
              TawselaMapWidget(
                mapController: _map,
                height: 280,
                pickupPoint: _pickup,
                dropoffPoint: _dropoff,
                onTap: _busy ? null : _tap,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('حدد الانطلاق'),
                    selected: _pickStart,
                    onSelected: (_) => setState(() => _pickStart = true),
                  ),
                  ChoiceChip(
                    label: const Text('حدد الوجهة'),
                    selected: !_pickStart,
                    onSelected: (_) => setState(() => _pickStart = false),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _gps,
                    icon: const Icon(Icons.my_location),
                    label: const Text('موقعي الحالي'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _field(_from, true),
              const SizedBox(height: 12),
              _field(_to, false),
              const SizedBox(height: 10),
              const Text(
                'بعد البحث، راجع علامة المكان على الخريطة. الخط المعروض والمسافة تقريبيان، وليس مسار طريق.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: 20),
              BlocBuilder<RideBookingBloc, RideBookingState>(
                builder: (context, state) {
                  final active =
                      state is SearchingDriver ||
                      state is DriverFoundState ||
                      state is RideInProgress ||
                      state is RideArrivedState;
                  return PrimaryButton(
                    text: active ? 'متابعة رحلتي الحالية' : 'اختار رحلتك',
                    isLoading: _busy,
                    onPressed: active ? () => _navigate(state) : _book,
                  );
                },
              ),
              BlocBuilder<RideBookingBloc, RideBookingState>(
                builder:
                    (context, state) =>
                        state is RideBookingError
                            ? Column(
                              children: [
                                Text(state.message),
                                TextButton(
                                  onPressed:
                                      () => context.read<RideBookingBloc>().add(
                                        const RestoreBooking(),
                                      ),
                                  child: const Text('استعادة الرحلة الحالية'),
                                ),
                              ],
                            )
                            : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.push('/driver'),
                icon: const Icon(Icons.drive_eta),
                label: const Text('مساحة السائق'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _field(TextEditingController controller, bool pickup) => TextField(
    readOnly: _busy,
    controller: controller,
    maxLength: 200,
    onChanged:
        (_) => setState(() {
          if (pickup) {
            _pickup = null;
          } else {
            _dropoff = null;
          }
        }),
    decoration: InputDecoration(
      labelText: pickup ? 'منين' : 'رايح فين',
      counterText: '',
      suffixIcon: IconButton(
        tooltip: 'ابحث عن العنوان',
        onPressed: _busy ? null : () => _resolve(pickup),
        icon: const Icon(Icons.search),
      ),
    ),
  );
}
