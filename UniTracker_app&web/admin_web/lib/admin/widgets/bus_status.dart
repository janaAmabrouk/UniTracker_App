import 'package:flutter/material.dart';

class BusStatus extends StatelessWidget {
  const BusStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buses = [
      {'name': 'Bus 101', 'route': 'North Campus', 'status': 'On Time'},
      {'name': 'Bus 102', 'route': 'South Campus', 'status': 'On Time'},
      {'name': 'Bus 103', 'route': 'East Campus', 'status': 'Delayed'},
      {'name': 'Bus 104', 'route': 'West Campus', 'status': 'On Time'},
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bus Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...buses.map((bus) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bus['status'] == 'On Time'
                              ? Colors.green
                              : Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(bus['name'] as String),
                      const SizedBox(width: 16),
                      Text(bus['route'] as String,
                          style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Text(bus['status'] as String,
                          style: TextStyle(
                              color: bus['status'] == 'On Time'
                                  ? Colors.green
                                  : Colors.amber)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
