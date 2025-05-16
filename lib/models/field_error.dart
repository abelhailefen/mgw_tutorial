// lib/models/field_error.dart

class FieldError {
  final String field;
  final String message;

  FieldError({
    required this.field,
    required this.message,
  });

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field'] as String? ?? 'unknown_field',
      message: json['message'] as String? ?? 'No specific error message for this field.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
    };
  }
}