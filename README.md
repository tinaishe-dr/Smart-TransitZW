# SmartTransitZW

A Flutter/Firebase platform connecting Zimbabwean commuters, transport operators and administrations.

## What works

- **Commuters:** email registration, sign-in and password reset; route/operator/destination search; available-seat and fare filters; persistent saved routes; boarding and leaving; private issue reports and resolution tracking.
- **Operators:** register an operator account; publish one vehicle service per route assignment; edit origin, destination, registration, fare in USD, capacity, availability, planned departure and passenger notices; archive unoccupied services; view network services.
- **Administrations:** aggregate service availability, reported seats and stale updates; review passenger reports; resolve or reopen reports. Administrator accounts are provisioned by a trusted Firebase administrator, never by public registration.
- Responsive desktop sidebar and mobile navigation, validation, pending-action protection, loading/error/empty states, startup retry and account-profile recovery.

Availability is streamed from Firestore. Departures are **operator-entered plans**, not GPS ETAs. Seat counts represent **app check-ins**, not all passengers. Boarding does not reserve a seat or process a payment. No fabricated vehicles, arrival times, ridership metrics or production demo records are included.

## Run

Use Flutter 3.44 or later with Dart 3.11.5 or later (verified with Flutter 3.44.4 / Dart 3.12.2).

```sh
flutter pub get
flutter run -d chrome
```

Firebase configuration already exists in `lib/firebase_options.dart`. For a different project, use FlutterFire configuration and enable Email/Password authentication and Cloud Firestore. Add your web deployment hostname to Firebase Authentication's authorized domains. Linux does not currently have Firebase configuration.

The UI never grants database permissions: **deploy the supplied rules before allowing users to use this release**. Deployment is deliberately not performed against the live project by development/test commands.

```sh
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
```

Create a normal account, then set its `users/{uid}.role` to `admin` through trusted Firebase administration tooling. Public clients cannot create an admin profile, edit their role, or read other user profiles. Operator self-registration does not imply regulatory verification.

## Structure

- `lib/features/` — account, role-aware workspace, service forms and reports.
- `lib/data/transit_repository.dart` — stable streams and transactional domain operations.
- `lib/models/` — route parsing, status and pure filtering.
- `lib/widgets/` — reusable service cards, navigation, panels, status and empty states.
- `lib/theme/` — shared visual tokens and Material 3 theme.
- `lib/screens/auth_gate.dart`, `home_screen.dart` — session and profile routing. Other original screen paths remain as deprecated compatibility entry points; new navigation uses features.
- `firestore.rules` — authorization, schema validation and atomic boarding invariants.
- `test/` — repository and responsive widget workflows.
- `tests/security/` — real Firestore emulator authorization and concurrency tests.

Three workspace subscriptions replace the previous per-service passenger listeners: services, the current user's saved routes, and the current user's private journey. Lists build visible rows lazily. Controllers, timers and subscriptions are disposed. Report subscriptions exist only while the reports screen is visible. This remains a small-network implementation: large deployments should introduce geographic query bounds and server-maintained aggregate counters rather than streaming the entire service collection.

## Data and privacy

`routes/{id}` represents one vehicle service and contains its public route, registration, fare, capacity, operator-reported status, notice and planned departure. `onboard` is changed only in a transaction paired with creation/deletion of `journeys/{uid}`. A commuter can have at most one current journey. Competing transactions cannot overbook the final seat. Operators cannot change the passenger counter or shrink capacity below occupancy.

`users/{uid}/saved/{routeId}` and `journeys/{uid}` are private. `reports/{id}` contains the submitter ID for ownership enforcement; only its submitter and authorized administrators can read it. Individual reports are **not anonymous to administrators**. Network statistics contain no passenger identities; administrators do not receive user-profile or journey read permission. Reports are not an emergency response channel.

## Existing-data migration

Back up Firestore and schedule a cutover; older clients write incompatible passenger records and will be rejected by the new rules.

1. Stop old boarding writes and reconcile any `routes/{id}/passengers` records with actual journeys. Do not silently convert these to new seat counts: the old schema permits multiple routes per user and has no trustworthy aggregate.
2. At a verified empty-service boundary, set `onboard: 0`. Preserve any occupied service until a trusted migration reconciles its unique passenger journeys and count atomically.
3. Populate `origin`, `destination`, `vehicle`, `notice`, `departureAt`, `archived` and `updatedAt`; retain `ownerId`, `company`, `name`, `fare`, `capacity`, `status`. Operators can fill missing service information through Manage service. Unknown statuses display as off duty.
4. Old reports without `userId` stay visible only to administrators. Do not guess submitter identities; preserve reports for authorized review. Keep historical passenger records under an explicit retention policy; new clients cannot read them.
5. Test a commuter and operator on the emulator/staging project, deploy rules and release updated clients together.

## Verification

```sh
flutter analyze
flutter test
flutter build web --release
```

Security tests require Node 22.13+ and Java 21+ on PATH:

```sh
cd tests/security
npm install
npm test
```

Alternatively use the checked-in pnpm lockfile with `pnpm install --frozen-lockfile` and `pnpm test`. The tests use `demo-smarttransitzw` only and never connect to a production database. They verify profile escalation rejection, ownership enforcement, report privacy, atomic boarding/leaving, last-seat concurrency and saved-route isolation. Implementation references: [Firebase transaction validation](https://firebase.google.com/docs/firestore/security/rules-conditions) and [emulator testing](https://firebase.google.com/docs/rules/unit-tests).

## Production boundaries

Live GPS tracking and calculated arrival times, mobile money collection, fare revenue reconciliation, regulatory credential verification, demand forecasting and emergency dispatch require additional providers and trusted backend workflows. They are not represented as working integrations. Data retention, account deletion and abuse controls also need an operational policy before a public launch. Test deployment configuration and existing-data migration in staging first. This change does not deploy rules or alter production records.
