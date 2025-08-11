import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/models/bus_route.dart' as bus_route_model;
import 'package:unitracker/models/bus_stop.dart' as bus_stop_model;
import 'package:unitracker/screens/schedules/route_details_screen.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/utils/size_config.dart' as sz;
import 'package:unitracker/widgets/toggle_button.dart';
import 'package:unitracker/widgets/modern_widgets.dart';
import '../../utils/responsive_utils.dart' as ru;
import '../../providers/route_provider.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  String _selectedRouteType = 'To University';

  final List<Color> _cardColors = [
    const Color(0xFFE9EFFC), // Light Blue
    const Color(0xFFE1F6EF), // Light Teal
    const Color(0xFFFFF3CD), // Light Yellow
    const Color(0xFFFDE8E8), // Light Red
    const Color(0xFFEDE7F6), // Light Purple
  ];

  List<bus_route_model.BusRoute> routes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index == 0 ? 'all' : 'favorites';
      });
    });

    // Load routes from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteProvider>().loadRoutes();
    });
  }

  void _toggleFavorite(String routeId) {
    final routeProvider = context.read<RouteProvider>();
    routeProvider.toggleFavorite(routeId);
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

  @override
  Widget build(BuildContext context) {
    sz.SizeConfig.init(context);

    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        if (routeProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'Schedules',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (routeProvider.error != null) {
          return Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'Schedules',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${routeProvider.error}'),
                  ElevatedButton(
                    onPressed: () => routeProvider.loadRoutes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredRoutes =
            _getFilteredRoutesFromProvider(routeProvider.routes);

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
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.lightTheme.textTheme
                                      .headlineLarge!.color,
                                  fontSize: ru.getProportionateScreenWidth(16),
                                ),
                        decoration: InputDecoration(
                          hintText: 'Search routes...',
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodySmall!.color,
                                  ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: ru.getProportionateScreenWidth(12),
                            ),
                            child: Icon(
                              Icons.search,
                              color: AppTheme
                                  .lightTheme.textTheme.bodySmall!.color,
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
                child: filteredRoutes.isEmpty
                    ? Center(
                        child: Text(
                          'No bus routes are available at the moment.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: filteredRoutes
                            .asMap()
                            .entries
                            .map((entry) => AnimatedSlideIn(
                                  index: entry.key,
                                  child: _buildRouteCard(entry.value),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(bus_route_model.BusRoute route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 33,
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
            ModernButton(
              text: 'View Schedule',
              icon: Icons.schedule,
              width: double.infinity,
              borderRadius: 33,
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
            ),
          ],
        ),
      ),
    );
  }

  List<bus_route_model.BusRoute> _getFilteredRoutesFromProvider(
      List<bus_route_model.BusRoute> routes) {
    List<bus_route_model.BusRoute> filteredRoutes = List.from(routes);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredRoutes = filteredRoutes.where((route) {
        return route.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            route.pickup.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            route.drop.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply favorites filter
    if (_selectedTab == 'favorites') {
      filteredRoutes =
          filteredRoutes.where((route) => route.isFavorite).toList();
    }

    return filteredRoutes;
  }
}

class RouteCard extends StatelessWidget {
  const RouteCard({
    Key? key,
    required this.route,
    required this.onFavoriteToggle,
    required this.color,
  }) : super(key: key);

  final bus_route_model.BusRoute route;
  final Function(String) onFavoriteToggle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 33,
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
                        color: color,
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
                    onTap: () => onFavoriteToggle(route.id),
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
            ModernButton(
              text: 'View Schedule',
              icon: Icons.schedule,
              width: double.infinity,
              borderRadius: 33,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailsScreen(
                      route: route,
                      onFavoriteToggle: onFavoriteToggle,
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
