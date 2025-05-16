// lib/models/user.dart

class User {
  // Fields from GET /api/users and Registration Form
  final int? id;
  String firstName;
  String lastName;
  String phone;
  String? password;
  bool? allCourses; // API: "all_coures"
  String? grade;
  String? category;
  String? school;
  String? gender;
  String? region;
  String? status;
  bool? enrolledAll;
  String? device; // This will now be used in login as well
  DateTime? createdAt;
  DateTime? updatedAt;
  String? serviceType;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.password,
    this.allCourses,
    this.grade,
    this.category,
    this.school,
    this.gender,
    this.region,
    this.status,
    this.enrolledAll,
    this.device, // Added to constructor parameters
    this.createdAt,
    this.updatedAt,
    this.serviceType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      allCourses: json['all_coures'] as bool?, // API typo "all_coures"
      grade: json['grade'] as String?,
      category: json['category'] as String?,
      school: json['school'] as String?,
      gender: json['gender'] as String?,
      region: json['region'] as String?,
      status: json['status'] as String?,
      enrolledAll: json['enrolled_all'] as bool?,
      device: json['device'] as String?,
      createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse(json['updatedAt'].toString()),
      // serviceType is not typically part of the main user object from /api/users
      // It's used during registration and might be part of a more detailed user profile endpoint.
    );
  }

  Map<String, dynamic> toJsonForFullRegistration() {
    return {
      "first_name": firstName,
      "last_name": lastName,
      "phone": phone,
      "password": password,
      "all_coures": allCourses ?? false, // API typo
      "grade": grade,
      "category": category,
      "school": school,
      "gender": gender,
      "region": region ?? "Not Specified",
      "status": status ?? "pending",
      "enrolled_all": enrolledAll ?? false,
      "device": device,
      "serviceType": serviceType, // Include if your /api/users endpoint accepts this
    };
  }

  Map<String, dynamic> toJsonForLogin() {
    return {
      "phone": phone,
      "password": password,
      "device": device, // <<< MODIFIED: Added device field
    };
  }

  Map<String, dynamic> toJsonForSimpleSignUp() {
    // Ensure this matches what your simple sign-up endpoint expects
    return {
      "phone": phone, // Or "phoneNumber" if API expects that
      "password": password,
      "firstName": firstName, // If simple signup also takes names
      "lastName": lastName,
      // "language": "en", // Example, or dynamically set if needed
      "device": device, // It's good practice to send device on signup too
    };
  }
}