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
    };
  }
}
