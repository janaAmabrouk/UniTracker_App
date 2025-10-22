import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';

class ReservationSlot {
  final String direction;
  final String route;
  final DateTime date;
  final TimeOfDay time;

  ReservationSlot({
    required this.direction,
    required this.route,
    required this.date,
    required this.time,
  });
}

class ReservationSlotManagementScreen extends StatefulWidget {
  const ReservationSlotManagementScreen({Key? key}) : super(key: key);

  @override
  State<ReservationSlotManagementScreen> createState() =>
      _ReservationSlotManagementScreenState();
}

class _ReservationSlotManagementScreenState
    extends State<ReservationSlotManagementScreen> {
  final List<ReservationSlot> _reservationSlots = [];
  String _direction = 'To University';
  String? _route;
  DateTime? _date;
  TimeOfDay? _time;
  final _formKey = GlobalKey<FormState>();

  void _addReservationSlot() {
    if (_formKey.currentState!.validate() &&
        _date != null &&
        _time != null &&
        _route != null) {
      setState(() {
        _reservationSlots.add(ReservationSlot(
          direction: _direction,
          route: _route!,
          date: _date!,
          time: _time!,
        ));
        _route = null;
        _date = null;
        _time = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Reservation slot added!'),
            backgroundColor: Colors.green),
      );
    }
  }

  void _deleteReservationSlot(int index) {
    setState(() {
      _reservationSlots.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Reservation slot deleted!'),
          backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 54),
            Text(
              'Reservation Slot Management',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set up and manage available reservation slots for students.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Direction Toggle
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Direction',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      ToggleButtons(
                                        borderRadius: BorderRadius.circular(8),
                                        isSelected: [
                                          _direction == 'To University',
                                          _direction == 'From University'
                                        ],
                                        onPressed: (index) {
                                          setState(() {
                                            _direction = index == 0
                                                ? 'To University'
                                                : 'From University';
                                          });
                                        },
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Text('To University'),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Text('From University'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Route Dropdown
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: _route,
                                    decoration: const InputDecoration(
                                        labelText: 'Route'),
                                    items: ['Route 1', 'Route 2', 'Route 3']
                                        .map((route) => DropdownMenuItem(
                                            value: route, child: Text(route)))
                                        .toList(),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Select route'
                                            : null,
                                    onChanged: (value) =>
                                        setState(() => _route = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Date Picker
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Date',
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    controller: TextEditingController(
                                      text: _date != null
                                          ? "${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}"
                                          : '',
                                    ),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (picked != null)
                                        setState(() => _date = picked);
                                    },
                                    validator: (value) =>
                                        _date == null ? 'Select date' : null,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Time Picker
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Time',
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    controller: TextEditingController(
                                      text: _time != null
                                          ? _time!.format(context)
                                          : '',
                                    ),
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null)
                                        setState(() => _time = picked);
                                    },
                                    validator: (value) =>
                                        _time == null ? 'Select time' : null,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Add Button
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  label: const Text('Add Reservation Slot'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _addReservationSlot,
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Column layout for mobile/narrow screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Direction',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            ToggleButtons(
                              borderRadius: BorderRadius.circular(8),
                              isSelected: [
                                _direction == 'To University',
                                _direction == 'From University'
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _direction = index == 0
                                      ? 'To University'
                                      : 'From University';
                                });
                              },
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('To University'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('From University'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _route,
                              decoration:
                                  const InputDecoration(labelText: 'Route'),
                              items: ['Route 1', 'Route 2', 'Route 3']
                                  .map((route) => DropdownMenuItem(
                                      value: route, child: Text(route)))
                                  .toList(),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Select route'
                                      : null,
                              onChanged: (value) =>
                                  setState(() => _route = value),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text: _date != null
                                    ? "${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}"
                                    : '',
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null)
                                  setState(() => _date = picked);
                              },
                              validator: (value) =>
                                  _date == null ? 'Select date' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              controller: TextEditingController(
                                text:
                                    _time != null ? _time!.format(context) : '',
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null)
                                  setState(() => _time = picked);
                              },
                              validator: (value) =>
                                  _time == null ? 'Select time' : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add Reservation Slot'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _addReservationSlot,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Available Reservation Slots:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _reservationSlots.isEmpty
                ? const Text('No slots added yet.',
                    style: TextStyle(color: Colors.grey))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reservationSlots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final slot = _reservationSlots[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.event_seat,
                              color: Theme.of(context).primaryColor),
                          title: Text('${slot.direction} - ${slot.route}'),
                          subtitle: Text(
                            '${slot.date.year}-${slot.date.month.toString().padLeft(2, '0')}-${slot.date.day.toString().padLeft(2, '0')} at ${slot.time.format(context)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteReservationSlot(index),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
