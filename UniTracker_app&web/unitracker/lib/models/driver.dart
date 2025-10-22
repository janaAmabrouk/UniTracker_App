class Driver {
  final String id;
  final String name;
  final String driverId;
  final String licenseNumber;
  final DateTime licenseExpirationDate;
  final String licenseImagePath;
  final String? profileImage;
  final bool isAvailable;
  final String? currentRouteId;
  final String? currentBusId;
  final bool isLocalImage;

  const Driver({
    required this.id,
    required this.name,
    required this.driverId,
    required this.licenseNumber,
    required this.licenseExpirationDate,
    required this.licenseImagePath,
    this.profileImage,
    this.isAvailable = true,
    this.currentRouteId,
    this.currentBusId,
    this.isLocalImage = false,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? driverId,
    String? licenseNumber,
    DateTime? licenseExpirationDate,
    String? licenseImagePath,
    String? profileImage,
    bool? isAvailable,
    String? currentRouteId,
    String? currentBusId,
    bool? isLocalImage,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      driverId: driverId ?? this.driverId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpirationDate:
          licenseExpirationDate ?? this.licenseExpirationDate,
      licenseImagePath: licenseImagePath ?? this.licenseImagePath,
      profileImage: profileImage ?? this.profileImage,
      isAvailable: isAvailable ?? this.isAvailable,
      currentRouteId: currentRouteId ?? this.currentRouteId,
      currentBusId: currentBusId ?? this.currentBusId,
      isLocalImage: isLocalImage ?? this.isLocalImage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'driverId': driverId,
      'licenseNumber': licenseNumber,
      'licenseExpirationDate': licenseExpirationDate.toIso8601String(),
      'licenseImagePath': licenseImagePath,
      'profileImage': profileImage,
      'isAvailable': isAvailable,
      'currentRouteId': currentRouteId,
      'currentBusId': currentBusId,
      'isLocalImage': isLocalImage,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as String,
      name: map['name'] as String,
      driverId: map['driverId'] as String,
      licenseNumber: map['licenseNumber'] as String,
      licenseExpirationDate:
          DateTime.parse(map['licenseExpirationDate'] as String),
      licenseImagePath: map['licenseImagePath'] as String,
      profileImage: map['profileImage'] as String?,
      isAvailable: map['isAvailable'] as bool? ?? true,
      currentRouteId: map['currentRouteId'] as String?,
      currentBusId: map['currentBusId'] as String?,
      isLocalImage: map['isLocalImage'] as bool? ?? false,
    );
  }
}
