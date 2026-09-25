import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

/// All application writes live here; screens never mutate Firestore directly.
class TransitRepository {
  TransitRepository(this.db, this.uid);
  final FirebaseFirestore db;
  final String uid;
  CollectionReference<Map<String, dynamic>> get routes =>
      db.collection('routes');
  DocumentReference<Map<String, dynamic>> get user =>
      db.collection('users').doc(uid);
  Stream<List<TransitRoute>> watchRoutes() => routes.snapshots().map(
    (s) =>
        s.docs.map((d) => TransitRoute.fromFirestore(d.id, d.data())).toList(),
  );
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchJourney() =>
      db.collection('journeys').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSaved() =>
      user.collection('saved').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchReports(bool admin) =>
      (admin
              ? db.collection('reports')
              : db.collection('reports').where('userId', isEqualTo: uid))
          .snapshots();
  Future<void> saveFavorite(String id, bool saved) => saved
      ? user.collection('saved').doc(id).set({
          'createdAt': FieldValue.serverTimestamp(),
        })
      : user.collection('saved').doc(id).delete();
  Future<void> saveRoute(Map<String, dynamic> data, {String? id}) async {
    final ref = id == null ? routes.doc() : routes.doc(id);
    await db.runTransaction((tx) async {
      final current = await tx.get(ref);
      final count = (current.data()?['onboard'] as num?)?.toInt() ?? 0;
      if ((data['capacity'] as int) < count) {
        throw StateError('Capacity cannot be below the onboard count.');
      }
      tx.set(ref, {
        ...data,
        if (!current.exists) 'ownerId': uid,
        'onboard': count,
        'archived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> archiveRoute(String id) => db.runTransaction((tx) async {
    final ref = routes.doc(id);
    final snapshot = await tx.get(ref);
    if ((snapshot.data()?['onboard'] as num? ?? 0) > 0) {
      throw StateError('Passengers must leave before archiving.');
    }
    tx.update(ref, {
      'archived': true,
      'status': 'off',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
  Future<void> board(String id) => db.runTransaction((tx) async {
    final ref = routes.doc(id);
    final journey = db.collection('journeys').doc(uid);
    final routeDoc = await tx.get(ref);
    final journeyDoc = await tx.get(journey);
    if (journeyDoc.exists) {
      throw StateError('Leave your current service before boarding another.');
    }
    if (!routeDoc.exists) {
      throw StateError('This service is no longer available.');
    }
    final route = TransitRoute.fromFirestore(id, routeDoc.data()!);
    if (!route.canBoard) {
      throw StateError('This service has no available seats.');
    }
    tx.update(ref, {'onboard': route.onboard + 1});
    tx.set(journey, {
      'routeId': id,
      'routeName': route.name,
      'fare': route.fare,
      'boardedAt': FieldValue.serverTimestamp(),
    });
  });
  Future<void> leave() => db.runTransaction((tx) async {
    final journey = db.collection('journeys').doc(uid);
    final snapshot = await tx.get(journey);
    if (!snapshot.exists) return;
    final ref = routes.doc(snapshot.data()!['routeId'] as String);
    final route = await tx.get(ref);
    if (!route.exists) {
      throw StateError('Service missing. Please contact the administrator.');
    }
    final count = (route.data()?['onboard'] as num?)?.toInt() ?? 0;
    if (count < 1) {
      throw StateError('The passenger count needs administrator attention.');
    }
    tx.update(ref, {'onboard': count - 1});
    tx.delete(journey);
  });
  Future<void> report(TransitRoute route, String issue, String details) => db
      .collection('reports')
      .add({
        'routeId': route.id,
        'routeName': route.name,
        'userId': uid,
        'issue': issue,
        'details': details,
        'status': 'open',
        'timestamp': FieldValue.serverTimestamp(),
      })
      .then((_) {});
  Future<void> resolveReport(String id, bool resolved) =>
      db.collection('reports').doc(id).update({
        'status': resolved ? 'resolved' : 'open',
        'resolvedAt': resolved ? FieldValue.serverTimestamp() : null,
      });
}
