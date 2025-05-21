// lib/models/author.dart
class Author {
  final int id;
  final String name;

  Author({
    required this.id,
    required this.name,
  });

  // Helper function to safely extract and cast int values
  static int _safeGetInt(Map<String, dynamic> json, String key, String modelName) {
    final value = json[key];
    if (value == null) {
      throw FormatException("Field '$key' is null in $modelName JSON, expected int. JSON: $json");
    }
    if (value is String) { // Try to parse if it's a string
        final parsedValue = int.tryParse(value);
        if (parsedValue != null) return parsedValue;
        throw FormatException("Field '$key' is a String that cannot be parsed to int in $modelName JSON. Value: '$value'. JSON: $json");
    }
    if (value is! int) {
      throw FormatException("Field '$key' is not an int in $modelName JSON, expected int but got ${value.runtimeType}. JSON: $json");
    }
    return value;
  }

  static String _safeGetString(Map<String, dynamic> json, String key, String modelName) {
    final value = json[key];
    if (value == null) {
      throw FormatException("Field '$key' is null in $modelName JSON, expected String. JSON: $json");
    }
    if (value is! String) {
      throw FormatException("Field '$key' is not a String in $modelName JSON, expected String but got ${value.runtimeType}. JSON: $json");
    }
    return value;
  }

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: _safeGetInt(json, 'id', 'Author'), // Use the helper
      name: _safeGetString(json, 'name', 'Author'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}