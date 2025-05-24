// lib/models/user.dart

class User {
  final int? id; // Nullable if not always present (e.g., during registration payload)
  final String firstName;
  final String lastName;
  final String phone;
  final String? password; // Nullable for responses, required for login/signup
  final bool? allCourses;
  final String? grade;
  final String? category; // e.g., stream
  final String? school;
  final String? gender;
  final String? region;
  final String? status; // e.g., "pending", "approved", "denied"
  final bool? enrolledAll;
  final String? device;
  final String? serviceType;
  final List<int>? enrolledCourseIds; // <<< NEW FIELD

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
    this.device,
    this.serviceType,
    this.enrolledCourseIds, // <<< NEW FIELD
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse list of ints
    List<int>? parseEnrolledCourseIds(dynamic ids) {
      if (ids == null) return null;
      if (ids is List) {
        return ids.map((id) {
          if (id is int) return id;
          if (id is String) return int.tryParse(id);
          return null;
        }).whereType<int>().toList();
      }
      if (ids is String) { // If it's a single ID as a string
        final parsedId = int.tryParse(ids);
        return parsedId != null ? [parsedId] : null;
      }
      if (ids is int) { // If it's a single ID as an int
        return [ids];
      }
      return null;
    }

    return User(
      id: json['id'] as int?,
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      // Password is not typically returned from API for security reasons
      allCourses: json['all_courses'] as bool? ?? json['allCourses'] as bool?,
      grade: json['grade'] as String?,
      category: json['category'] as String?,
      school: json['school'] as String?,
      gender: json['gender'] as String?,
      region: json['region'] as String?,
      status: json['status'] as String?,
      enrolledAll: json['enrolled_all'] as bool? ?? json['enrolledAll'] as bool?,
      device: json['device'] as String?,
      serviceType: json['service_type'] as String? ?? json['serviceType'] as String?,
      enrolledCourseIds: parseEnrolledCourseIds(json['enrolled_course_ids'] ?? json['enrolledCourseIds'] ?? json['courseId'] /* Fallback for single courseId */), // <<< PARSE NEW FIELD
    );
  }

  Map<String, dynamic> toJsonForLogin() {
    return {
      'phone': phone,
      'password': password,
      'device': device,
    };
  }

  Map<String, dynamic> toJsonForSimpleSignUp() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'password': password,
      'device': device,
    };
  }

  Map<String, dynamic> toJsonForFullRegistration() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'password': password,
      'all_courses': allCourses ?? false,
      'grade': grade,
      'category': category,
      'school': school,
      'gender': gender,
      'region': region,
      'status': status ?? "pending", // Default to pending if not provided
      'enrolled_all': enrolledAll ?? false,
      'device': device,
      'service_type': serviceType,
      // enrolledCourseIds are usually set by the backend, not sent during registration
    };
  }
}