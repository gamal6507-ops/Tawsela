import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/domain/repositories/rating_repository.dart';
import 'package:toktok/presentation/blocs/rating/rating_cubit.dart';
import 'package:toktok/presentation/blocs/rating/rating_state.dart';

class Ratings implements RatingRepository {
  bool fail = false;
  int writes = 0;
  String? savedTrip;
  @override
  Future<void> saveRating(
    String tripId,
    int stars,
    List<String> tags,
    String comment,
  ) async {
    if (fail) throw StateError('offline');
    writes++;
    savedTrip = tripId;
  }
}

void main() {
  test(
    'rating success requires a persisted write for the exact trip',
    () async {
      final repository = Ratings();
      final cubit = RatingCubit(repository);
      cubit.setStars(5);
      await cubit.submitRating(tripId: 'trip-a');
      expect(repository.writes, 1);
      expect(repository.savedTrip, 'trip-a');
      expect(cubit.state, isA<RatingSubmitted>());
      await cubit.close();
    },
  );
  test('failed rating retains input and remains retryable', () async {
    final repository = Ratings()..fail = true;
    final cubit = RatingCubit(repository);
    cubit.setStars(4);
    cubit.setComment('test');
    await cubit.submitRating(tripId: 'trip-a');
    expect(cubit.state, isA<RatingUpdated>());
    expect((cubit.state as RatingUpdated).stars, 4);
    repository.fail = false;
    await cubit.submitRating(tripId: 'trip-a');
    expect(repository.writes, 1);
    await cubit.close();
  });
}
