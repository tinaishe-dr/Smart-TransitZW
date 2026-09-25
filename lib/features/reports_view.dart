import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/transit_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key, required this.repository, required this.admin});
  final TransitRepository repository;
  final bool admin;
  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  late var _stream = widget.repository.watchReports(widget.admin);
  String _filter = 'all';
  final _pending = <String>{};
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reports could not be loaded.'),
              TextButton(
                onPressed: () => setState(
                  () => _stream = widget.repository.watchReports(widget.admin),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final all = snapshot.data!.docs.toList()
        ..sort(
          (a, b) =>
              ((b.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
                      0)
                  .compareTo(
                    (a.data()['timestamp'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0,
                  ),
        );
      final reports = all
          .where(
            (d) =>
                _filter == 'all' || (d.data()['status'] ?? 'open') == _filter,
          )
          .toList();
      return ListView.builder(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width >= 1000 ? 40 : 20,
        ),
        itemCount: reports.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.admin
                      ? 'Listen. Respond. Improve.'
                      : 'Your voice matters.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.admin
                      ? 'Review passenger concerns and keep resolutions visible.'
                      : 'Track your submitted reports and their resolution status.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: ['all', 'open', 'resolved']
                      .map(
                        (v) => ChoiceChip(
                          label: Text('${v[0].toUpperCase()}${v.substring(1)}'),
                          selected: _filter == v,
                          onSelected: (_) => setState(() => _filter = v),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                if (reports.isEmpty)
                  const EmptyState(
                    title: 'No reports here',
                    message: 'Reports submitted from a service appear here.',
                    icon: Icons.task_alt,
                  ),
              ],
            );
          }
          final doc = reports[index - 1];
          final data = doc.data();
          final resolved = data['status'] == 'resolved';
          final date = (data['timestamp'] as Timestamp?)?.toDate();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        data['issue'] as String? ?? 'Issue',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      StatusPill(
                        resolved ? 'Resolved' : 'Open',
                        color: resolved ? forest : const Color(0xFFA36512),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['routeName'] as String? ?? 'Service unavailable',
                    style: const TextStyle(color: muted),
                  ),
                  if ((data['details'] as String? ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(data['details'] as String),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    date == null
                        ? 'Submitting…'
                        : '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  if (widget.admin)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: _pending.contains(doc.id)
                            ? null
                            : () async {
                                setState(() => _pending.add(doc.id));
                                try {
                                  await widget.repository.resolveReport(
                                    doc.id,
                                    !resolved,
                                  );
                                  if (context.mounted) {
                                    showMessage(
                                      context,
                                      resolved
                                          ? 'Report reopened.'
                                          : 'Report marked as resolved.',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showMessage(context, friendlyError(e));
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _pending.remove(doc.id));
                                  }
                                }
                              },
                        icon: Icon(resolved ? Icons.undo : Icons.check),
                        label: Text(
                          resolved ? 'Reopen report' : 'Mark resolved',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
