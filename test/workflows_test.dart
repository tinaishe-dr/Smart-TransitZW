import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:smarttransitzw/main.dart';
import 'package:smarttransitzw/features/account_screen.dart';
import 'package:smarttransitzw/features/reports_view.dart';
import 'package:smarttransitzw/features/service_forms.dart';
import 'package:smarttransitzw/features/transit_dashboard.dart';
import 'package:smarttransitzw/models/route_model.dart';
import 'package:smarttransitzw/data/transit_repository.dart';
import 'transit_repository_test.dart' show service;

void main() {
  for (final size in [
    const Size(360, 740),
    const Size(1024, 600),
    const Size(1440, 1000),
  ]) {
    testWidgets('account layout adapts to $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp(home: AccountScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('passenger submits a report and admin resolves it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = FakeFirebaseFirestore();
    final repo = TransitRepository(db, 'rider');
    final route = TransitRoute.fromFirestore('a', service());
    await tester.pumpWidget(
      MyApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ReportEditor(repository: repo, route: route),
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Driver was racing for passengers.',
    );
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(
      (await repo.watchReports(false).first).docs.single.data()['details'],
      'Driver was racing for passengers.',
    );
    await tester.pumpWidget(
      MyApp(
        home: Scaffold(
          body: ReportsView(
            repository: TransitRepository(db, 'admin'),
            admin: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark resolved'));
    await tester.pumpAndSettle();
    expect(
      (await repo.watchReports(false).first).docs.single.data()['status'],
      'resolved',
    );
    expect(find.text('Reopen report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('administrator sees computed coverage with no seeded metrics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = FakeFirebaseFirestore();
    await db.collection('routes').doc('a').set(service());
    await tester.pumpWidget(
      MyApp(
        home: TransitDashboard(
          repository: TransitRepository(db, 'admin'),
          role: 'admin',
          company: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Network availability'), findsOneWidget);
    expect(
      find.text('1 services have no operator update in the last 15 minutes.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
