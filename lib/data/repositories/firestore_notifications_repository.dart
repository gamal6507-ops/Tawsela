import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toktok/domain/models/app_notification.dart';
import 'package:toktok/domain/repositories/notifications_repository.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  FirestoreNotificationsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : db = firestore ?? FirebaseFirestore.instance,
       auth = firebaseAuth ?? FirebaseAuth.instance;
  String get uid =>
      auth.currentUser?.uid ?? (throw StateError('سجل الدخول أولاً'));
  CollectionReference<Map<String, dynamic>> _markers(String accountId) =>
      db.collection('users').doc(accountId).collection('notification_states');
  void _requireAccount(String accountId) {
    if (auth.currentUser?.uid != accountId) {
      throw StateError('تغير الحساب أثناء العملية');
    }
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    final accountId = uid;
    final markersRef = _markers(accountId);
    final rides =
        await db
            .collection('ride_requests')
            .where('userId', isEqualTo: accountId)
            .orderBy('createdAt', descending: true)
            .limit(30)
            .get();
    _requireAccount(accountId);
    final markers = await markersRef.get();
    _requireAccount(accountId);
    final states = {for (final doc in markers.docs) doc.id: doc.data()};
    const labels = {
      'searching': 'جاري البحث عن سائق',
      'accepted': 'تم قبول الرحلة',
      'in_progress': 'بدأت الرحلة',
      'arrived': 'وصلت الرحلة',
      'completed': 'اكتملت الرحلة',
      'cancelled': 'تم إلغاء الرحلة',
    };
    return rides.docs
        .where(
          (doc) =>
              states['${doc.id}_${doc.data()['status']}']?['hidden'] != true,
        )
        .map((doc) {
          final data = doc.data();
          final id = '${doc.id}_${data['status']}';
          return AppNotification(
            id: id,
            title: labels[data['status']] ?? 'تحديث رحلة',
            body: '${data['from']} ← ${data['to']}',
            type: NotificationType.ride,
            date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isRead: states[id]?['isRead'] == true,
          );
        })
        .toList();
  }

  @override
  Future<void> markAsRead(String id) =>
      _markers(uid).doc(id).set({'isRead': true, 'hidden': false});
  @override
  Future<void> clearAll() async {
    final accountId = uid;
    final markersRef = _markers(accountId);
    final notifications = await getNotifications();
    _requireAccount(accountId);
    final batch = db.batch();
    for (final n in notifications) {
      batch.set(markersRef.doc(n.id), {'isRead': true, 'hidden': true});
    }
    await batch.commit();
  }
}
