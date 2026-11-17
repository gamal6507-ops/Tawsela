import 'package:equatable/equatable.dart';
import 'package:toktok/domain/models/trip.dart';

abstract class TripHistoryState extends Equatable {
  const TripHistoryState();
  @override
  List<Object?> get props => [];
}

class TripHistoryInitial extends TripHistoryState {}
class TripHistoryLoading extends TripHistoryState {}
class TripHistoryLoaded extends TripHistoryState {
  final List<Trip> trips;
  final double totalSpent;
  const TripHistoryLoaded({required this.trips, required this.totalSpent});
  @override
  List<Object?> get props => [trips, totalSpent];
}
class TripHistoryEmpty extends TripHistoryState {}
class TripHistoryError extends TripHistoryState {
  final String message;
  const TripHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
