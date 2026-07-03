enum RouteStatus { active, off, full }

class TransitRoute {
  final String id;
  final String name;
  final double fare;
  final RouteStatus status;
  final String? ownerId;
  final String? company;
  final int capacity;

  TransitRoute({
    required this.id,
    required this.name,
    required this.fare,
    required this.status,
    this.ownerId,
    this.company,
    this.capacity = 0,
  });

  factory TransitRoute.fromFirestore(String id, Map<String, dynamic> data) {
    return TransitRoute(
      id: id,
      name: data['name'] as String,
      fare: (data['fare'] as num).toDouble(),
      status: RouteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RouteStatus.active,
      ),
      ownerId: data['ownerId'] as String?,
      company: data['company'] as String?,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}

extension RouteStatusX on RouteStatus {
  RouteStatus next() {
    switch (this) {
      case RouteStatus.active:
        return RouteStatus.full;
      case RouteStatus.full:
        return RouteStatus.off;
      case RouteStatus.off:
        return RouteStatus.active;
    }
  }
}
