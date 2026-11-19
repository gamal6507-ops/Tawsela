import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toktok/core/services/location_service.dart';
import 'package:toktok/data/repositories/firestore_driver_repository.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/presentation/widgets/tawsela_map_widget.dart';
import 'package:latlong2/latlong.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});
  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final _repository = FirestoreDriverRepository();
  late final _profile = _repository.watchProfile();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  final _form = GlobalKey<FormState>();
  RideType _type = RideType.car;
  bool _busy = false;
  String? _error;
  Timer? _locationTimer;
  String? _sharingRide;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _requests;
  String? _requestType;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _rideStream;
  String? _rideStreamId;
  @override
  void dispose() {
    _locationTimer?.cancel();
    _name.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await work();
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error =
                  'تعذر تنفيذ العملية. تأكد من اتصالك وحالة الطلب ثم حاول تاني',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(String id) async {
    final point = await LocationService().getCurrentLocation();
    await _repository.shareLocation(id, point);
  }

  void _toggleSharing(String id) {
    if (_sharingRide == id) {
      _locationTimer?.cancel();
      setState(() => _sharingRide = null);
      return;
    }
    _run(() => _share(id));
    setState(() => _sharingRide = id);
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_busy) _run(() => _share(id));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مساحة السائق')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profile,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _retry('تعذر تحميل حساب السائق', () => setState(() {}));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!.data();
            if (data == null) return _registration();
            if (data['approved'] != true) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'طلب الانضمام اتسجل. حسابك في انتظار مراجعة الإدارة واعتماد بياناتك ومستنداتك. لن تظهر طلبات ركاب قبل الاعتماد.',
                ),
              );
            }
            final activeId = data['activeRideId'] as String?;
            if (activeId == null && _sharingRide != null) {
              _locationTimer?.cancel();
              _sharingRide = null;
            }
            if (activeId != null) return _active(activeId);
            final type = data['vehicleType'] as String;
            if (_requestType != type) {
              _requestType = type;
              _requests = _repository.requests(type);
            }
            return Column(
              children: [
                SwitchListTile(
                  title: const Text('متاح لاستقبال رحلات'),
                  value: data['isAvailable'] == true,
                  onChanged:
                      _busy
                          ? null
                          : (value) =>
                              _run(() => _repository.setAvailable(value)),
                ),
                if (_error != null) Text(_error!),
                if (data['isAvailable'] != true)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('فعّل التوفر لعرض الطلبات المناسبة لمركبتك.'),
                  )
                else
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _requests,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _retry(
                            'تعذر تحميل الطلبات',
                            () => setState(() {
                              _requestType = null;
                            }),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs =
                            snapshot.data!.docs
                                .where(
                                  (doc) =>
                                      doc.data()['userId'] != _repository.uid,
                                )
                                .toList();
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('مفيش طلبات متاحة حالياً'),
                          );
                        }
                        return ListView(
                          children:
                              docs.map((doc) {
                                final r = doc.data();
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${r['from']} ← ${r['to']}'),
                                        Text(
                                          '${r['price']} ج كاش • ${r['distanceKm']} كم تقريبياً',
                                        ),
                                        const Text(
                                          'بقبولك توافق على الأجرة المعروضة. راجع مكان الانطلاق والوجهة.',
                                        ),
                                        const SizedBox(height: 8),
                                        TawselaMapWidget(
                                          height: 170,
                                          center: LatLng(
                                            (r['pickupLat'] as num).toDouble(),
                                            (r['pickupLng'] as num).toDouble(),
                                          ),
                                          pickupPoint: LatLng(
                                            (r['pickupLat'] as num).toDouble(),
                                            (r['pickupLng'] as num).toDouble(),
                                          ),
                                          dropoffPoint: LatLng(
                                            (r['dropoffLat'] as num).toDouble(),
                                            (r['dropoffLng'] as num).toDouble(),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              _busy
                                                  ? null
                                                  : () => _run(
                                                    () => _repository.accept(
                                                      doc.id,
                                                    ),
                                                  ),
                                          child: const Text('قبول الرحلة'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
  Widget _active(String id) {
    if (_rideStreamId != id) {
      _rideStreamId = id;
      _rideStream =
          _repository.db.collection('ride_requests').doc(id).snapshots();
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _rideStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('تعذر تحميل الرحلة. ارجع وافتح مساحة السائق تاني'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = snapshot.data!.data();
        if (r == null) return const Center(child: Text('الرحلة غير موجودة'));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${r['from']} ← ${r['to']}',
              style: const TextStyle(fontSize: 20),
            ),
            Text('الأجرة المتفق عليها: ${r['price']} ج • كاش'),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!),
            OutlinedButton(
              onPressed: () => context.push('/chat/$id'),
              child: const Text('محادثة الراكب'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _toggleSharing(id),
              child: Text(
                _sharingRide == id
                    ? 'إيقاف مشاركة الموقع'
                    : 'مشاركة موقعي أثناء فتح الشاشة',
              ),
            ),
            const Text('مشاركة الموقع اختيارية وتتوقف عند مغادرة الشاشة.'),
            if (r['status'] == 'accepted')
              ElevatedButton(
                onPressed:
                    _busy
                        ? null
                        : () =>
                            _run(() => _repository.advance(id, 'in_progress')),
                child: const Text('الراكب ركب • ابدأ الرحلة'),
              ),
            if (r['status'] == 'in_progress')
              ElevatedButton(
                onPressed:
                    _busy
                        ? null
                        : () => _run(() => _repository.advance(id, 'arrived')),
                child: const Text('وصلنا • إنهاء وحفظ الرحلة'),
              ),
          ],
        );
      },
    );
  }

  Widget _registration() => Form(
    key: _form,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('انضم كسائق', style: TextStyle(fontSize: 24)),
        const Text('الإدارة تراجع هويتك وترخيصك قبل تفعيل استقبال الرحلات.'),
        TextFormField(
          controller: _name,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'الاسم'),
          validator:
              (v) => v == null || v.trim().length < 2 ? 'اكتب اسمك' : null,
        ),
        TextFormField(
          controller: _phone,
          maxLength: 11,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'رقم الموبايل المصري'),
          validator:
              (v) =>
                  RegExp(r'^01[0125][0-9]{8}$').hasMatch(v ?? '')
                      ? null
                      : 'رقم غير صحيح',
        ),
        TextFormField(
          controller: _plate,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'رقم اللوحة'),
          validator:
              (v) =>
                  v == null || v.trim().length < 3 ? 'اكتب رقم اللوحة' : null,
        ),
        DropdownButtonFormField<RideType>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'نوع المركبة'),
          items:
              RideType.values
                  .map(
                    (t) =>
                        DropdownMenuItem(value: t, child: Text(t.displayName)),
                  )
                  .toList(),
          onChanged: (t) => setState(() => _type = t!),
        ),
        if (_error != null) Text(_error!),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              _busy
                  ? null
                  : () {
                    if (_form.currentState!.validate()) {
                      _run(
                        () => _repository.register(
                          name: _name.text,
                          phone: _phone.text,
                          plate: _plate.text,
                          type: _type.name,
                        ),
                      );
                    }
                  },
          child: const Text('إرسال طلب الانضمام'),
        ),
      ],
    ),
  );
  Widget _retry(String message, VoidCallback retry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        TextButton(onPressed: retry, child: const Text('حاول تاني')),
      ],
    ),
  );
}
