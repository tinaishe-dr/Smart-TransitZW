import 'package:flutter/material.dart';
import '../models/route_model.dart';
import 'reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_route_screen.dart';
import 'edit_fare_screen.dart';
import 'app_drawer.dart';

class RouteListScreen extends StatefulWidget {
  final bool isOperator;

  const RouteListScreen({super.key, required this.isOperator});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  bool _sortByFare = false;

  // ---- Design tokens (LeafLight-inspired) ----
  static const Color _bg = Color(0xFFF3F5F9);
  static const List<Color> _heroGradient = [
    Color(0xFF0D3B84),
    Color(0xFF1E70C7),
  ];
  static const List<Color> _blueGradient = [
    Color(0xFF1565C0),
    Color(0xFF2196F3),
  ];
  static const List<Color> _greenGradient = [
    Color(0xFF00897B),
    Color(0xFF26C6A2),
  ];
  static const List<Color> _orangeGradient = [
    Color(0xFFEF6C00),
    Color(0xFFFFA726),
  ];
  static const List<Color> _purpleGradient = [
    Color(0xFF6A1B9A),
    Color(0xFF9C4DCC),
  ];

  // ---- Firestore actions (unchanged logic) ----
  void _submitReport(String routeName, String issue) {
    FirebaseFirestore.instance.collection('reports').add({
      'routeName': routeName,
      'issue': issue,
      'timestamp': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Report submitted: $issue')));
  }

  void _showReportDialog(BuildContext context, TransitRoute route) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Report: ${route.name}'),
          content: const Text('What went wrong?'),
          actions: [
            TextButton(
              onPressed: () => _submitReport(route.name, 'Overcharging'),
              child: const Text('Overcharging'),
            ),
            TextButton(
              onPressed: () => _submitReport(route.name, 'No-show'),
              child: const Text('No-show'),
            ),
            TextButton(
              onPressed: () => _submitReport(route.name, 'Unsafe driving'),
              child: const Text('Unsafe driving'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDeleteReturnsBool(
    BuildContext context,
    TransitRoute route,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete route?'),
          content: Text('This will permanently remove "${route.name}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('routes')
          .doc(route.id)
          .delete();
      return true;
    }
    return false;
  }

  void _openEditFare(BuildContext context, TransitRoute route) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditFareScreen(route: route)),
    );
  }

  void _confirmLeave(
    BuildContext context,
    TransitRoute route,
    String uid,
    int onboardCount,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Leave this route?'),
          content: const Text('You will no longer be marked as onboard.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay onboard'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('routes')
                    .doc(route.id)
                    .collection('passengers')
                    .doc(uid)
                    .delete();

                if (route.status == RouteStatus.full &&
                    onboardCount - 1 < route.capacity) {
                  await FirebaseFirestore.instance
                      .collection('routes')
                      .doc(route.id)
                      .update({'status': 'active'});
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _boardRoute(
    BuildContext context,
    TransitRoute route,
    String? currentUid,
    int onboardCount,
    int seatsLeft,
  ) {
    if (route.status != RouteStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This vehicle is currently off. Cannot board.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (seatsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This vehicle is full. Cannot board.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final passengerRef = FirebaseFirestore.instance
        .collection('routes')
        .doc(route.id)
        .collection('passengers')
        .doc(currentUid);

    passengerRef.set({'boardedAt': FieldValue.serverTimestamp()});

    if (onboardCount + 1 >= route.capacity) {
      FirebaseFirestore.instance.collection('routes').doc(route.id).update({
        'status': 'full',
      });
    }
  }

  // ---- Style helpers ----
  ({Color color, String label, IconData icon}) _statusMeta(RouteStatus status) {
    switch (status) {
      case RouteStatus.active:
        return (
          color: const Color(0xFF2E7D32),
          label: 'Active',
          icon: Icons.check_circle,
        );
      case RouteStatus.off:
        return (
          color: const Color(0xFFC62828),
          label: 'Off',
          icon: Icons.cancel,
        );
      case RouteStatus.full:
        return (
          color: const Color(0xFFEF6C00),
          label: 'Full',
          icon: Icons.error,
        );
    }
  }

  String _initials(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      drawer: AppDrawer(
        roleLabel: widget.isOperator ? 'Operator' : 'Commuter',
        items: [
          AppDrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: true,
            onTap: () {},
          ),
          if (widget.isOperator)
            AppDrawerItem(
              icon: Icons.add_road,
              label: 'Add Route',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRouteScreen(),
                  ),
                );
              },
            ),
          if (!widget.isOperator)
            AppDrawerItem(
              icon: Icons.list_alt,
              label: 'My Reports',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
          AppDrawerItem(
            icon: Icons.attach_money,
            label: 'Sort by Fare',
            onTap: () => setState(() => _sortByFare = !_sortByFare),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(child: _buildHero(context, user, 0, 0)),
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No routes yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final routes = snapshot.data!.docs.map((doc) {
            return TransitRoute.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
          if (_sortByFare) {
            routes.sort((a, b) => a.fare.compareTo(b.fare));
          }

          final activeCount = routes
              .where((r) => r.status == RouteStatus.active)
              .length;

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: _buildHero(context, user, routes.length, activeCount),
              ),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRouteCard(context, routes[index]),
                    childCount: routes.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(widget.isOperator ? 'Operator View' : 'SmartTransitZW'),
      actions: [
        if (!widget.isOperator)
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
        IconButton(
          icon: Icon(_sortByFare ? Icons.sort : Icons.sort_by_alpha),
          tooltip: 'Sort by fare',
          onPressed: () => setState(() => _sortByFare = !_sortByFare),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }

  Widget _buildHero(
    BuildContext context,
    User? user,
    int totalRoutes,
    int activeCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Text(
                  _initials(user?.email),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      user?.email?.split('@').first ??
                          (widget.isOperator ? 'Operator' : 'Commuter'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$activeCount Live',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalRoutes ${totalRoutes == 1 ? 'route' : 'routes'} tracked',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$activeCount currently active',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final tiles = <_QuickAction>[
      if (widget.isOperator)
        _QuickAction(
          icon: Icons.add_road,
          title: 'Add Route',
          subtitle: 'Create new route',
          gradient: _blueGradient,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRouteScreen()),
          ),
        ),
      if (!widget.isOperator)
        _QuickAction(
          icon: Icons.list_alt,
          title: 'My Reports',
          subtitle: 'View submitted reports',
          gradient: _blueGradient,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          ),
        ),
      _QuickAction(
        icon: Icons.attach_money,
        title: 'Sort by Fare',
        subtitle: _sortByFare ? 'Sorting: cheapest first' : 'Tap to sort',
        gradient: _greenGradient,
        onTap: () => setState(() => _sortByFare = !_sortByFare),
      ),
      if (widget.isOperator)
        _QuickAction(
          icon: Icons.swap_horiz,
          title: 'Manage',
          subtitle: 'Swipe your routes to edit/delete',
          gradient: _orangeGradient,
          onTap: () {},
        ),
      if (!widget.isOperator)
        _QuickAction(
          icon: Icons.flag_outlined,
          title: 'Report Issue',
          subtitle: 'Flag a problem on a route',
          gradient: _purpleGradient,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tap the flag icon on a route below'),
              ),
            );
          },
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: tiles.map((t) => _quickActionCard(t)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard(_QuickAction action) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: action.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: action.gradient.last.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(action.icon, color: Colors.white, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, TransitRoute route) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = route.ownerId == currentUid;
    final canManage = widget.isOperator && isOwner;
    final meta = _statusMeta(route.status);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('routes')
          .doc(route.id)
          .collection('passengers')
          .snapshots(),
      builder: (context, passengerSnapshot) {
        final passengerDocs = passengerSnapshot.data?.docs ?? [];
        final onboardCount = passengerDocs.length;
        final isOnboard = passengerDocs.any((doc) => doc.id == currentUid);
        final seatsLeft = route.capacity - onboardCount;

        final card = Opacity(
          opacity: widget.isOperator && !isOwner ? 0.55 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          color: meta.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fare: \$${route.fare.toStringAsFixed(2)} • $onboardCount/${route.capacity} onboard'
                              '${route.ownerId != null && !isOwner ? " • ${route.company ?? "Unknown company"}" : ""}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(meta.icon, size: 12, color: meta.color),
                            const SizedBox(width: 4),
                            Text(
                              meta.label,
                              style: TextStyle(
                                color: meta.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.isOperator && !isOwner) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Not your route',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!widget.isOperator) ...[
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              if (isOnboard) {
                                _confirmLeave(
                                  context,
                                  route,
                                  currentUid!,
                                  onboardCount,
                                );
                                return;
                              }
                              _boardRoute(
                                context,
                                route,
                                currentUid,
                                onboardCount,
                                seatsLeft,
                              );
                            },
                            icon: Icon(
                              isOnboard
                                  ? Icons.directions_bus
                                  : Icons.directions_bus_outlined,
                              size: 18,
                              color: isOnboard
                                  ? const Color(0xFF2E7D32)
                                  : (seatsLeft <= 0 ||
                                        route.status != RouteStatus.active)
                                  ? Colors.grey
                                  : const Color(0xFF1565C0),
                            ),
                            label: Text(
                              isOnboard ? 'Leave' : 'Board',
                              style: TextStyle(
                                color: isOnboard
                                    ? const Color(0xFF2E7D32)
                                    : (seatsLeft <= 0 ||
                                          route.status != RouteStatus.active)
                                    ? Colors.grey
                                    : const Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _showReportDialog(context, route),
                            icon: const Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Report',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (canManage) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Tap card to cycle status • swipe to edit/delete',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        return Dismissible(
          key: Key(route.id),
          direction: canManage
              ? DismissDirection.horizontal
              : DismissDirection.none,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return await _confirmDeleteReturnsBool(context, route);
            } else {
              _openEditFare(context, route);
              return false;
            }
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: GestureDetector(
            onTap: canManage
                ? () {
                    FirebaseFirestore.instance
                        .collection('routes')
                        .doc(route.id)
                        .update({'status': route.status.next().name});
                  }
                : null,
            child: card,
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}
