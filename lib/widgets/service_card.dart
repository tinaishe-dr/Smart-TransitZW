import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// A service's public information. Permissions and persistence are supplied by
/// the workspace, keeping this widget usable across operator and commuter views.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.route,
    this.saved = false,
    this.onSave,
    this.onBoard,
    this.onReport,
    this.onManage,
    this.onArchive,
    this.showCommuterActions = false,
  });
  final TransitRoute route;
  final bool saved, showCommuterActions;
  final VoidCallback? onSave, onBoard, onReport, onManage, onArchive;

  @override
  Widget build(BuildContext context) {
    final fresh = route.isFresh(DateTime.now());
    return Panel(
      padding: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus_outlined, color: forest),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${route.company ?? 'Operator not specified'}${route.vehicle.isEmpty ? '' : ' · ${route.vehicle}'}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (showCommuterActions)
                IconButton(
                  tooltip: saved ? 'Unsave route' : 'Save route',
                  onPressed: onSave,
                  icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    color: forest,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (route.origin.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                '${route.origin}  →  ${route.destination}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                route.status.label,
                color: route.status == RouteStatus.active
                    ? forest
                    : route.status == RouteStatus.full
                    ? const Color(0xFFA36512)
                    : muted,
              ),
              Text(
                route.occupancyKnown
                    ? '${route.seatsLeft} / ${route.capacity} seats available'
                    : 'Seat count unavailable',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              Text(
                'USD ${route.fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            route.updatedAt == null
                ? 'No recent operator update'
                : '${fresh ? 'Updated' : 'Update may be stale •'} ${_relative(route.updatedAt!)}',
            style: TextStyle(
              color: fresh ? muted : const Color(0xFFA36512),
              fontSize: 12,
            ),
          ),
          if (route.departureAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${route.departureAt!.isBefore(DateTime.now()) ? 'Last planned departure' : 'Planned departure'}: ${MaterialLocalizations.of(context).formatShortDate(route.departureAt!)} ${TimeOfDay.fromDateTime(route.departureAt!).format(context)} · operator estimate',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
          if (route.notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(route.notice),
            ),
          const Divider(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onManage != null) ...[
                FilledButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Manage service'),
                ),
                TextButton(onPressed: onArchive, child: const Text('Archive')),
              ] else if (showCommuterActions) ...[
                FilledButton.icon(
                  onPressed: onBoard,
                  icon: const Icon(Icons.directions_bus_outlined, size: 17),
                  label: const Text('Board service'),
                ),
                TextButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 17),
                  label: const Text('Report issue'),
                ),
              ] else
                const Text(
                  'Operator-managed availability',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _relative(DateTime date) {
    final minutes = DateTime.now().difference(date).inMinutes;
    return minutes < 1
        ? 'just now'
        : minutes < 60
        ? '$minutes min ago'
        : minutes < 1440
        ? '${minutes ~/ 60} hr ago'
        : '${minutes ~/ 1440} days ago';
  }
}
