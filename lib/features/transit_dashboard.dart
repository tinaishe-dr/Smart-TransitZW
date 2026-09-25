import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/transit_repository.dart';
import '../models/route_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/service_card.dart';
import '../widgets/workspace_sidebar.dart';
import 'service_forms.dart';
import 'reports_view.dart';

class TransitDashboard extends StatefulWidget {
  const TransitDashboard({
    super.key,
    required this.repository,
    required this.role,
    required this.company,
  });
  final TransitRepository repository;
  final String role, company;
  @override
  State<TransitDashboard> createState() => _TransitDashboardState();
}

class _TransitDashboardState extends State<TransitDashboard> {
  final _search = TextEditingController();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<TransitRoute>? _routes;
  Set<String> _saved = {};
  Map<String, dynamic>? _journey;
  String? _error, _accountError;
  bool _available = false, _cheapest = false;
  int _page = 0;
  final Set<String> _pending = {};
  late final Timer _clock;
  bool get _operator => widget.role == 'operator';
  bool get _admin => widget.role == 'admin';
  List<String> get _labels => [
    _admin
        ? 'Network overview'
        : _operator
        ? 'My services'
        : 'Find a ride',
    _operator
        ? 'Network'
        : _admin
        ? 'Services'
        : 'Saved routes',
    _admin ? 'Reports inbox' : 'My reports',
  ];
  @override
  void initState() {
    super.initState();
    _listen();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _listen() {
    _subscriptions.add(
      widget.repository.watchRoutes().listen(
        (routes) {
          if (mounted) {
            setState(() {
              _routes = routes;
              _error = null;
            });
          }
        },
        onError: (Object e) {
          if (mounted) setState(() => _error = friendlyError(e));
        },
      ),
    );
    _subscriptions.add(
      widget.repository.watchSaved().listen(
        (snapshot) {
          if (mounted) {
            setState(() => _saved = snapshot.docs.map((d) => d.id).toSet());
          }
        },
        onError: (Object e) {
          if (mounted) setState(() => _accountError = friendlyError(e));
        },
      ),
    );
    _subscriptions.add(
      widget.repository.watchJourney().listen(
        (snapshot) {
          if (mounted) setState(() => _journey = snapshot.data());
        },
        onError: (Object e) {
          if (mounted) setState(() => _accountError = friendlyError(e));
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _clock.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _act(
    String key,
    Future<void> Function() action,
    String success,
  ) async {
    if (_pending.contains(key)) return;
    setState(() => _pending.add(key));
    try {
      await action();
      if (mounted) showMessage(context, success);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _pending.remove(key));
    }
  }

  Future<void> _edit([TransitRoute? route]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RouteEditor(
        repository: widget.repository,
        company: widget.company,
        route: route,
      ),
    );
    if (saved == true && mounted) {
      showMessage(
        context,
        'Service published. Passengers can see your update.',
      );
    }
  }

  void _select(int page) => setState(() {
    _page = page;
    _search.clear();
    _available = false;
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1000;
      return Scaffold(
        appBar: wide
            ? null
            : AppBar(
                title: const Text(
                  'smarttransit',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: () => _act(
                      'logout',
                      () => FirebaseAuth.instance.signOut(),
                      'Signed out',
                    ),
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _page,
                onDestinationSelected: _select,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.route_outlined),
                    label: _admin
                        ? 'Overview'
                        : _operator
                        ? 'My services'
                        : 'Find a ride',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      _operator || _admin
                          ? Icons.public
                          : Icons.bookmark_border,
                    ),
                    label: _operator || _admin ? 'Network' : 'Saved',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.flag_outlined),
                    label: 'Reports',
                  ),
                ],
              ),
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                WorkspaceSidebar(
                  page: _page,
                  labels: _labels,
                  network: _operator || _admin,
                  onSelect: _select,
                  onSignOut: () => _act(
                    'logout',
                    () => FirebaseAuth.instance.signOut(),
                    'Signed out',
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (wide)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 23,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8DF)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _labels[_page],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.location_on_outlined,
                              color: muted,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Zimbabwe',
                              style: TextStyle(color: muted),
                            ),
                            const SizedBox(width: 24),
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xFFE3EBD9),
                              child: Text(
                                widget.role.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: forest),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.role[0].toUpperCase() +
                                  widget.role.substring(1),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _page == 2
                          ? ReportsView(
                              repository: widget.repository,
                              admin: _admin,
                            )
                          : _content(wide),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget _content(bool wide) {
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              EmptyState(
                title: 'Network unavailable',
                message: _error!,
                icon: Icons.cloud_off_outlined,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  for (final s in _subscriptions) {
                    await s.cancel();
                  }
                  _subscriptions.clear();
                  if (mounted) {
                    setState(() {
                      _error = null;
                      _routes = null;
                      _accountError = null;
                    });
                    _listen();
                  }
                },
                child: const Text('Reconnect'),
              ),
            ],
          ),
        ),
      );
    }
    if (_routes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final all = _routes!.where((r) => !r.archived).toList();
    final source = _operator && _page == 0
        ? all.where((r) => r.ownerId == widget.repository.uid).toList()
        : all;
    final shown = filterRoutes(
      source,
      query: _search.text,
      availableOnly: _available,
      cheapestFirst: _cheapest,
      savedIds: !_operator && !_admin && _page == 1 ? _saved : null,
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(wide ? 40 : 20, 30, wide ? 40 : 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _admin
                            ? 'A clearer view of your city.'
                            : _operator
                            ? 'Keep your city moving.'
                            : _page == 1
                            ? 'Your everyday routes.'
                            : 'Where are you headed?',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _admin
                            ? 'Service coverage and passenger feedback, in one place.'
                            : _operator
                            ? 'Manage your vehicles, fares and passenger updates.'
                            : 'Find your route. Know your fare. Travel with confidence.',
                        style: const TextStyle(color: muted),
                      ),
                    ],
                  ),
                  if (_operator)
                    FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add service'),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              if (!_admin && !_operator && _page == 0) _hero(),
              if (_accountError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Saved routes or journey unavailable. $_accountError',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ),
              if (_journey != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Panel(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(Icons.directions_bus, color: forest),
                        Text(
                          'On board: ${_journey!['routeName']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        OutlinedButton(
                          onPressed: _pending.contains('journey')
                              ? null
                              : () => _act(
                                  'journey',
                                  widget.repository.leave,
                                  'Journey ended. Thank you for travelling.',
                                ),
                          child: const Text('Leave service'),
                        ),
                      ],
                    ),
                  ),
                ),
              _stats(source),
              const SizedBox(height: 28),
              if (_admin && _page == 0) ...[
                _coverage(all),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _operator && _page == 0
                          ? 'Your vehicle services'
                          : _page == 1 && !_admin && !_operator
                          ? 'Saved routes'
                          : 'Explore services',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${shown.length} services',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search destination, route or operator',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(_search.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Seats available'),
                    selected: _available,
                    onSelected: (v) => setState(() => _available = v),
                  ),
                  FilterChip(
                    label: const Text('Lowest fare first'),
                    selected: _cheapest,
                    onSelected: (v) => setState(() => _cheapest = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Availability is operator-reported. Seat counts reflect app check-ins, not all passengers.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ]),
          ),
        ),
        if (shown.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                title: all.isEmpty
                    ? 'The network starts here.'
                    : 'No matching services',
                message: _operator && all.isEmpty
                    ? 'Add your first vehicle service to make it visible to commuters.'
                    : 'Try another search, change your filters or save a route using its bookmark.',
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(wide ? 40 : 20, 0, wide ? 40 : 20, 32),
          sliver: SliverList.builder(
            itemCount: shown.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _routeCard(shown[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() => Container(
    margin: const EdgeInsets.only(bottom: 22),
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: const Color(0xFFE7EEDC),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill('YOUR CITY, CONNECTED'),
              SizedBox(height: 14),
              Text(
                'Less guessing.\nMore getting there.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  letterSpacing: -.8,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Explore services and check availability before you set off.',
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 600)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Icon(Icons.directions_bus_rounded, size: 106, color: forest),
          ),
      ],
    ),
  );
  Widget _stats(List<TransitRoute> routes) => LayoutBuilder(
    builder: (context, constraints) {
      final values = [
        (
          '${routes.length}',
          _operator ? 'Your services' : 'Listed services',
          Icons.route,
        ),
        (
          '${routes.where((r) => r.status == RouteStatus.active).length}',
          'In service',
          Icons.directions_bus_outlined,
        ),
        (
          '${routes.fold<int>(0, (sum, r) => sum + (r.canBoard ? r.seatsLeft : 0))}',
          'Reported seats',
          Icons.event_seat_outlined,
        ),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: values
            .map(
              (item) => SizedBox(
                width: constraints.maxWidth < 480
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 24) / 3,
                child: Panel(
                  padding: 20,
                  child: Row(
                    children: [
                      Icon(item.$3, size: 24, color: forest),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
  Widget _coverage(List<TransitRoute> routes) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network availability',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Aggregated from registered services. This does not measure citywide demand or coverage of unregistered operators.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        ...RouteStatus.values.map((status) {
          final count = routes.where((r) => r.status == status).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(status.label),
                    const Spacer(),
                    Text('$count'),
                  ],
                ),
                const SizedBox(height: 7),
                LinearProgressIndicator(
                  value: routes.isEmpty ? 0 : count / routes.length,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          );
        }),
        Text(
          '${routes.where((r) => !r.isFresh(DateTime.now())).length} services have no operator update in the last 15 minutes.',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
  Widget _routeCard(TransitRoute route) {
    final manage = _operator && route.ownerId == widget.repository.uid;
    return ServiceCard(
      route: route,
      saved: _saved.contains(route.id),
      showCommuterActions: !_operator && !_admin,
      onSave: _pending.contains('save-${route.id}') || _accountError != null
          ? null
          : () => _act(
              'save-${route.id}',
              () => widget.repository.saveFavorite(
                route.id,
                !_saved.contains(route.id),
              ),
              _saved.contains(route.id)
                  ? 'Route removed from saved.'
                  : 'Route saved.',
            ),
      onManage: manage ? () => _edit(route) : null,
      onArchive: _pending.contains(route.id) ? null : () => _archive(route),
      onBoard:
          !route.canBoard ||
              _journey != null ||
              _accountError != null ||
              _pending.contains('journey')
          ? null
          : () => _board(route),
      onReport: () => _report(route),
    );
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _archive(TransitRoute route) async {
    if (await _confirm(
          'Archive this service?',
          '${route.name} will no longer appear to commuters. Existing reports are retained.',
          'Archive',
        ) &&
        mounted) {
      await _act(
        route.id,
        () => widget.repository.archiveRoute(route.id),
        'Service archived.',
      );
    }
  }

  Future<void> _board(TransitRoute route) async {
    if (await _confirm(
          'Are you boarding this vehicle?',
          'Check in to ${route.name} only when boarding. This does not reserve a seat or collect payment. Confirm the USD ${route.fare.toStringAsFixed(2)} fare with the operator.',
          'Confirm boarding',
        ) &&
        mounted) {
      await _act(
        'journey',
        () => widget.repository.board(route.id),
        'You are checked in. Have a safe journey.',
      );
    }
  }

  Future<void> _report(TransitRoute route) async {
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReportEditor(repository: widget.repository, route: route),
    );
    if (sent == true && mounted) {
      showMessage(context, 'Report submitted. Track it in My reports.');
    }
  }
}
