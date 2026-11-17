import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:toktok/core/services/location_service.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/presentation/blocs/auth/auth_cubit.dart';
import 'package:toktok/presentation/blocs/auth/auth_state.dart';
import 'package:toktok/presentation/blocs/notifications/notifications_cubit.dart';
import 'package:toktok/presentation/blocs/promo_codes/promo_codes_cubit.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_bloc.dart';
import 'package:toktok/presentation/blocs/ride_booking/ride_booking_event.dart';
import 'package:toktok/presentation/widgets/quick_destination_button.dart';
import 'package:toktok/presentation/widgets/primary_button.dart';
import 'package:toktok/presentation/widgets/tawsela_map_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _locationService = LocationService();
  final _mapController = MapController();
  LatLng _pickupPoint = LocationService.defaultCairoLocation;
  LatLng? _dropoffPoint;
  bool _pickingPickup = false;
  final _quickDestinations = [
    {'icon': '🛍️', 'label': 'المول', 'value': 'مدينتي مول'},
    {'icon': '💼', 'label': 'الشغل', 'value': 'مكتب العمل'},
    {'icon': '🏠', 'label': 'البيت', 'value': 'المنزل'},
    {'icon': '🏥', 'label': 'المستشفى', 'value': 'مستشفى النيل'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().loadNotifications();
    context.read<PromoCodesCubit>().loadPromoCodes();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    final current = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _pickupPoint = current;
    });
    _mapController.move(current, 14.5);
    if (_fromController.text.isEmpty) {
      final address = await _locationService.getAddressFromLatLng(current);
      if (mounted && _fromController.text.isEmpty) {
        setState(() => _fromController.text = address);
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _onMapTap(LatLng point) async {
    if (!_locationService.isInsideEgypt(point)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الخدمة متاحة داخل مصر فقط',
            style: GoogleFonts.cairo(color: AppColors.textPrimary),
          ),
        ),
      );
      return;
    }
    final isPickup = _pickingPickup || _fromController.text.isEmpty;
    setState(() {
      if (isPickup) {
        _pickupPoint = point;
        _pickingPickup = false;
      } else {
        _dropoffPoint = point;
      }
    });
    final address = await _locationService.getAddressFromLatLng(point);
    if (!mounted) return;
    setState(() {
      if (isPickup) {
        _fromController.text = address;
      } else {
        _toController.text = address;
      }
    });
  }

  Future<void> _centerOnPickup() async {
    final current = await _locationService.getCurrentLocation();
    final address = await _locationService.getAddressFromLatLng(current);
    if (!mounted) return;
    setState(() {
      _pickupPoint = current;
      _fromController.text = address;
    });
    _mapController.move(current, 15.0);
  }

  void _onQuickDestination(String value, bool isFrom) {
    setState(() {
      if (isFrom) {
        _fromController.text = value;
      } else {
        _toController.text = value;
      }
    });
  }

  void _onSearch() {
    if (_fromController.text.isNotEmpty && _toController.text.isNotEmpty) {
      final dropoff = _dropoffPoint ??
          LatLng(_pickupPoint.latitude + 0.02, _pickupPoint.longitude + 0.015);
      final distanceKm = _locationService.calculateDistanceKm(
        _pickupPoint,
        dropoff,
      );
      context.read<RideBookingBloc>().add(
            RideBookingStarted(
              from: _fromController.text.trim(),
              to: _toController.text.trim(),
              pickupLatLng: _pickupPoint,
              dropoffLatLng: dropoff,
              distanceKm: distanceKm,
            ),
          );
      context.push('/choose-ride');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اختار نقطة الانطلاق والوجهة الأول',
            style: GoogleFonts.cairo(color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildLocationButton(),
                  const SizedBox(height: 20),
                  Text(
                    'عايز تروح فين؟',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLocationField(
                    controller: _fromController,
                    icon: Icons.circle,
                    iconColor: AppColors.accent,
                    hint: 'منين',
                  ),
                  const SizedBox(height: 12),
                  _buildLocationField(
                    controller: _toController,
                    icon: Icons.search,
                    iconColor: AppColors.textSecondary,
                    hint: 'رواح فين',
                  ),
                  const SizedBox(height: 24),
                  _buildQuickDestinations(),
                  const SizedBox(height: 24),
                  _buildPromoBanner(),
                  const SizedBox(height: 20),
                  PrimaryButton(text: 'ابحث عن رحلة', onPressed: _onSearch),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final userName = state is Authenticated ? (state.user.displayName ?? 'صديقي') : 'صديقي';
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهلاً بيك، $userName 👋',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ودّك تروح فين النهارده؟',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationButton() {
    return Stack(
      children: [
        TawselaMapWidget(
          mapController: _mapController,
          center: _pickupPoint,
          height: 220,
          pickupPoint: _pickupPoint,
          dropoffPoint: _dropoffPoint,
          onTap: _onMapTap,
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: InkWell(
              onTap: () => setState(() => _pickingPickup = !_pickingPickup),
              child: Text(
                _pickingPickup
                    ? 'اضغط على الخريطة لتحديد: منين'
                    : 'اضغط على الخريطة لتحديد: رايح فين',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: FloatingActionButton.small(
            heroTag: 'home_my_location',
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            onPressed: _centerOnPickup,
            child: const Icon(Icons.my_location, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintStyle: GoogleFonts.cairo(color: AppColors.textTertiary),
              ),
              style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وجهات سريعة',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _quickDestinations.map((d) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: QuickDestinationButton(
                  icon: d['icon']!,
                  label: d['label']!,
                  onTap: () => _onQuickDestination(d['value']!, false),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return GestureDetector(
      onTap: () => context.push('/promo-codes'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, Color(0xFFF5A623)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عندك كود خصم؟',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'طبّق الكود ووفّر على رحلتك',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.local_offer_outlined, color: Colors.black, size: 32),
          ],
        ),
      ),
    );
  }
}
