import 'package:mgw_tutorial/models/user.dart';

class AuthResponse {
  final User? user; // Make user nullable
  final String? token;
  final String? message; // Add message to capture API response
  final int? code; // Add code to capture API response

  AuthResponse({
    this.user, // User is optional
    this.token,
    this.message,
    this.code,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      token: json['token'] as String?,
      message: json['message'] as String?,
      code: json['code'] as int?,
    );
  }
}