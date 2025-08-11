import 'package:flutter/material.dart';
import 'package:unitracker/models/bus_route.dart';
import 'package:unitracker/models/bus_stop.dart';
import 'package:unitracker/services/supabase_service.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/utils/responsive_utils.dart';

class RouteDetailsScreen extends StatefulWidget {
  final BusRoute route;
  final Function(String) onFavoriteToggle;

  const RouteDetailsScreen({
    super.key,
    required this.route,
    required this.onFavoriteToggle,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late BusRoute _route;
  final ScrollController _scrollController = ScrollController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  List<BusStop> _stops = [];

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    _loadStops();
  }

  Future<void> _loadStops() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Query bus_stops table for this route with proper ascending order
      final response = await _supabaseService.client
          .from('bus_stops')
          .select(
              'id, name, stop_order, estimated_arrival_time, is_pickup_point, is_drop_point')
          .eq('route_id', _route.id)
          .order('stop_order', ascending: true);

      final stopsData = response as List<dynamic>? ?? [];

      final stops = <BusStop>[];

      debugPrint('🚏 Loading stops for route: ${_route.name}');
      debugPrint('🚏 Found ${stopsData.length} stops in database');

      // Add all stops from database (including main pickup and drop points)
      for (int i = 0; i < stopsData.length; i++) {
        final stopData = stopsData[i];
        final arrivalTime = stopData['estimated_arrival_time'] as String?;
        final stopOrder = stopData['stop_order'] as int;
        final stopName = stopData['name'] as String;

        debugPrint(
            '🚏 Stop ${i + 1}: $stopName (Order: $stopOrder, Time: $arrivalTime)');

        // Format time from HH:MM:SS to HH:MM AM/PM
        String? formattedArrivalTime;
        String? formattedDepartureTime;

        if (arrivalTime != null) {
          formattedArrivalTime = _formatTime(arrivalTime);
          // For departure, add 2 minutes to arrival time (except for last stop)
          if (i < stopsData.length - 1) {
            formattedDepartureTime = _addMinutesToTime(arrivalTime, 2);
          } else {
            formattedDepartureTime = '-'; // No departure from final destination
          }
        }

        stops.add(BusStop(
          id: stopData['id'] as String,
          name: stopName,
          order: stopOrder,
          arrivalTime: formattedArrivalTime,
          departureTime: formattedDepartureTime,
        ));
      }

      // Sort stops by order to ensure correct sequence
      stops.sort((a, b) => a.order.compareTo(b.order));

      debugPrint('🚏 Final stops order:');
      for (int i = 0; i < stops.length; i++) {
        debugPrint(
            '  ${i + 1}. ${stops[i].name} (Order: ${stops[i].order}, Arrival: ${stops[i].arrivalTime})');
      }

      setState(() {
        _stops = stops;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading stops: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(String timeString) {
    // Handle different time formats
    String cleanTime = timeString;

    // If it already contains AM/PM, return as is
    if (timeString.toLowerCase().contains('am') ||
        timeString.toLowerCase().contains('pm')) {
      return timeString;
    }

    // If it's in HH:MM:SS format, extract HH:MM
    if (timeString.contains(':')) {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = parts[1];

        if (hour == 0) {
          return '12:$minute AM';
        } else if (hour < 12) {
          return '$hour:$minute AM';
        } else if (hour == 12) {
          return '12:$minute PM';
        } else {
          return '${hour - 12}:$minute PM';
        }
      }
    }

    // Fallback
    return timeString;
  }

  String _addMinutesToTime(String timeString, int minutesToAdd) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final totalMinutes = hour * 60 + minute + minutesToAdd;
    final newHour = (totalMinutes ~/ 60) % 24;
    final newMinute = totalMinutes % 60;

    return _formatTime(
        '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}:00');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFavoriteToggle() {
    setState(() {
      _route = BusRoute(
        id: _route.id,
        name: _route.name,
        pickup: _route.pickup,
        drop: _route.drop,
        startTime: _route.startTime,
        endTime: _route.endTime,
        iconColor: _route.iconColor,
        stops: _route.stops,
        isFavorite: !_route.isFavorite,
      );
    });
    widget.onFavoriteToggle(_route.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: getProportionateScreenWidth(4)),
          child: const BackButton(color: Colors.black),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: getProportionateScreenWidth(4)),
          child: Text(
            'Bus Schedules',
            style: TextStyle(
              color: Colors.black,
              fontSize: getProportionateScreenWidth(18),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _route.isFavorite ? Icons.star : Icons.star_border,
              color: _route.isFavorite
                  ? Theme.of(context).colorScheme.tertiary
                  : Colors.grey[400],
              size: 24,
            ),
            onPressed: _handleFavoriteToggle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                getProportionateScreenWidth(16),
                getProportionateScreenHeight(16),
                getProportionateScreenWidth(16),
                getProportionateScreenHeight(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(8)),
                    decoration: const BoxDecoration(
                      color: Color(0x1A1D1691),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: const Color(0xFF1D1691),
                      size: getProportionateScreenWidth(24),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _route.name,
                        style: TextStyle(
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(4)),
                      Text(
                        '${_route.pickup} → ${_route.drop}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: getProportionateScreenWidth(14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: getProportionateScreenWidth(12),
                      offset: Offset(0, getProportionateScreenHeight(4)),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(16),
                        vertical: getProportionateScreenHeight(12),
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            getProportionateScreenWidth(12),
                          ),
                          topRight: Radius.circular(
                            getProportionateScreenWidth(12),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Stop',
                              style: TextStyle(
                                color: AppTheme.lightTheme.primaryColor,
                                fontSize: getProportionateScreenWidth(15),
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.left,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: getProportionateScreenWidth(2)),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Arrival',
                              style: TextStyle(
                                color: AppTheme.lightTheme.primaryColor,
                                fontSize: getProportionateScreenWidth(15),
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: getProportionateScreenWidth(4)),
                              child: Text(
                                'Departure',
                                style: TextStyle(
                                  color: AppTheme.lightTheme.primaryColor,
                                  fontSize: getProportionateScreenWidth(15),
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stops List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(
                            getProportionateScreenWidth(12),
                          ),
                          bottomRight: Radius.circular(
                            getProportionateScreenWidth(12),
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? Padding(
                              padding: EdgeInsets.all(
                                  getProportionateScreenWidth(32)),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _stops.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.all(
                                      getProportionateScreenWidth(32)),
                                  child: Center(
                                    child: Text(
                                      'No stops available for this route',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize:
                                            getProportionateScreenWidth(14),
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _stops.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey[200],
                                  ),
                                  itemBuilder: (context, index) {
                                    final stop = _stops[index];

                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            getProportionateScreenWidth(16),
                                        vertical:
                                            getProportionateScreenHeight(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              stop.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                          SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      2)),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  left:
                                                      getProportionateScreenWidth(
                                                          4)),
                                              child: Text(
                                                stop.arrivalTime ?? '-',
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  left:
                                                      getProportionateScreenWidth(
                                                          4)),
                                              child: Text(
                                                stop.departureTime ?? '-',
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
          ],
        ),
      ),
    );
  }
}
