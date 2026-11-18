import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/repositories/trip_history_repository.dart';
import 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  final TripHistoryRepository _repository;

  TripHistoryCubit(this._repository) : super(TripHistoryInitial());

  Future<void> loadTrips() async {
    emit(TripHistoryLoading());
    try {
      final trips = await _repository.getTripHistory();
      final totalSpent = await _repository.getTotalSpent();
      if (trips.isEmpty) {
        emit(TripHistoryEmpty());
      } else {
        emit(TripHistoryLoaded(trips: trips, totalSpent: totalSpent));
      }
    } catch (e) {
      emit(TripHistoryError(e.toString()));
    }
  }
}
