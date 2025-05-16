// lib/models/auth_response.dart
import 'package:mgw_tutorial/models/user.dart'; // Ensure this path is correct

class AuthResponse {
  final User user;
  final String? token; // Token is nullable because the API doesn't send it yet

  AuthResponse({
    required this.user,
    this.token, // Token is optional in the constructor
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      
      token: json['token'] as String?,
    );
  }
}