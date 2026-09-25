import 'package:cloud_firestore/cloud_firestore.dart';

enum RouteStatus { active, off, full }

class TransitRoute {
  const TransitRoute({
    required this.id,
    required this.name,
    required this.fare,
    required this.status,
    this.ownerId,
    this.company,
    this.capacity = 0,
    this.onboard = 0,
    this.vehicle = '',
    this.origin = '',
    this.destination = '',
    this.notice = '',
    this.updatedAt,
    this.departureAt,
    this.archived = false,
    this.occupancyKnown = true,
  });
  final String id, name, vehicle, origin, destination, notice;
  final double fare;
  final RouteStatus status;
  final String? ownerId, company;
  final int capacity, onboard;
  final DateTime? updatedAt, departureAt;
  final bool archived, occupancyKnown;
  int get seatsLeft =>
      (capacity - onboard).clamp(0, capacity < 0 ? 0 : capacity);
  bool get canBoard =>
      occupancyKnown &&
      !archived &&
      status == RouteStatus.active &&
      seatsLeft > 0;
  bool isFresh(DateTime now) =>
      updatedAt != null && now.difference(updatedAt!).inMinutes < 15;
  factory TransitRoute.fromFirestore(String id, Map<String, dynamic> data) {
    return TransitRoute(
      id: id,
      name: data['name'] as String? ?? 'Unnamed service',
      fare: (data['fare'] as num?)?.toDouble() ?? 0,
      status: RouteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RouteStatus.off,
      ),
      ownerId: data['ownerId'] as String?,
      company: data['company'] as String?,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      onboard: (data['onboard'] as num?)?.toInt() ?? 0,
      occupancyKnown: data['onboard'] is num,
      vehicle: data['vehicle'] as String? ?? '',
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      notice: data['notice'] as String? ?? '',
      archived: data['archived'] == true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      departureAt: (data['departureAt'] as Timestamp?)?.toDate(),
    );
  }
}

extension RouteStatusX on RouteStatus {
  RouteStatus next() => switch (this) {
    RouteStatus.active => RouteStatus.full,
    RouteStatus.full => RouteStatus.off,
    RouteStatus.off => RouteStatus.active,
  };
  String get label => switch (this) {
    RouteStatus.active => 'In service',
    RouteStatus.full => 'Full',
    RouteStatus.off => 'Off duty',
  };
}

List<TransitRoute> filterRoutes(
  Iterable<TransitRoute> routes, {
  String query = '',
  bool availableOnly = false,
  bool cheapestFirst = false,
  Set<String>? savedIds,
}) {
  final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
  final result = routes
      .where(
        (r) =>
            !r.archived &&
            (!availableOnly || r.canBoard) &&
            (savedIds == null || savedIds.contains(r.id)) &&
            terms.every(
              (term) =>
                  '${r.name} ${r.origin} ${r.destination} ${r.company ?? ''} ${r.vehicle}'
                      .toLowerCase()
                      .contains(term),
            ),
      )
      .toList();
  result.sort(
    (a, b) => cheapestFirst && a.fare != b.fare
        ? a.fare.compareTo(b.fare)
        : a.name.compareTo(b.name),
  );
  return result;
}
