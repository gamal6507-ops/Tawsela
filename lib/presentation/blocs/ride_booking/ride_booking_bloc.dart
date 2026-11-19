import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/models/ride_request.dart';
import 'package:toktok/domain/repositories/ride_repository.dart';
import 'ride_booking_event.dart';
import 'ride_booking_state.dart';

class RideBookingBloc extends Bloc<RideBookingEvent, RideBookingState> {
  final RideRepository _rideRepository;
  StreamSubscription<RideRequest?>? _updates;
  int _generation = 0;
  String? _requestId;
  bool _restoring = false;
  bool _completing = false;

  RideBookingBloc(this._rideRepository) : super(RideBookingInitial()) {
    on<RideBookingStarted>((event, emit) async {
      if (_requestId != null ||
          state is SearchingDriver ||
          state is DriverFoundState ||
          state is RideInProgress ||
          state is RideArrivedState) {
        return;
      }
      final generation = ++_generation;
      try {
        final options = await _rideRepository.getRideTypes(
          distanceKm: event.distanceKm,
        );
        if (generation != _generation || emit.isDone) return;
        if (options.isEmpty) throw StateError('لا توجد مركبات متاحة');
        emit(
          SelectingRide(
            from: event.from,
            to: event.to,
            rideOptions: options,
            selectedType: options.first.type,
            selectedPrice: options.first.price,
            pickupLatLng: event.pickupLatLng,
            dropoffLatLng: event.dropoffLatLng,
            distanceKm: event.distanceKm,
          ),
        );
      } catch (_) {
        if (!emit.isDone) {
          emit(const RideBookingError('تعذر تحميل الأسعار. حاول تاني'));
        }
      }
    });
    on<RideTypeSelected>((event, emit) {
      final current = state;
      if (current is SelectingRide && !current.isSubmitting) {
        final option = current.rideOptions.firstWhere(
          (o) => o.type == event.rideType,
        );
        emit(
          current.copyWith(
            selectedType: option.type,
            selectedPrice: option.price,
          ),
        );
      }
    });
    on<PaymentMethodSelected>((event, emit) {
      final current = state;
      if (current is SelectingRide && !current.isSubmitting) {
        emit(current.copyWith(selectedPayment: event.method));
      }
    });
    on<BookingConfirmed>(_confirm);
    on<DriverSearchStarted>(_search);
    // Only persisted driver updates advance a production ride.
    on<DriverFound>((event, emit) {});
    on<RideStarted>((event, emit) {});
    on<RemoteRideChanged>(_remote);
    on<RideArrived>((event, emit) {});
    on<RideCompleted>(_complete);
    on<BookingCancelled>(_cancel);
    on<RestoreBooking>(_restore);
    on<BookingFailure>((event, emit) => emit(RideBookingError(event.message)));
  }

  Future<void> _confirm(
    BookingConfirmed event,
    Emitter<RideBookingState> emit,
  ) async {
    final current = state;
    if (current is! SelectingRide || current.isSubmitting) return;
    final generation = _generation;
    emit(current.copyWith(isSubmitting: true));
    try {
      final id = await _rideRepository.createRideRequest(
        from: current.from,
        to: current.to,
        rideType: current.selectedType,
        price: current.selectedPrice,
        paymentMethod: current.selectedPayment,
        pickupLatLng: current.pickupLatLng,
        dropoffLatLng: current.dropoffLatLng,
        distanceKm: current.distanceKm,
      );
      if (id == null) throw StateError('لم يتم إنشاء الطلب');
      if (generation != _generation || emit.isDone) {
        await _rideRepository.cancelSearch(requestId: id);
        return;
      }
      _requestId = id;
      emit(
        SearchingDriver(
          from: current.from,
          to: current.to,
          rideType: current.selectedType,
          price: current.selectedPrice,
          paymentMethod: current.selectedPayment,
          requestId: id,
          pickupLatLng: current.pickupLatLng,
          dropoffLatLng: current.dropoffLatLng,
          distanceKm: current.distanceKm,
        ),
      );
      _watch(id);
      add(const DriverSearchStarted());
    } catch (_) {
      if (generation == _generation && !emit.isDone) {
        emit(
          current.copyWith(
            isSubmitting: false,
            error: 'تعذر إرسال الطلب. تحقق من الإنترنت وحاول تاني',
          ),
        );
      }
    }
  }

  void _watch(String id) {
    _updates?.cancel();
    _updates = _rideRepository
        .watchRide(id)
        .listen(
          (request) {
            if (!isClosed && _requestId == id && request != null) {
              add(RemoteRideChanged(request));
            }
          },
          onError: (_) {
            if (!isClosed && _requestId == id) {
              add(
                const BookingFailure('تعذر متابعة الرحلة. اضغط استعادة الرحلة'),
              );
            }
          },
        );
  }

  Future<void> _search(
    DriverSearchStarted event,
    Emitter<RideBookingState> emit,
  ) async {
    final current = state;
    final generation = _generation;
    if (current is! SearchingDriver) return;
    try {
      final driver = await _rideRepository.searchForDriver(
        current.rideType,
        requestId: current.requestId,
      );
      if (emit.isDone ||
          generation != _generation ||
          state is! SearchingDriver) {
        return;
      }
      emit(
        DriverFoundState(
          from: current.from,
          to: current.to,
          driver: driver,
          rideType: current.rideType,
          price: current.price,
          paymentMethod: current.paymentMethod,
          requestId: current.requestId,
          pickupLatLng: current.pickupLatLng,
          dropoffLatLng: current.dropoffLatLng,
          distanceKm: current.distanceKm,
        ),
      );
    } catch (_) {
      if (!emit.isDone &&
          generation == _generation &&
          state is SearchingDriver) {
        emit(
          const RideBookingError(
            'لم يقبل سائق الطلب بعد أو انقطع الاتصال. يمكنك استعادة الطلب أو إلغاؤه',
          ),
        );
      }
    }
  }

  void _remote(RemoteRideChanged event, Emitter<RideBookingState> emit) {
    final r = event.request;
    if (r.id != _requestId) return;
    if (r.status == 'cancelled') {
      _requestId = null;
      _updates?.cancel();
      emit(RideBookingInitial());
      return;
    }
    if (r.status == 'searching') {
      emit(
        SearchingDriver(
          from: r.from,
          to: r.to,
          rideType: r.type,
          price: r.price,
          paymentMethod: r.payment,
          requestId: r.id,
          pickupLatLng: r.pickup,
          dropoffLatLng: r.dropoff,
          distanceKm: r.distanceKm,
        ),
      );
      return;
    }
    final driver = r.driver;
    if (driver == null) return;
    if (r.status == 'accepted') {
      emit(
        DriverFoundState(
          from: r.from,
          to: r.to,
          driver: driver,
          rideType: r.type,
          price: r.price,
          paymentMethod: r.payment,
          requestId: r.id,
          pickupLatLng: r.pickup,
          dropoffLatLng: r.dropoff,
          distanceKm: r.distanceKm,
        ),
      );
    } else if (r.status == 'in_progress') {
      emit(
        RideInProgress(
          from: r.from,
          to: r.to,
          driver: driver,
          rideType: r.type,
          price: r.price,
          paymentMethod: r.payment,
          requestId: r.id,
          pickupLatLng: r.pickup,
          dropoffLatLng: r.dropoff,
          distanceKm: r.distanceKm,
        ),
      );
    } else if (r.status == 'arrived' || r.status == 'completed') {
      emit(
        RideArrivedState(
          from: r.from,
          to: r.to,
          driver: driver,
          rideType: r.type,
          price: r.price,
          paymentMethod: r.payment,
          requestId: r.id,
          pickupLatLng: r.pickup,
          dropoffLatLng: r.dropoff,
          distanceKm: r.distanceKm,
          durationMinutes: (r.data['durationMinutes'] as num?)?.toInt() ?? 0,
        ),
      );
    }
  }

  Future<void> _complete(
    RideCompleted event,
    Emitter<RideBookingState> emit,
  ) async {
    final current = state;
    if (current is! RideArrivedState || _completing) return;
    _completing = true;
    try {
      await _rideRepository.completeRideAndSaveTrip(
        requestId: current.requestId,
        from: current.from,
        to: current.to,
        rideType: current.rideType,
        price: current.price,
        driver: current.driver,
        paymentMethod: current.paymentMethod,
        distanceKm: current.distanceKm,
      );
      if (!emit.isDone) {
        _requestId = null;
        _updates?.cancel();
        emit(RideBookingInitial());
      }
    } catch (_) {
      if (!emit.isDone) {
        emit(
          const RideBookingError(
            'تعذر تأكيد الرحلة. بياناتها محفوظة، استعدها وحاول تاني',
          ),
        );
      }
    } finally {
      _completing = false;
    }
  }

  Future<void> _cancel(
    BookingCancelled event,
    Emitter<RideBookingState> emit,
  ) async {
    if (state is RideInProgress || state is RideArrivedState) return;
    ++_generation;
    try {
      if (_requestId != null) {
        await _rideRepository.cancelSearch(requestId: _requestId);
      }
      _requestId = null;
      await _updates?.cancel();
      if (!emit.isDone) emit(RideBookingInitial());
    } catch (_) {
      if (!emit.isDone) {
        emit(
          const RideBookingError(
            'تعذر إلغاء الطلب. استعد الرحلة لمعرفة حالتها الحالية',
          ),
        );
      }
    }
  }

  Future<void> _restore(
    RestoreBooking event,
    Emitter<RideBookingState> emit,
  ) async {
    if (_restoring) return;
    _restoring = true;
    final generation = _generation;
    try {
      final request = await _rideRepository.getActiveRide();
      if (emit.isDone || generation != _generation) return;
      if (request == null) {
        _requestId = null;
        emit(RideBookingInitial());
      } else {
        _requestId = request.id;
        _watch(request.id);
        _remote(RemoteRideChanged(request), emit);
      }
    } catch (_) {
      if (!emit.isDone) {
        emit(
          const RideBookingError(
            'تعذر تحميل الرحلة الحالية. تحقق من الإنترنت وحاول تاني',
          ),
        );
      }
    } finally {
      _restoring = false;
    }
  }

  @override
  Future<void> close() async {
    ++_generation;
    await _updates?.cancel();
    return super.close();
  }
}
