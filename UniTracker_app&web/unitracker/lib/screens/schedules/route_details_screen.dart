import 'package:flutter/material.dart';
import 'package:unitracker/models/bus_route.dart';
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

  @override
  void initState() {
    super.initState();
    _route = widget.route;
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _route.stops.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final stop = _route.stops[index];
                          final isFirstStop = index == 0;
                          final isLastStop = index == _route.stops.length - 1;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(16),
                              vertical: getProportionateScreenHeight(12),
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
                                SizedBox(width: getProportionateScreenWidth(2)),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: getProportionateScreenWidth(4)),
                                    child: Text(
                                      isFirstStop
                                          ? '-'
                                          : (stop.arrivalTime ?? '-'),
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
                                        left: getProportionateScreenWidth(4)),
                                    child: Text(
                                      isLastStop
                                          ? '-'
                                          : (stop.departureTime ?? '-'),
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
