// Platform interfaces are mocked only to control the account-switch race.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toktok/data/repositories/firestore_notifications_repository.dart';

class Db extends Mock implements FirebaseFirestore {}

class Auth extends Mock implements FirebaseAuth {}

class Account extends Mock implements User {}

class Col extends Mock implements CollectionReference<Map<String, dynamic>> {}

class Ref extends Mock implements DocumentReference<Map<String, dynamic>> {}

class Q extends Mock implements Query<Map<String, dynamic>> {}

class Snap extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class Row extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class Batch extends Mock implements WriteBatch {}

void main() {
  test(
    'clearing notifications aborts if the authenticated account changes while loading',
    () async {
      final db = Db();
      final auth = Auth();
      final a = Account();
      final b = Account();
      final rides = Col();
      final users = Col();
      final userA = Ref();
      final userB = Ref();
      final markersA = Col();
      final markersB = Col();
      final marker = Ref();
      final q = Q();
      final snapshot = Snap();
      final empty = Snap();
      final row = Row();
      final batch = Batch();
      final pending = Completer<QuerySnapshot<Map<String, dynamic>>>();
      when(() => a.uid).thenReturn('a');
      when(() => b.uid).thenReturn('b');
      when(() => auth.currentUser).thenReturn(a);
      when(() => db.collection('ride_requests')).thenReturn(rides);
      when(() => rides.where('userId', isEqualTo: 'a')).thenReturn(q);
      when(() => q.orderBy('createdAt', descending: true)).thenReturn(q);
      when(() => q.limit(30)).thenReturn(q);
      when(() => q.get()).thenAnswer((_) => pending.future);
      when(() => db.collection('users')).thenReturn(users);
      when(() => users.doc('a')).thenReturn(userA);
      when(() => users.doc('b')).thenReturn(userB);
      when(() => userA.collection('notification_states')).thenReturn(markersA);
      when(() => userB.collection('notification_states')).thenReturn(markersB);
      when(() => markersA.get()).thenAnswer((_) async => empty);
      when(() => markersB.get()).thenAnswer((_) async => empty);
      when(() => empty.docs).thenReturn([]);
      when(() => snapshot.docs).thenReturn([row]);
      when(() => row.id).thenReturn('ride-a');
      when(() => row.data()).thenReturn({
        'status': 'completed',
        'from': 'A',
        'to': 'B',
        'createdAt': Timestamp.now(),
      });
      when(() => db.batch()).thenReturn(batch);
      when(() => markersB.doc('ride-a_completed')).thenReturn(marker);
      when(
        () => batch.set(marker, {'isRead': true, 'hidden': true}),
    ).thenAnswer((_) {});
      when(() => batch.commit()).thenAnswer((_) async {});
      final repository = FirestoreNotificationsRepository(
        firestore: db,
        firebaseAuth: auth,
      );
      final operation = repository.clearAll();
      when(() => auth.currentUser).thenReturn(b);
      pending.complete(snapshot);
      await expectLater(operation, throwsStateError);
      verifyNever(() => batch.commit());
      verifyNever(() => users.doc('b'));
    },
  );
}
