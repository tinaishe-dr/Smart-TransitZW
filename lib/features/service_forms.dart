import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/transit_repository.dart';
import '../models/route_model.dart';
import '../widgets/common.dart';

class RouteEditor extends StatefulWidget {
  const RouteEditor({
    super.key,
    required this.repository,
    required this.company,
    this.route,
  });
  final TransitRepository repository;
  final String company;
  final TransitRoute? route;
  @override
  State<RouteEditor> createState() => _RouteEditorState();
}

class _RouteEditorState extends State<RouteEditor> {
  final _form = GlobalKey<FormState>();
  late final _origin = TextEditingController(text: widget.route?.origin);
  late final _destination = TextEditingController(
    text: widget.route?.destination,
  );
  late final _name = TextEditingController(text: widget.route?.name);
  late final _vehicle = TextEditingController(text: widget.route?.vehicle);
  late final _fare = TextEditingController(
    text: widget.route?.fare.toStringAsFixed(2),
  );
  late final _capacity = TextEditingController(
    text: widget.route?.capacity.toString(),
  );
  late final _notice = TextEditingController(text: widget.route?.notice);
  late RouteStatus _status = widget.route?.status ?? RouteStatus.off;
  DateTime? _departure;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _departure = widget.route?.departureAt;
  }

  @override
  void dispose() {
    for (final c in [
      _origin,
      _destination,
      _name,
      _vehicle,
      _fare,
      _capacity,
      _notice,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.saveRoute({
        'name': _name.text.trim(),
        'origin': _origin.text.trim(),
        'destination': _destination.text.trim(),
        'vehicle': _vehicle.text.trim().toUpperCase(),
        'fare': double.parse(_fare.text),
        'capacity': int.parse(_capacity.text),
        'company': widget.route?.company ?? widget.company,
        'notice': _notice.text.trim(),
        'status': _status.name,
        'departureAt': _departure == null
            ? null
            : Timestamp.fromDate(_departure!),
      }, id: widget.route?.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int max = 100,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      maxLength: max,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'This field is required' : null,
    ),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.route == null ? 'Add a vehicle service' : 'Manage service',
    ),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Each service represents one vehicle on a route. Publish updates whenever availability changes.',
              ),
              const SizedBox(height: 20),
              _field(_name, 'Service name'),
              _field(_origin, 'From / boarding point'),
              _field(_destination, 'To / destination'),
              _field(_vehicle, 'Vehicle registration', max: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fare,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Fare (USD)',
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return n == null || !n.isFinite || n <= 0 || n > 1000
                            ? 'Enter USD 0.01–1,000'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Seats'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 1 || n > 100
                            ? 'Enter 1–100 seats'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<RouteStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Availability'),
                items: RouteStatus.values
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notice,
                maxLength: 300,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Passenger notice (optional)',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _departure == null
                          ? 'Set planned departure'
                          : 'Departure: ${TimeOfDay.fromDateTime(_departure!).format(context)}',
                    ),
                    onPressed: _busy
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time == null || !mounted) return;
                            final now = DateTime.now();
                            var date = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              time.hour,
                              time.minute,
                            );
                            if (date.isBefore(now)) {
                              date = date.add(const Duration(days: 1));
                            }
                            setState(() => _departure = date);
                          },
                  ),
                  if (_departure != null)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _departure = null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const Text(
                'Departure is operator-reported, not a GPS arrival estimate.',
                style: TextStyle(fontSize: 12),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Saving…' : 'Publish service'),
      ),
    ],
  );
}

class ReportEditor extends StatefulWidget {
  const ReportEditor({
    super.key,
    required this.repository,
    required this.route,
  });
  final TransitRepository repository;
  final TransitRoute route;
  @override
  State<ReportEditor> createState() => _ReportEditorState();
}

class _ReportEditorState extends State<ReportEditor> {
  final _details = TextEditingController();
  String _issue = 'Unsafe driving';
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Report an issue'),
    content: SizedBox(
      width: 430,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.route.name),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _issue,
              decoration: const InputDecoration(labelText: 'What happened?'),
              items: [
                'Unsafe driving',
                'Overcharging',
                'No-show',
                'Overcrowding',
                'Other',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: _busy ? null : (v) => setState(() => _issue = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _details,
              maxLength: 1000,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Where and when did this happen?',
              ),
            ),
            const Text(
              'Only you and authorised administrators can view this report. This is not an emergency response service.',
              style: TextStyle(fontSize: 12),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy
            ? null
            : () async {
                setState(() {
                  _busy = true;
                  _error = null;
                });
                try {
                  await widget.repository.report(
                    widget.route,
                    _issue,
                    _details.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (mounted) setState(() => _error = friendlyError(e));
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
        child: Text(_busy ? 'Submitting…' : 'Submit report'),
      ),
    ],
  );
}
