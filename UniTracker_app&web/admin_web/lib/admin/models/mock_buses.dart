import 'bus_route.dart';
import 'bus_stop.dart';

class MockBus {
  final String id;
  final String name;
  final String driver;
  final int capacity;
  final String route;
  final String status;
  final String lastMaintenance;
  final bool isTracking;

  MockBus({
    required this.id,
    required this.name,
    required this.driver,
    required this.capacity,
    required this.route,
    required this.status,
    required this.lastMaintenance,
    this.isTracking = false,
  });

  MockBus copyWith({
    String? id,
    String? name,
    String? driver,
    int? capacity,
    String? route,
    String? status,
    String? lastMaintenance,
    bool? isTracking,
  }) {
    return MockBus(
      id: id ?? this.id,
      name: name ?? this.name,
      driver: driver ?? this.driver,
      capacity: capacity ?? this.capacity,
      route: route ?? this.route,
      status: status ?? this.status,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}

final mockBuses = [
  MockBus(
    id: 'BUS-101',
    name: 'Campus Express 1',
    driver: 'John Smith',
    capacity: 40,
    route: 'North Campus Loop',
    status: 'Active',
    lastMaintenance: '2023-10-15',
    isTracking: false,
  ),
  MockBus(
    id: 'BUS-102',
    name: 'Campus Express 2',
    driver: 'Sarah Johnson',
    capacity: 40,
    route: 'South Campus Loop',
    status: 'Active',
    lastMaintenance: '2023-11-02',
    isTracking: false,
  ),
  MockBus(
    id: 'BUS-103',
    name: 'Campus Express 3',
    driver: 'Michael Brown',
    capacity: 30,
    route: 'East Campus Loop',
    status: 'Maintenance',
    lastMaintenance: '2024-01-10',
    isTracking: false,
  ),
  MockBus(
    id: 'BUS-104',
    name: 'Campus Express 4',
    driver: 'Emily Davis',
    capacity: 40,
    route: 'West Campus Loop',
    status: 'Active',
    lastMaintenance: '2023-12-05',
    isTracking: false,
  ),
  MockBus(
    id: 'BUS-105',
    name: 'Campus Shuttle 1',
    driver: 'Robert Wilson',
    capacity: 25,
    route: 'Downtown Connector',
    status: 'Inactive',
    lastMaintenance: '2023-09-20',
    isTracking: false,
  ),
];

final mockBusRoutes = [
  BusRoute(
    id: 'route1',
    name: 'North Campus Loop',
    pickup: 'North Gate',
    drop: 'Main Library',
    startTime: '07:00',
    endTime: '19:00',
    stops: List.generate(
        8,
            (i) => BusStop(
          id: 'ncl-${i + 1}',
          name: 'Stop ${i + 1}',
          order: i + 1,
          arrivalTime: '07:${(i * 5).toString().padLeft(2, '0')} AM',
        )),
    iconColor: 'FF5733',
  ),
  BusRoute(
    id: 'route2',
    name: 'South Campus Loop',
    pickup: 'South Gate',
    drop: 'Engineering Hall',
    startTime: '07:15',
    endTime: '19:15',
    stops: List.generate(
        6,
            (i) => BusStop(
          id: 'scl-${i + 1}',
          name: 'Stop ${i + 1}',
          order: i + 1,
          arrivalTime: '07:${(15 + i * 5).toString().padLeft(2, '0')} AM',
        )),
    iconColor: '33C1FF',
  ),
  BusRoute(
    id: 'route3',
    name: 'East Campus Loop',
    pickup: 'East Gate',
    drop: 'Sports Complex',
    startTime: '07:30',
    endTime: '19:30',
    stops: List.generate(
        5,
            (i) => BusStop(
          id: 'ecl-${i + 1}',
          name: 'Stop ${i + 1}',
          order: i + 1,
          arrivalTime: '07:${(30 + i * 5).toString().padLeft(2, '0')} AM',
        )),
    iconColor: '22C55E',
  ),
  BusRoute(
    id: 'route4',
    name: 'West Campus Loop',
    pickup: 'West Gate',
    drop: 'Dormitories',
    startTime: '07:45',
    endTime: '19:45',
    stops: List.generate(
        7,
            (i) => BusStop(
          id: 'wcl-${i + 1}',
          name: 'Stop ${i + 1}',
          order: i + 1,
          arrivalTime: '07:${(45 + i * 5).toString().padLeft(2, '0')} AM',
        )),
    iconColor: 'F59E42',
  ),
  BusRoute(
    id: 'route5',
    name: 'Downtown Connector',
    pickup: 'Central Station',
    drop: 'City Park',
    startTime: '08:00',
    endTime: '20:00',
    stops: List.generate(
        10,
            (i) => BusStop(
          id: 'dc-${i + 1}',
          name: 'Stop ${i + 1}',
          order: i + 1,
          arrivalTime: '08:${(i * 5).toString().padLeft(2, '0')} AM',
        )),
    iconColor: 'A855F7',
  ),
  BusRoute(
    id: 'route6',
    name: 'Weekend Express',
    pickup: 'Campus Center',
    drop: 'Shopping Mall',
    startTime: '09:00',
    endTime: '18:00',
    stops: List.generate(
        4,
            (i) => BusStop(
          id: 'we-${i + 1}',
          name: 'Stop ${i + 1}',
          order: i + 1,
          arrivalTime: '09:${(i * 5).toString().padLeft(2, '0')} AM',
        )),
    iconColor: 'F43F5E',
  ),
];
