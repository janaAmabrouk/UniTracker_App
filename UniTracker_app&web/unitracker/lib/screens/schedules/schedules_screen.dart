import 'package:flutter/material.dart';
import 'package:unitracker/models/bus_route.dart' as bus_route_model;
import 'package:unitracker/models/bus_stop.dart' as bus_stop_model;
import 'package:unitracker/screens/schedules/route_details_screen.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/utils/size_config.dart' as sz;
import 'package:unitracker/widgets/toggle_button.dart';
import '../../utils/responsive_utils.dart' as ru;

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTab = 'all';
  bool _isSearchVisible = false;
  bool _isFilterVisible = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'morning', 'afternoon'
  bool _showFavoritesOnly = false;
  String _selectedRouteType = 'To University';

  List<bus_route_model.BusRoute> routes = [
    bus_route_model.BusRoute(
      id: 'R1',
      name: 'Masr El Gedida Route',
      pickup: 'Koleyet El Banat',
      drop: 'EUI Campus',
      startTime: '07:50 AM',
      endTime: '08:45 AM',
      iconColor: 'E9EFFC',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R1-S1',
          name: 'Koleyet El Banat',
          order: 1,
          departureTime: '07:50 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R1-S2',
          name: 'El Marghany St.',
          order: 2,
          arrivalTime: '07:55 AM',
          departureTime: '07:57 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R1-S3',
          name: 'Roxy - Arrabiata',
          order: 3,
          arrivalTime: '08:00 AM',
          departureTime: '08:02 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R1-S4',
          name: 'Roxy Cinema',
          order: 4,
          arrivalTime: '08:05 AM',
          departureTime: '08:07 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R1-S5',
          name: 'Tseppas Patisterrie - Haroun El Rasheed St.',
          order: 5,
          arrivalTime: '08:10 AM',
          departureTime: '08:12 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R1-S6',
          name: 'Tivoli Dome',
          order: 6,
          arrivalTime: '08:17 AM',
          departureTime: '08:19 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R1-S7',
          name: 'EUI Campus',
          order: 7,
          arrivalTime: '08:45 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R2',
      name: 'Maadi Route',
      pickup: 'Maadi',
      drop: 'EUI Campus',
      startTime: '07:20 AM',
      endTime: '08:45 AM',
      iconColor: 'E1F6EF',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R2-S1',
          name: 'El Cornishe HSBC Bank',
          order: 1,
          departureTime: '07:20 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S2',
          name: 'Military Hospital',
          order: 2,
          arrivalTime: '07:25 AM',
          departureTime: '07:27 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S3',
          name: 'House of Donuts',
          order: 3,
          arrivalTime: '07:30 AM',
          departureTime: '07:32 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S4',
          name: 'El Horia Square',
          order: 4,
          arrivalTime: '07:35 AM',
          departureTime: '07:37 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S5',
          name: 'Victoria Square',
          order: 5,
          arrivalTime: '07:45 AM',
          departureTime: '07:47 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S6',
          name: 'Vodafone El Zahraa',
          order: 6,
          arrivalTime: '07:55 AM',
          departureTime: '07:57 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S7',
          name: 'Hub 50 Mall',
          order: 7,
          arrivalTime: '08:02 AM',
          departureTime: '08:04 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S8',
          name: 'IMS School',
          order: 8,
          arrivalTime: '08:07 AM',
          departureTime: '08:09 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S9',
          name: 'Becho American City',
          order: 9,
          arrivalTime: '08:12 AM',
          departureTime: '08:14 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R2-S10',
          name: 'EUI Campus',
          order: 10,
          arrivalTime: '08:45 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R3',
      name: 'Downtown Direct',
      pickup: 'Downtown',
      drop: 'EUI Campus',
      startTime: '08:00 AM',
      endTime: '09:15 AM',
      iconColor: 'FDE8E8',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R3-S1',
          name: 'Tahrir Square',
          order: 1,
          departureTime: '08:00 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R3-S2',
          name: 'Ramses Station',
          order: 2,
          arrivalTime: '08:20 AM',
          departureTime: '08:22 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R3-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '09:15 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R11',
      name: 'Sheikh Zayed Line',
      pickup: 'Sheikh Zayed',
      drop: 'EUI Campus',
      startTime: '06:15 AM',
      endTime: '07:45 AM',
      iconColor: 'EDE7F6',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R11-S1',
          name: 'Hyper One',
          order: 1,
          departureTime: '06:15 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R11-S2',
          name: 'Zayed 2000',
          order: 2,
          arrivalTime: '06:35 AM',
          departureTime: '06:37 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R11-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '07:45 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R12',
      name: 'El Obour Route',
      pickup: 'El Obour',
      drop: 'EUI Campus',
      startTime: '06:45 AM',
      endTime: '08:15 AM',
      iconColor: 'FFF3CD',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R12-S1',
          name: 'Obour Mall',
          order: 1,
          departureTime: '06:45 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R12-S2',
          name: 'Golf City',
          order: 2,
          arrivalTime: '07:05 AM',
          departureTime: '07:07 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R12-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:15 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R13',
      name: 'Mokattam Direct',
      pickup: 'Mokattam',
      drop: 'EUI Campus',
      startTime: '07:30 AM',
      endTime: '08:45 AM',
      iconColor: 'BDDDE4',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R13-S1',
          name: 'Street 9',
          order: 1,
          departureTime: '07:30 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R13-S2',
          name: 'Fountain Square',
          order: 2,
          arrivalTime: '07:50 AM',
          departureTime: '07:52 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R13-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:45 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R14',
      name: 'Ain Shams Line',
      pickup: 'Ain Shams',
      drop: 'EUI Campus',
      startTime: '07:15 AM',
      endTime: '08:30 AM',
      iconColor: 'FFCDB2',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R14-S1',
          name: 'University Bridge',
          order: 1,
          departureTime: '07:15 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R14-S2',
          name: 'El-Gaish Square',
          order: 2,
          arrivalTime: '07:35 AM',
          departureTime: '07:37 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R14-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:30 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R15',
      name: 'Shubra Express',
      pickup: 'Shubra',
      drop: 'EUI Campus',
      startTime: '06:30 AM',
      endTime: '08:00 AM',
      iconColor: 'F7CFD8',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R15-S1',
          name: 'Rod El-Farag',
          order: 1,
          departureTime: '06:30 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R15-S2',
          name: 'Ahmed Helmy',
          order: 2,
          arrivalTime: '06:50 AM',
          departureTime: '06:52 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R15-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:00 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R16',
      name: 'Hadayek Route',
      pickup: 'Hadayek El-Kobba',
      drop: 'EUI Campus',
      startTime: '07:45 AM',
      endTime: '09:00 AM',
      iconColor: 'E4B1F0',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R16-S1',
          name: 'Kobba Bridge',
          order: 1,
          departureTime: '07:45 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R16-S2',
          name: 'Serag Mall',
          order: 2,
          arrivalTime: '08:05 AM',
          departureTime: '08:07 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R16-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '09:00 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R17',
      name: 'Tagamoa Line',
      pickup: 'Fifth Settlement',
      drop: 'EUI Campus',
      startTime: '07:00 AM',
      endTime: '08:15 AM',
      iconColor: 'E9EFFC',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R17-S1',
          name: 'Medical Center',
          order: 1,
          departureTime: '07:00 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R17-S2',
          name: 'Downtown Mall',
          order: 2,
          arrivalTime: '07:20 AM',
          departureTime: '07:22 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R17-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:15 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R4',
      name: 'Nasr City Line',
      pickup: 'Nasr City',
      drop: 'EUI Campus',
      startTime: '06:45 AM',
      endTime: '08:15 AM',
      iconColor: 'FFF085',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R4-S1',
          name: 'City Stars',
          order: 1,
          departureTime: '06:45 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R4-S2',
          name: 'Abbas El-Akkad',
          order: 2,
          arrivalTime: '07:00 AM',
          departureTime: '07:02 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R4-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:15 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R5',
      name: 'October Express',
      pickup: '6th October',
      drop: 'EUI Campus',
      startTime: '06:30 AM',
      endTime: '08:00 AM',
      iconColor: 'E9DFC3',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R5-S1',
          name: 'Mall of Arabia',
          order: 1,
          departureTime: '06:30 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R5-S2',
          name: 'Central Axis',
          order: 2,
          arrivalTime: '06:50 AM',
          departureTime: '06:52 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R5-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:00 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R6',
      name: 'Giza Connector',
      pickup: 'Mohandessin',
      drop: 'EUI Campus',
      startTime: '07:15 AM',
      endTime: '08:45 AM',
      iconColor: 'EABDE6',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R6-S1',
          name: 'Lebanon Square',
          order: 1,
          departureTime: '07:15 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R6-S2',
          name: 'Kit Kat',
          order: 2,
          arrivalTime: '07:35 AM',
          departureTime: '07:37 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R6-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:45 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R7',
      name: 'Zamalek Route',
      pickup: 'Zamalek',
      drop: 'EUI Campus',
      startTime: '07:45 AM',
      endTime: '09:00 AM',
      iconColor: 'FFD7C4',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R7-S1',
          name: '26th July Corridor',
          order: 1,
          departureTime: '07:45 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R7-S2',
          name: 'Opera Square',
          order: 2,
          arrivalTime: '08:00 AM',
          departureTime: '08:02 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R7-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '09:00 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R8',
      name: 'New Cairo Express',
      pickup: 'New Cairo',
      drop: 'EUI Campus',
      startTime: '07:00 AM',
      endTime: '08:15 AM',
      iconColor: 'EAD196',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R8-S1',
          name: 'Point 90 Mall',
          order: 1,
          departureTime: '07:00 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R8-S2',
          name: 'AUC Gate 4',
          order: 2,
          arrivalTime: '07:20 AM',
          departureTime: '07:22 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R8-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:15 AM',
        ),
      ],
      isFavorite: false,
    ),
    bus_route_model.BusRoute(
      id: 'R9',
      name: 'Shorouk Shuttle',
      pickup: 'Shorouk City',
      drop: 'EUI Campus',
      startTime: '06:30 AM',
      endTime: '08:00 AM',
      iconColor: 'DDEB9D',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R9-S1',
          name: 'Shorouk Club',
          order: 1,
          departureTime: '06:30 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R9-S2',
          name: 'Youth City',
          order: 2,
          arrivalTime: '06:50 AM',
          departureTime: '06:52 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R9-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:00 AM',
        ),
      ],
      isFavorite: true,
    ),
    bus_route_model.BusRoute(
      id: 'R10',
      name: 'Rehab Link',
      pickup: 'Rehab City',
      drop: 'EUI Campus',
      startTime: '07:15 AM',
      endTime: '08:30 AM',
      iconColor: 'fbc8b0',
      stops: [
        const bus_stop_model.BusStop(
          id: 'R10-S1',
          name: 'Rehab Mall 1',
          order: 1,
          departureTime: '07:15 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R10-S2',
          name: 'Rehab Mall 2',
          order: 2,
          arrivalTime: '07:25 AM',
          departureTime: '07:27 AM',
        ),
        const bus_stop_model.BusStop(
          id: 'R10-S3',
          name: 'EUI Campus',
          order: 3,
          arrivalTime: '08:30 AM',
        ),
      ],
      isFavorite: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index == 0 ? 'all' : 'favorites';
      });
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Filter Routes',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.lightTheme.textTheme.displayLarge!.color,
                  fontSize: ru.getProportionateScreenWidth(18),
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All Routes', 'all'),
              _buildFilterOption('Morning Routes', 'morning'),
              _buildFilterOption('Afternoon Routes', 'afternoon'),
              _buildFilterOption('Evening Routes', 'evening'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(33),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, String value) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: sz.getProportionateScreenHeight(12),
          horizontal: ru.getProportionateScreenWidth(16),
        ),
        decoration: BoxDecoration(
          color: _selectedFilter == value
              ? AppTheme.lightTheme.colorScheme.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(33),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _selectedFilter == value
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.textTheme.bodyLarge!.color,
                  ),
            ),
            if (_selectedFilter == value)
              Icon(
                Icons.check,
                color: AppTheme.lightTheme.primaryColor,
                size: ru.getProportionateScreenWidth(20),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(String routeId) {
    setState(() {
      final routeIndex = routes.indexWhere((r) => r.id == routeId);
      if (routeIndex != -1) {
        final currentRoute = routes[routeIndex];
        final newRoute = bus_route_model.BusRoute(
          id: currentRoute.id,
          name: currentRoute.name,
          pickup: currentRoute.pickup,
          drop: currentRoute.drop,
          startTime: currentRoute.startTime,
          endTime: currentRoute.endTime,
          iconColor: currentRoute.iconColor,
          stops: currentRoute.stops,
          isFavorite: !currentRoute.isFavorite,
        );

        routes[routeIndex] = newRoute;
      }
    });
  }

  void _updateRouteColor(String routeId, String newColor) {
    setState(() {
      final routeIndex = routes.indexWhere((r) => r.id == routeId);
      if (routeIndex != -1) {
        final currentRoute = routes[routeIndex];
        routes[routeIndex] = bus_route_model.BusRoute(
          id: currentRoute.id,
          name: currentRoute.name,
          pickup: currentRoute.pickup,
          drop: currentRoute.drop,
          startTime: currentRoute.startTime,
          endTime: currentRoute.endTime,
          iconColor: newColor,
          stops: currentRoute.stops,
          isFavorite: currentRoute.isFavorite,
        );
      }
    });
  }

  List<bus_route_model.BusRoute> _getFilteredRoutes() {
    var filteredRoutes = routes;

    // Filter by favorites if in favorites tab
    if (_tabController.index == 1) {
      filteredRoutes =
          filteredRoutes.where((route) => route.isFavorite).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filteredRoutes = filteredRoutes
          .where((route) =>
              route.name.toLowerCase().contains(searchLower) ||
              route.pickup.toLowerCase().contains(searchLower) ||
              route.drop.toLowerCase().contains(searchLower))
          .toList();
    }

    // Apply time filter
    if (_selectedFilter != 'all') {
      filteredRoutes = filteredRoutes.where((route) {
        // List of routes that should appear in afternoon filter
        final afternoonRoutes = [
          'Mokattam Direct',
          'Sheikh Zayed Line',
          'Tagamoa Line',
          'Giza Connector'
        ];

        if (_selectedFilter == 'morning') {
          return !afternoonRoutes.contains(route.name);
        } else if (_selectedFilter == 'afternoon') {
          return afternoonRoutes.contains(route.name);
        } else if (_selectedFilter == 'evening') {
          return true;
        }
        return false;
      }).toList();

      // Modify routes for afternoon schedule
      if (_selectedFilter == 'afternoon') {
        filteredRoutes = filteredRoutes.map((route) {
          return bus_route_model.BusRoute(
            id: route.id,
            name: route.name,
            pickup: 'EUI Campus',
            drop: route.pickup,
            startTime: '12:00 PM',
            endTime: '1:00 PM',
            iconColor: route.iconColor,
            stops: [
              bus_stop_model.BusStop(
                  id: 'R1-S1',
                  name: 'EUI Campus',
                  order: 1,
                  departureTime: '12:00 PM'),
              bus_stop_model.BusStop(
                id: 'R1-S2',
                name: route.stops[1].name,
                order: 2,
                arrivalTime: '12:30 PM',
                departureTime: '12:32 PM',
              ),
              bus_stop_model.BusStop(
                id: 'R1-S3',
                name: route.pickup,
                order: 3,
                arrivalTime: '1:00 PM',
              ),
            ],
            isFavorite: route.isFavorite,
          );
        }).toList();
      }

      // Modify routes for evening schedule
      if (_selectedFilter == 'evening') {
        filteredRoutes = filteredRoutes.map((route) {
          return bus_route_model.BusRoute(
            id: route.id,
            name: route.name,
            pickup: 'EUI Campus',
            drop: route.pickup,
            startTime: '04:00 PM',
            endTime: '06:00 PM',
            iconColor: route.iconColor,
            stops: [
              bus_stop_model.BusStop(
                  id: 'R2-S1',
                  name: 'EUI Campus',
                  order: 1,
                  departureTime: '04:00 PM'),
              bus_stop_model.BusStop(
                id: 'R2-S2',
                name: route.stops[1].name,
                order: 2,
                arrivalTime: '05:00 PM',
                departureTime: '05:02 PM',
              ),
              bus_stop_model.BusStop(
                id: 'R2-S3',
                name: route.pickup,
                order: 3,
                arrivalTime: '06:00 PM',
              ),
            ],
            isFavorite: route.isFavorite,
          );
        }).toList();
      }
    }

    return filteredRoutes;
  }

  @override
  Widget build(BuildContext context) {
    sz.SizeConfig.init(context);
    final filteredRoutes = _getFilteredRoutes();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.primaryColor,
        titleSpacing: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: _isSearchVisible
            ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ru.getProportionateScreenWidth(16),
                  vertical: sz.getProportionateScreenHeight(8),
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(33),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme
                              .lightTheme.textTheme.headlineLarge!.color,
                          fontSize: ru.getProportionateScreenWidth(16),
                        ),
                    decoration: InputDecoration(
                      hintText: 'Search routes...',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                AppTheme.lightTheme.textTheme.bodySmall!.color,
                          ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ru.getProportionateScreenWidth(12),
                        ),
                        child: Icon(
                          Icons.search,
                          color: AppTheme.lightTheme.textTheme.bodySmall!.color,
                          size: 20,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    autofocus: true,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Bus Schedules',
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        fontSize: ru.getProportionateScreenWidth(20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSearchVisible ? Icons.close : Icons.search,
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchController.clear();
                              _searchQuery = '';
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.filter_alt_outlined,
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                        onPressed: _showFilterDialog,
                      ),
                    ],
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ru.getProportionateScreenWidth(16),
              vertical: sz.getProportionateScreenHeight(16),
            ),
            child: ToggleButtonPair(
              firstText: 'All Routes',
              firstIcon: Icons.format_list_bulleted_outlined,
              secondText: 'Favorites',
              secondIcon: Icons.star_outline,
              isFirstSelected: _tabController.index == 0,
              onToggle: (isFirst) {
                setState(() {
                  _tabController.animateTo(isFirst ? 0 : 1);
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: filteredRoutes
                  .map((route) => _buildRouteCard(route))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(bus_route_model.BusRoute route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(33),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: Color(0xFF1D1691),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BA123',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: () => _toggleFavorite(route.id),
                  child: Icon(
                    route.isFavorite ? Icons.star : Icons.star_border,
                    color: route.isFavorite
                        ? Color(0xFFFFD700)
                        : Color(0xFFD1D5DB),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    route.startTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                      letterSpacing: 0.3,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: Color(0xFFE5E7EB),
                  ),
                  Text(
                    route.endTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.pickup,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drop:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.drop,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailsScreen(
                      route: route,
                      onFavoriteToggle: _toggleFavorite,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1D1691),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(
                Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'View Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
