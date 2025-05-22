// lib/models/api_error.dart
import 'package:mgw_tutorial/models/field_error.dart'; 
import 'package:mgw_tutorial/models/field_error.dart';
class ApiError {
  final String message;
  final List<FieldError>? errors;

  ApiError({required this.message, this.errors});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    var errorsList = json['errors'] as List<dynamic>?;
    List<FieldError>? fieldErrors;
    if (errorsList != null) {
      fieldErrors = errorsList.map((e) => FieldError.fromJson(e as Map<String, dynamic>)).toList();
    }
    return ApiError(
      message: json['message'] as String? ?? 'An unknown error occurred.',
      errors: fieldErrors,
    );
  }
}