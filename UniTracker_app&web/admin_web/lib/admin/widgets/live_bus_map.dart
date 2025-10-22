import 'package:flutter/material.dart';

class LiveBusMap extends StatelessWidget {
  const LiveBusMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock bus marker positions
    final markers = [
      {'left': 60.0, 'top': 80.0, 'id': 1, 'color': Colors.green},
      {'left': 120.0, 'top': 120.0, 'id': 2, 'color': Colors.green},
      {'left': 180.0, 'top': 60.0, 'id': 3, 'color': Colors.amber},
      {'left': 80.0, 'top': 180.0, 'id': 4, 'color': Colors.green},
    ];
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: NetworkImage(
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?fit=crop&w=600&q=80'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          ...markers.map((marker) => Positioned(
                left: marker['left'] as double,
                top: marker['top'] as double,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: marker['color'] as Color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      marker['id'].toString(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
