import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:smarttransitzw/data/transit_repository.dart';
import 'package:smarttransitzw/models/route_model.dart';

Map<String, dynamic> service({int capacity = 2}) => {
  'name': 'CBD to Mbare',
  'origin': 'Market Square',
  'destination': 'Mbare',
  'fare': 1.0,
  'capacity': capacity,
  'onboard': 0,
  'status': 'active',
  'ownerId': 'operator',
  'company': 'Test operator',
  'vehicle': 'ABC1234',
  'notice': '',
  'archived': false,
  'departureAt': null,
};
void main() {
  late FakeFirebaseFirestore db;
  late TransitRepository rider;
  setUp(() async {
    db = FakeFirebaseFirestore();
    rider = TransitRepository(db, 'rider');
    await db.collection('routes').doc('a').set(service());
  });
  test(
    'boarding and leaving update both seat count and the private journey',
    () async {
      await rider.board('a');
      expect(
        (await db.collection('routes').doc('a').get()).data()!['onboard'],
        1,
      );
      expect(
        (await db.collection('journeys').doc('rider').get()).data()!['routeId'],
        'a',
      );
      await rider.leave();
      expect(
        (await db.collection('routes').doc('a').get()).data()!['onboard'],
        0,
      );
      expect(
        (await db.collection('journeys').doc('rider').get()).exists,
        false,
      );
    },
  );
  test(
    'cannot board twice or board another service during a journey',
    () async {
      await db.collection('routes').doc('b').set(service());
      await rider.board('a');
      await expectLater(rider.board('a'), throwsStateError);
      await expectLater(rider.board('b'), throwsStateError);
      expect(
        (await db.collection('routes').doc('b').get()).data()!['onboard'],
        0,
      );
    },
  );
  test('full, off duty and archived services reject boarding', () async {
    for (final change in [
      {'onboard': 2},
      {'onboard': 0, 'status': 'off'},
      {'status': 'active', 'archived': true},
    ]) {
      await db.collection('routes').doc('a').update(change);
      await expectLater(rider.board('a'), throwsStateError);
    }
  });
  test(
    'capacity cannot shrink beneath occupancy and occupied service cannot archive',
    () async {
      await rider.board('a');
      final operator = TransitRepository(db, 'operator');
      await expectLater(
        operator.saveRoute(service(capacity: 0), id: 'a'),
        throwsStateError,
      );
      await expectLater(operator.archiveRoute('a'), throwsStateError);
      await rider.leave();
      await operator.archiveRoute('a');
      expect(
        (await db.collection('routes').doc('a').get()).data()!['archived'],
        true,
      );
    },
  );
  test(
    'saved routes persist and reports are scoped to their submitter',
    () async {
      await rider.saveFavorite('a', true);
      expect((await rider.watchSaved().first).docs.single.id, 'a');
      await rider.saveFavorite('a', false);
      expect((await rider.watchSaved().first).docs, isEmpty);
      final route = TransitRoute.fromFirestore('a', service());
      await rider.report(route, 'Overcharging', 'Requested a different fare');
      await TransitRepository(db, 'other').report(route, 'No-show', '');
      final reports = (await rider.watchReports(false).first).docs;
      expect(reports.length, 1);
      expect(reports.single.data()['issue'], 'Overcharging');
      await rider.resolveReport(reports.single.id, true);
      expect(
        (await rider.watchReports(false).first).docs.single.data()['status'],
        'resolved',
      );
    },
  );
  test(
    'search combines words, availability, saved routes and fare ordering',
    () {
      final routes = [
        TransitRoute.fromFirestore('a', service()),
        TransitRoute.fromFirestore('b', {...service(), 'fare': 0.5}),
        TransitRoute.fromFirestore('c', {...service(), 'status': 'off'}),
      ];
      expect(
        filterRoutes(
          routes,
          query: 'mbare CBD',
          cheapestFirst: true,
          availableOnly: true,
        ).map((r) => r.id),
        ['b', 'a'],
      );
      expect(filterRoutes(routes, savedIds: {'a'}).single.id, 'a');
      expect(filterRoutes(routes, query: 'Bulawayo'), isEmpty);
    },
  );
  test(
    'legacy records tolerate absent optional fields and unknown status fails closed',
    () {
      final route = TransitRoute.fromFirestore('legacy', {
        'name': 'Legacy',
        'fare': 1,
        'status': 'invalid',
      });
      expect(route.status, RouteStatus.off);
      expect(route.canBoard, false);
      expect(route.isFresh(DateTime.now()), false);
    },
  );
}
