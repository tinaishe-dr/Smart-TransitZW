enum RouteStatus { active, off, full }

class TransitRoute {
  final String name;
  final double fare;
  final RouteStatus status;

  TransitRoute({required this.name, required this.fare, required this.status});
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
