import '../models/trip.dart';

abstract class TripHistoryRepository {
  Future<List<Trip>> getTripHistory();
  Future<double> getTotalSpent();
}
