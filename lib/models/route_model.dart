enum RouteStatus { active, off, full }

class TransitRoute {
  final String id;
  final String name;
  final double fare;
  final RouteStatus status;

  TransitRoute({
    required this.id,
    required this.name,
    required this.fare,
    required this.status,
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
