import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:smarttransitzw/main.dart';
import 'package:smarttransitzw/features/account_screen.dart';
import 'package:smarttransitzw/features/transit_dashboard.dart';
import 'package:smarttransitzw/data/transit_repository.dart';
import 'transit_repository_test.dart' show service;

void main() {
  testWidgets('login validates inputs and switches to operator registration', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(home: AccountScreen()));
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
    await tester.ensureVisible(find.text('New here? Create an account'));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Operator'));
    await tester.tap(find.text('Operator'));
    await tester.pumpAndSettle();
    expect(find.text('Operator / company name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets(
      'commuter workspace search, saving and navigation at $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = FakeFirebaseFirestore();
        await db.collection('routes').doc('a').set(service());
        await tester.pumpWidget(
          MyApp(
            home: TransitDashboard(
              repository: TransitRepository(db, 'rider'),
              role: 'commuter',
              company: '',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Where are you headed?'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byTooltip('Save route'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byTooltip('Save route'));
        await tester.pumpAndSettle();
        expect(
          (await db.collection('users').doc('rider').collection('saved').get())
              .docs
              .length,
          1,
        );
        await tester.enterText(
          find.byType(TextField),
          'No matching destination',
        );
        await tester.pumpAndSettle();
        expect(find.text('No matching services'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('operator publishes a service from the editor', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(
      MyApp(
        home: TransitDashboard(
          repository: TransitRepository(db, 'operator'),
          role: 'operator',
          company: 'Test operator',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add service'));
    await tester.pumpAndSettle();
    for (final entry in {
      'Service name': 'CBD to Mbare',
      'From / boarding point': 'Market Square',
      'To / destination': 'Mbare',
      'Vehicle registration': 'ABC1234',
      'Fare (USD)': '1.50',
      'Seats': '18',
    }.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, entry.key),
        entry.value,
      );
    }
    await tester.tap(find.text('Publish service'));
    await tester.pumpAndSettle();
    expect(
      (await db.collection('routes').get()).docs.single.data()['fare'],
      1.5,
    );
    expect(find.text('CBD to Mbare'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
