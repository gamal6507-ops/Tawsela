import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toktok/domain/repositories/rating_repository.dart';

class FirestoreRatingRepository implements RatingRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  FirestoreRatingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : db = firestore ?? FirebaseFirestore.instance,
       auth = firebaseAuth ?? FirebaseAuth.instance;
  @override
  Future<void> saveRating(
    String tripId,
    int stars,
    List<String> tags,
    String comment,
  ) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || stars < 1 || stars > 5 || comment.length > 1000) {
      throw ArgumentError('بيانات التقييم غير صالحة');
    }
    await db.collection('ratings').doc(tripId).set({
      'userId': uid,
      'tripId': tripId,
      'stars': stars,
      'tags': tags,
      'comment': comment.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
