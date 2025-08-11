class User {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String university;
  final String department;
  final String role;
  final String? profileImage;
  final String? driverId;
  final String? licenseNumber;
  final String? licenseExpiration;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.university,
    required this.department,
    required this.role,
    this.profileImage,
    this.driverId,
    this.licenseNumber,
    this.licenseExpiration,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      studentId: json['studentId'] as String,
      university: json['university'] as String,
      department: json['department'] as String,
      role: json['role'] as String,
      profileImage: json['profileImage'] as String?,
      driverId: json['driverId'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      licenseExpiration: json['licenseExpiration'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  factory User.fromSupabase(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String,
      name: data['full_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      studentId: data['student_id'] as String? ?? '',
      university: data['university'] as String? ?? '',
      department: data['department'] as String? ?? '',
      role: data['role'] as String,
      profileImage: data['profile_image_url'] as String?,
      driverId:
          data['id'] as String?, // For drivers, use the user ID as driver ID
      licenseNumber: data['driver_license'] as String?,
      licenseExpiration: data['license_expiry'] as String?,
      phoneNumber: data['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'university': university,
      'department': department,
      'role': role,
      'profileImage': profileImage,
      'driverId': driverId,
      'licenseNumber': licenseNumber,
      'licenseExpiration': licenseExpiration,
      'phoneNumber': phoneNumber,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? university,
    String? department,
    String? role,
    String? profileImage,
    String? driverId,
    String? licenseNumber,
    String? licenseExpiration,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      university: university ?? this.university,
      department: department ?? this.department,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      driverId: driverId ?? this.driverId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiration: licenseExpiration ?? this.licenseExpiration,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
