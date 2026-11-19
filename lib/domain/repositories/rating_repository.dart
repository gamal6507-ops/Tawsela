abstract class RatingRepository {
  Future<void> saveRating(
    String tripId,
    int stars,
    List<String> tags,
    String comment,
  );
}
