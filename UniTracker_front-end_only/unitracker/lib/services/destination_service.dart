import 'package:flutter/foundation.dart';

class DestinationService {
  static final DestinationService _instance = DestinationService._internal();
  factory DestinationService() => _instance;
  DestinationService._internal();

  // Egypt destinations mapping based on route names
  static const Map<String, DestinationInfo> _egyptDestinations = {
    // Cairo Areas
    'maadi': DestinationInfo(
      name: 'Maadi',
      fullName: 'Maadi, Cairo',
      description: 'Upscale residential district in southern Cairo',
      coordinates: LatLngInfo(29.9602, 31.2569),
      landmarks: ['Maadi Metro Station', 'Maadi Corniche', 'Maadi Grand Mall'],
      area: 'Cairo',
    ),
    'nasr city': DestinationInfo(
      name: 'Nasr City',
      fullName: 'Nasr City, Cairo',
      description: 'Modern district in eastern Cairo',
      coordinates: LatLngInfo(30.0626, 31.3219),
      landmarks: ['City Stars Mall', 'Cairo International Stadium', 'Nasr City Metro'],
      area: 'Cairo',
    ),
    'heliopolis': DestinationInfo(
      name: 'Heliopolis',
      fullName: 'Heliopolis, Cairo',
      description: 'Historic upscale district in northeastern Cairo',
      coordinates: LatLngInfo(30.0808, 31.3219),
      landmarks: ['Baron Palace', 'Heliopolis Club', 'Cairo International Airport'],
      area: 'Cairo',
    ),
    'new cairo': DestinationInfo(
      name: 'New Cairo',
      fullName: 'New Cairo, Cairo',
      description: 'Modern satellite city east of Cairo',
      coordinates: LatLngInfo(30.0254, 31.4913),
      landmarks: ['AUC New Campus', 'Cairo Festival City', 'Point 90 Mall'],
      area: 'Cairo',
    ),
    'zamalek': DestinationInfo(
      name: 'Zamalek',
      fullName: 'Zamalek, Cairo',
      description: 'Affluent district on Gezira Island',
      coordinates: LatLngInfo(30.0626, 31.2156),
      landmarks: ['Cairo Opera House', 'Gezira Club', 'Zamalek Art Gallery'],
      area: 'Cairo',
    ),
    'downtown': DestinationInfo(
      name: 'Downtown Cairo',
      fullName: 'Downtown Cairo, Cairo',
      description: 'Historic commercial center of Cairo',
      coordinates: LatLngInfo(30.0444, 31.2357),
      landmarks: ['Tahrir Square', 'Egyptian Museum', 'Khedival Opera House'],
      area: 'Cairo',
    ),
    'dokki': DestinationInfo(
      name: 'Dokki',
      fullName: 'Dokki, Giza',
      description: 'Residential and commercial district in Giza',
      coordinates: LatLngInfo(30.0388, 31.2125),
      landmarks: ['Dokki Metro Station', 'Shooting Club', 'Cairo University'],
      area: 'Giza',
    ),
    'mohandessin': DestinationInfo(
      name: 'Mohandessin',
      fullName: 'Mohandessin, Giza',
      description: 'Upscale residential area in Giza',
      coordinates: LatLngInfo(30.0626, 31.2000),
      landmarks: ['Arab League Street', 'Mohandessin Metro', 'Gezira Sporting Club'],
      area: 'Giza',
    ),
    'giza': DestinationInfo(
      name: 'Giza',
      fullName: 'Giza, Giza Governorate',
      description: 'Historic city famous for the pyramids',
      coordinates: LatLngInfo(30.0131, 31.2089),
      landmarks: ['Great Pyramid', 'Sphinx', 'Giza Plateau'],
      area: 'Giza',
    ),
    
    // Alexandria
    'alexandria': DestinationInfo(
      name: 'Alexandria',
      fullName: 'Alexandria, Alexandria Governorate',
      description: 'Historic Mediterranean coastal city',
      coordinates: LatLngInfo(31.2001, 29.9187),
      landmarks: ['Bibliotheca Alexandrina', 'Citadel of Qaitbay', 'Corniche'],
      area: 'Alexandria',
    ),
    
    // Other Major Cities
    'sharm el sheikh': DestinationInfo(
      name: 'Sharm El Sheikh',
      fullName: 'Sharm El Sheikh, South Sinai',
      description: 'Popular Red Sea resort destination',
      coordinates: LatLngInfo(27.9158, 34.3300),
      landmarks: ['Naama Bay', 'Ras Mohammed National Park', 'Old Market'],
      area: 'South Sinai',
    ),
    'hurghada': DestinationInfo(
      name: 'Hurghada',
      fullName: 'Hurghada, Red Sea',
      description: 'Major Red Sea resort town',
      coordinates: LatLngInfo(27.2574, 33.8129),
      landmarks: ['Marina Boulevard', 'Giftun Island', 'El Dahar'],
      area: 'Red Sea',
    ),
    'luxor': DestinationInfo(
      name: 'Luxor',
      fullName: 'Luxor, Luxor Governorate',
      description: 'Ancient city with pharaonic monuments',
      coordinates: LatLngInfo(25.6872, 32.6396),
      landmarks: ['Valley of the Kings', 'Karnak Temple', 'Luxor Temple'],
      area: 'Luxor',
    ),
    'aswan': DestinationInfo(
      name: 'Aswan',
      fullName: 'Aswan, Aswan Governorate',
      description: 'Southern city on the Nile',
      coordinates: LatLngInfo(24.0889, 32.8998),
      landmarks: ['High Dam', 'Philae Temple', 'Nubian Village'],
      area: 'Aswan',
    ),
    
    // New Administrative Capital
    'new capital': DestinationInfo(
      name: 'New Administrative Capital',
      fullName: 'New Administrative Capital, Cairo',
      description: 'Egypt\'s new planned capital city',
      coordinates: LatLngInfo(30.0254, 31.7373),
      landmarks: ['Central Business District', 'Government Quarter', 'Green River'],
      area: 'New Capital',
    ),
    
    // 6th of October City
    '6th october': DestinationInfo(
      name: '6th of October City',
      fullName: '6th of October City, Giza',
      description: 'Planned satellite city west of Cairo',
      coordinates: LatLngInfo(29.9097, 30.9746),
      landmarks: ['Mall of Arabia', 'Dreamland', 'October University'],
      area: 'Giza',
    ),
    
    // Sheikh Zayed City
    'sheikh zayed': DestinationInfo(
      name: 'Sheikh Zayed City',
      fullName: 'Sheikh Zayed City, Giza',
      description: 'Modern residential city in Giza',
      coordinates: LatLngInfo(30.0982, 30.9776),
      landmarks: ['Arkan Plaza', 'Hyper One', 'Allegria'],
      area: 'Giza',
    ),
  };

  /// Analyzes route name and returns destination information
  DestinationInfo? analyzeRouteDestination(String routeName) {
    if (routeName.isEmpty) return null;
    
    final normalizedName = routeName.toLowerCase().trim();
    
    // Direct match
    if (_egyptDestinations.containsKey(normalizedName)) {
      return _egyptDestinations[normalizedName];
    }
    
    // Partial match - check if route name contains any destination keywords
    for (final entry in _egyptDestinations.entries) {
      final keyword = entry.key;
      final destination = entry.value;
      
      if (normalizedName.contains(keyword) || keyword.contains(normalizedName)) {
        return destination;
      }
    }
    
    // Check for common route patterns
    if (normalizedName.contains('shuttle') || normalizedName.contains('route')) {
      // Extract location from route name
      final words = normalizedName.split(' ');
      for (final word in words) {
        if (_egyptDestinations.containsKey(word)) {
          return _egyptDestinations[word];
        }
      }
    }
    
    return null;
  }

  /// Gets all available destinations
  List<DestinationInfo> getAllDestinations() {
    return _egyptDestinations.values.toList();
  }

  /// Gets destinations by area
  List<DestinationInfo> getDestinationsByArea(String area) {
    return _egyptDestinations.values
        .where((dest) => dest.area.toLowerCase() == area.toLowerCase())
        .toList();
  }

  /// Searches destinations by name or landmarks
  List<DestinationInfo> searchDestinations(String query) {
    if (query.isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase();
    
    return _egyptDestinations.values.where((dest) {
      return dest.name.toLowerCase().contains(normalizedQuery) ||
             dest.fullName.toLowerCase().contains(normalizedQuery) ||
             dest.description.toLowerCase().contains(normalizedQuery) ||
             dest.landmarks.any((landmark) => 
                 landmark.toLowerCase().contains(normalizedQuery));
    }).toList();
  }
}

class DestinationInfo {
  final String name;
  final String fullName;
  final String description;
  final LatLngInfo coordinates;
  final List<String> landmarks;
  final String area;

  const DestinationInfo({
    required this.name,
    required this.fullName,
    required this.description,
    required this.coordinates,
    required this.landmarks,
    required this.area,
  });
}

class LatLngInfo {
  final double latitude;
  final double longitude;

  const LatLngInfo(this.latitude, this.longitude);
}
