import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/bus_route.dart';
import '../../models/map_location.dart';
import '../../services/map_service.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/destination_service.dart';

class MapScreen extends StatefulWidget {
  final List<BusRoute>? routes;
  final String? selectedRouteId;
  final Function(String?)? onRouteSelect;

  const MapScreen({
    super.key,
    this.routes,
    this.selectedRouteId,
    this.onRouteSelect,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Map<String, StreamSubscription<MapLocation>> _locationSubscriptions =
      {};
  bool _isFollowingBus = false;
  String? _selectedBusId;
  MapType _currentMapType = MapType.normal;
  bool _showBottomSheet = false;
  MapLocation? _selectedBusLocation;
  LatLng? _userLocation;
  bool _locationPermissionChecked = false;
  bool _hasFitToBounds = false;
  bool _hasZoomedToUser = false;
  String? _lastFitRouteId;

  // Egypt University of Informatics (EUI) location
  static const LatLng _universityLocation = LatLng(30.0789, 31.3265);

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocation();
    _updateMapFeatures();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset fit-to-bounds if the selected route actually changes
    if (widget.selectedRouteId != _lastFitRouteId) {
      _hasFitToBounds = false;
      _lastFitRouteId = widget.selectedRouteId;
    }
    if (widget.routes != oldWidget.routes ||
        widget.selectedRouteId != oldWidget.selectedRouteId) {
      _updateMapFeatures();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
      _hasFitToBounds = false;
      _hasZoomedToUser = false;
    });
    _updateMapFeatures();
    // If user location is already available, zoom to it
    if (_userLocation != null && !_hasZoomedToUser) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 17),
      );
      _hasZoomedToUser = true;
    }
  }

  Future<void> _updateMapFeatures() async {
    if (!mounted) return;

    final mapService = context.read<MapService>();
    final routes = widget.routes ?? [];
    final markers = <Marker>{};
    final polylines = <Polyline>{};
    List<MapLocation> allLocations = [];

    // Add university marker only if a route is selected
    if (widget.selectedRouteId != null) {
      try {
        final universityIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(),
          'assets/images/university_marker.png',
        );
        markers.add(
          Marker(
            markerId: const MarkerId('university'),
            position: LatLng(30.02229168783005, 31.708040703086247),
            icon: universityIcon,
            infoWindow: const InfoWindow(
              title: 'Egypt University of Informatics',
              snippet: 'Main Campus',
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error loading university marker: $e');
        // Fallback to default marker
        markers.add(
          Marker(
            markerId: const MarkerId('university'),
            position: LatLng(30.02229168783005, 31.708040703086247),
            infoWindow: const InfoWindow(
              title: 'Egypt University of Informatics',
              snippet: 'Main Campus',
            ),
          ),
        );
      }
    }

    // Only show routes, stops, and buses if a route is selected
    if (widget.selectedRouteId != null) {
      for (final route in routes) {
        if (route.id == widget.selectedRouteId) {
          final locations = mapService.convertRouteToLocations(route);
          allLocations.addAll(locations);
          mapService.updateRouteLocations(route.id, locations);

          // Create route polyline including waypoints
          final routeStops =
              locations.where((loc) => loc.type == 'stop').toList();

          if (routeStops.isNotEmpty) {
            try {
              // Get route points from Directions API
              final routePoints = await mapService.getRoutePoints(
                LatLng(routeStops.first.latitude, routeStops.first.longitude),
                LatLng(routeStops.last.latitude, routeStops.last.longitude),
                routeStops
                    .sublist(1, routeStops.length - 1)
                    .map((stop) => LatLng(stop.latitude, stop.longitude))
                    .toList(),
              );

              polylines.add(
                Polyline(
                  polylineId: PolylineId('route_${route.id}'),
                  points: routePoints,
                  color: Colors.blue.shade600,
                  width: 6,
                  endCap: Cap.roundCap,
                  startCap: Cap.roundCap,
                  geodesic: true,
                  jointType: JointType.round,
                ),
              );
            } catch (e) {
              print('Error getting route points: $e');
              // Fallback to direct lines if API fails
              final directPoints = routeStops
                  .map((loc) => LatLng(loc.latitude, loc.longitude))
                  .toList();

              polylines.add(
                Polyline(
                  polylineId: PolylineId('route_${route.id}'),
                  points: directPoints,
                  color: Colors.blue.shade600,
                  width: 6,
                  endCap: Cap.roundCap,
                  startCap: Cap.roundCap,
                  geodesic: true,
                  jointType: JointType.round,
                ),
              );
            }
          }

          // Add markers for stops
          final stops = locations.where((loc) => loc.type == 'stop');
          for (final stop in stops) {
            try {
              final stopIcon = await BitmapDescriptor.fromAssetImage(
                const ImageConfiguration(),
                'assets/images/stop_marker.png',
              );
              markers.add(
                Marker(
                  markerId: MarkerId('stop_${stop.id}'),
                  position: LatLng(stop.latitude, stop.longitude),
                  icon: stopIcon,
                  infoWindow: InfoWindow(
                    title: stop.name,
                    snippet: _getLocationSnippet(stop),
                  ),
                  onTap: () => _showStopDetails(stop),
                ),
              );
            } catch (e) {
              debugPrint('Error loading stop marker: $e');
              // Fallback to default marker
              markers.add(
                Marker(
                  markerId: MarkerId('stop_${stop.id}'),
                  position: LatLng(stop.latitude, stop.longitude),
                  infoWindow: InfoWindow(
                    title: stop.name,
                    snippet: _getLocationSnippet(stop),
                  ),
                  onTap: () => _showStopDetails(stop),
                ),
              );
            }
          }

          // Add bus markers
          final buses = locations.where((loc) => loc.type == 'bus');
          for (final bus in buses) {
            _setupBusLocationUpdates(mapService, bus.id, markers);
            markers.add(
              Marker(
                markerId: MarkerId('bus_${bus.id}'),
                position: LatLng(bus.latitude, bus.longitude),
                icon: await bitmapDescriptorFromIcon(Icons.directions_bus,
                    color: Colors.red, size: 48),
                infoWindow: InfoWindow(
                  title: bus.name,
                  snippet: _getLocationSnippet(bus),
                ),
                onTap: () => _onBusMarkerTap(bus),
              ),
            );
          }
        }
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // If a route is selected, fit bounds (only once per route selection)
    if (_isMapReady &&
        widget.selectedRouteId != null &&
        _mapController != null &&
        !_hasFitToBounds) {
      final bounds = _calculateRouteBounds(allLocations);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
      _hasFitToBounds = true;
      _lastFitRouteId = widget.selectedRouteId;
    }
  }

  void _setupBusLocationUpdates(
    MapService mapService,
    String busId,
    Set<Marker> markers,
  ) {
    _locationSubscriptions[busId] =
        mapService.getBusLocationStream(busId).listen((location) {
      if (!mounted) return;
      _updateBusMarker(location);
    });
  }

  Future<void> _updateBusMarker(MapLocation location) async {
    final marker = Marker(
      markerId: MarkerId('bus_${location.id}'),
      position: LatLng(location.latitude, location.longitude),
      icon: await bitmapDescriptorFromIcon(Icons.directions_bus,
          color: Colors.red, size: 48),
      infoWindow: InfoWindow(
        title: 'Bus ${location.id}',
        snippet: _getLocationSnippet(location),
      ),
      onTap: () => _onBusMarkerTap(location),
    );

    setState(() {
      _markers = Set.from(_markers)
        ..removeWhere((m) => m.markerId == MarkerId('bus_${location.id}'))
        ..add(marker);

      // Update selected bus location if this is the one being followed
      if (_selectedBusId == location.id) {
        _selectedBusLocation = location;
      }
    });

    // If following this bus, update camera position
    if (_isFollowingBus && _selectedBusId == location.id) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(location.latitude, location.longitude),
        ),
      );
    }
  }

  void _onBusMarkerTap(MapLocation location) {
    setState(() {
      _selectedBusId = location.id;
      _selectedBusLocation = location;
      _isFollowingBus = true;
      _showBottomSheet = true;
    });
  }

  void _showStopDetails(MapLocation location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StopDetailsSheet(location: location),
    );
  }

  String _getLocationSnippet(MapLocation location) {
    if (location.type == 'bus') {
      final speed = location.additionalInfo?['speed']?.toString() ?? 'N/A';
      final eta = location.additionalInfo?['eta'] ?? 'Calculating...';
      return 'Speed: $speed km/h\nETA: $eta';
    } else {
      final nextBus =
          location.additionalInfo?['nextBusArrival'] ?? 'No bus scheduled';
      return 'Next bus: $nextBus';
    }
  }

  LatLngBounds _calculateRouteBounds(List<MapLocation> locations) {
    if (locations.isEmpty) {
      // Default to EUI campus area if no locations
      return LatLngBounds(
        southwest: const LatLng(29.95, 31.23),
        northeast: const LatLng(30.03, 31.71),
      );
    }

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  Future<void> _checkAndRequestLocation() async {
    final locationService = context.read<LocationService>();
    final hasPermission = await locationService.initialize();
    if (hasPermission && locationService.currentLocation != null) {
      setState(() {
        _userLocation = LatLng(
          locationService.currentLocation!.latitude!,
          locationService.currentLocation!.longitude!,
        );
        _locationPermissionChecked = true;
      });
      // Zoom to user location only once
      if (_mapController != null && !_hasZoomedToUser) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation!, 17),
        );
        _hasZoomedToUser = true;
      }
    } else {
      setState(() {
        _locationPermissionChecked = true;
      });
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission is required to show your current location.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Wrap GoogleMap in error handling
        _buildMapWidget(),
        if (!_locationPermissionChecked)
          const Center(child: CircularProgressIndicator()),

        // Search bar
        Positioned(
          top: 16,
          left: 16,
          right: 72,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.selectedRouteId,
                  hint: const Text('Select a route'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Select Route'),
                    ),
                    ...widget.routes?.map((route) => DropdownMenuItem<String>(
                              value: route.id,
                              child: Text(route.name),
                            )) ??
                        [],
                  ],
                  onChanged: (value) {
                    if (widget.onRouteSelect != null) {
                      widget.onRouteSelect!(value);
                    }
                  },
                ),
              ),
            ),
          ),
        ),

        // Destination info card
        if (widget.selectedRouteId != null) _buildDestinationInfo(),

        // Map controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              if (_isFollowingBus && _selectedBusId != null)
                _MapControlButton(
                  icon: Icons.directions_bus,
                  onPressed: () {
                    setState(() {
                      _isFollowingBus = false;
                      _selectedBusId = null;
                      _showBottomSheet = false;
                    });
                  },
                  tooltip: 'Stop following bus',
                ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.my_location,
                onPressed: () {
                  if (_userLocation != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(_userLocation!, 17),
                    );
                  } else if (_mapController != null) {
                    // fallback: zoom to university location
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(_universityLocation, 15),
                    );
                  }
                },
                tooltip: 'My location',
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.layers,
                onPressed: () {
                  setState(() {
                    _currentMapType = _currentMapType == MapType.normal
                        ? MapType.satellite
                        : MapType.normal;
                  });
                },
                tooltip: 'Change map type',
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.add,
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.zoomIn(),
                  );
                },
                tooltip: 'Zoom in',
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.remove,
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.zoomOut(),
                  );
                },
                tooltip: 'Zoom out',
              ),
            ],
          ),
        ),

        // Bus details bottom sheet
        if (_showBottomSheet && _selectedBusLocation != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BusDetailsSheet(
              location: _selectedBusLocation!,
              onClose: () {
                setState(() {
                  _showBottomSheet = false;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMapWidget() {
    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _userLocation ?? const LatLng(29.990, 31.471),
          zoom: 15,
        ),
        markers: {
          ..._markers,
        },
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: _currentMapType,
        zoomControlsEnabled: false,
        compassEnabled: true,
        onTap: (_) {
          setState(() {
            _isFollowingBus = false;
            _showBottomSheet = false;
          });
        },
      );
    } catch (e) {
      debugPrint('Error creating Google Map: $e');
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Map Loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we initialize the map',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Trigger rebuild
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDestinationInfo() {
    final selectedRoute = widget.routes?.firstWhere(
      (route) => route.id == widget.selectedRouteId,
      orElse: () => widget.routes!.first,
    );

    if (selectedRoute == null) return const SizedBox.shrink();

    final destinationService = DestinationService();
    final destination = destinationService.analyzeRouteDestination(selectedRoute.name);

    if (destination == null) return const SizedBox.shrink();

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          destination.fullName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      destination.area,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                destination.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
              if (destination.landmarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: destination.landmarks.take(3).map((landmark) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        landmark,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _createFallbackMarker(IconData icon, Color color) async {
    try {
      return await bitmapDescriptorFromIcon(icon, color: color, size: 48);
    } catch (e) {
      debugPrint('Error creating fallback marker: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  void dispose() {
    for (var subscription in _locationSubscriptions.values) {
      subscription.cancel();
    }
    _mapController?.dispose();
    super.dispose();
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class RouteSelector extends StatelessWidget {
  final List<BusRoute> routes;
  final String? selectedRouteId;
  final Function(String)? onRouteSelect;

  const RouteSelector({
    super.key,
    required this.routes,
    this.selectedRouteId,
    this.onRouteSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedRouteId,
            hint: const Text('Select a route'),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Select Route'),
              ),
              ...routes.map((route) => DropdownMenuItem<String>(
                    value: route.id,
                    child: Text(route.name),
                  )),
            ],
            onChanged: (value) {
              if (onRouteSelect != null) {
                onRouteSelect!(value ?? '');
              }
            },
          ),
        ),
      ),
    );
  }
}

class BusDetailsSheet extends StatelessWidget {
  final MapLocation location;
  final VoidCallback onClose;

  const BusDetailsSheet({
    super.key,
    required this.location,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final speed = location.additionalInfo?['speed']?.toString() ?? 'N/A';
    final status = location.additionalInfo?['status'] ?? 'Unknown';
    final eta = location.additionalInfo?['eta'] ?? 'Calculating...';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Bus ${location.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.speed,
                  label: 'Speed',
                  value: '$speed km/h',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: status,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: eta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StopDetailsSheet extends StatelessWidget {
  final MapLocation location;

  const StopDetailsSheet({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final nextBusId = location.additionalInfo?['nextBusId'];
    final nextBusArrival = location.additionalInfo?['nextBusArrival'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              location.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (nextBusId != null) ...[
                  _InfoRow(
                    icon: Icons.directions_bus,
                    label: 'Next Bus',
                    value: 'Bus $nextBusId',
                  ),
                  const SizedBox(height: 8),
                ],
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Arrival',
                  value: nextBusArrival ?? 'No scheduled arrivals',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

Future<BitmapDescriptor> bitmapDescriptorFromIcon(IconData iconData,
    {Color color = Colors.red, double size = 48}) async {
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  final iconStr = String.fromCharCode(iconData.codePoint);
  textPainter.text = TextSpan(
    text: iconStr,
    style: TextStyle(
      fontSize: size,
      fontFamily: 'MaterialIcons',
      color: color,
    ),
  );
  textPainter.layout();
  textPainter.paint(canvas, Offset.zero);
  final image =
      await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}
