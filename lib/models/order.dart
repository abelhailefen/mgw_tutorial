// lib/models/order.dart
import 'dart:convert';

// Renamed and generalized from OrderCategory
class OrderSelectionItem {
  final String id; // e.g., Semester ID (or Course ID if type is 'courses')
  final String name; // e.g., Semester Name (or Course Name) - API expects "catagory"

  OrderSelectionItem({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(), // Ensure ID is string if it could be int
      'catagory': name,    // Matches API's "catagory"
    };
  }

  factory OrderSelectionItem.fromJson(Map<String, dynamic> json) {
    return OrderSelectionItem(
      id: json['id'].toString(), // API might send int or string, ensure string
      name: json['catagory'] as String,
    );
  }
}

class Order {
  final int? id;
  final String fullName;
  final String? bankName; // User-entered bank name
  final String phone;
  final String type; // e.g., "semester_enrollment", "courses"
  final String status;
  final List<OrderSelectionItem> selections; // Represents "categories" in API
  final List<dynamic> courses; // If you also need to pass a list of simple course IDs/names
  final String? screenshot; // Path to screenshot from API response
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    required this.fullName,
    this.bankName,
    required this.phone,
    required this.type,
    required this.status,
    required this.selections,
    this.courses = const [], // Default to empty list if not provided
    this.screenshot,
    this.createdAt,
    this.updatedAt,
  });

  // This method prepares data for the MultipartRequest fields
  Map<String, String> toJsonForApiFields() { // Renamed to clarify it's for fields
    return {
      'full_name': fullName,
      if (bankName != null && bankName!.isNotEmpty) 'bank_name': bankName!,
      'phone': phone,
      'type': type,
      'status': status,
      'categories': jsonEncode(selections.map((sel) => sel.toJson()).toList()),
      // 'courses' can be more complex. If it's just an array of IDs or simple strings:
      'courses': jsonEncode(courses.map((c) => c.toString()).toList()), // Example if courses are simple IDs/strings
      // The 'screenshot' field itself is not sent as a text field,
      // but as a file part in the MultipartRequest.
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderSelectionItem> parsedSelections = [];
    if (json['categories'] != null) {
      // API sends 'categories' as an array of objects directly in the JSON response,
      // not as a JSON string within a string.
      if (json['categories'] is List) {
        try {
          List<dynamic> sels = json['categories'] as List<dynamic>;
          parsedSelections = sels.map((s) => OrderSelectionItem.fromJson(s as Map<String, dynamic>)).toList();
        } catch (e) {
          print("Error parsing 'categories' list from order JSON: $e. JSON: ${json['categories']}");
        }
      } else if (json['categories'] is String) { // Fallback if it IS a string in some case
         try {
            List<dynamic> sels = jsonDecode(json['categories']);
            parsedSelections = sels.map((s) => OrderSelectionItem.fromJson(s as Map<String, dynamic>)).toList();
          } catch (e) {
            print("Error parsing 'categories' string from order JSON: $e. JSON: ${json['categories']}");
          }
      }
    }

    List<dynamic> parsedCourses = [];
    if (json['courses'] != null) {
      if (json['courses'] is List) {
        parsedCourses = json['courses'] as List<dynamic>;
      } else if (json['courses'] is String) { // Fallback for stringified list
        try {
          parsedCourses = jsonDecode(json['courses']);
        } catch (e) {
          print("Error parsing 'courses' string from order JSON: $e. JSON: ${json['courses']}");
        }
      }
    }


    return Order(
      id: json['id'] as int?,
      fullName: json['full_name'] as String? ?? '',
      bankName: json['bank_name'] as String?,
      phone: json['phone'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      selections: parsedSelections,
      courses: parsedCourses,
      screenshot: json['screenshot'] as String?, // This is the path from the server
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}