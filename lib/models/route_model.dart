enum RouteStatus { active, off, full }

class TransitRoute {
  final String name;
  final double fare;
  final RouteStatus status;

  TransitRoute({required this.name, required this.fare, required this.status});
}
