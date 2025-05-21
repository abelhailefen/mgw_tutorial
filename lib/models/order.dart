// lib/models/order.dart
import 'dart:convert';

// Renamed and generalized from OrderCategory
class OrderSelectionItem {
  final String id; // e.g., Semester ID
  final String name; // e.g., Semester Name

  OrderSelectionItem({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    // The API for orders expects "catagory" for the name field in its stringified JSON
    return {
      'id': id,
      'catagory': name, // Keep 'catagory' to match the existing order API
    };
  }

  factory OrderSelectionItem.fromJson(Map<String, dynamic> json) {
    return OrderSelectionItem(
      id: json['id'] as String,
      name: json['catagory'] as String, // Reads 'catagory' from API
    );
  }
}

class Order {
  final int? id;
  final String fullName;
  final String? bankName;
  final String phone;
  final String type; // Will be "department"
  final String status;
  // This 'categories' field in the Order model will now hold selected semesters (or other items)
  // and will be stringified from a List<OrderSelectionItem>
  final List<OrderSelectionItem> selections; // Renamed from 'categories' for clarity in the model
  final List<dynamic> courses;
  final String? screenshot;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    required this.fullName,
    this.bankName,
    required this.phone,
    required this.type,
    required this.status,
    required this.selections, // Changed from categories
    this.courses = const [],
    this.screenshot,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJsonForApi() {
    return {
      'full_name': fullName,
      'bank_name': bankName ?? "N/A",
      'phone': phone,
      'type': type, // This will be "department"
      'status': status,
      // The API's 'categories' field receives the stringified 'selections'
      'categories': jsonEncode(selections.map((sel) => sel.toJson()).toList()),
      'courses': jsonEncode(courses),
     // 'screenshot': screenshot,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderSelectionItem> parsedSelections = [];
    if (json['categories'] != null && json['categories'] is String) { // API uses 'categories'
      try {
        List<dynamic> sels = jsonDecode(json['categories']);
        parsedSelections = sels.map((s) => OrderSelectionItem.fromJson(s as Map<String, dynamic>)).toList();
      } catch (e) {
        print("Error parsing selections (categories) from order: $e");
      }
    }
    // ... (rest of fromJson for courses, etc. remains similar)
     List<dynamic> parsedCourses = [];
     if (json['courses'] != null && json['courses'] is String) {
      try {
        parsedCourses = jsonDecode(json['courses']);
      } catch (e) {
        print("Error parsing courses from order: $e");
      }
    }

    return Order(
      id: json['id'] as int?,
      fullName: json['full_name'] as String,
      bankName: json['bank_name'] as String?,
      phone: json['phone'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      selections: parsedSelections, // Use parsed selections
      courses: parsedCourses,
      screenshot: json['screenshot'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}