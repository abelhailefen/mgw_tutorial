// lib/provider/department_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/department.dart'; // Adjust path if needed

class DepartmentProvider with ChangeNotifier {
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;

  List<Department> get departments => [..._departments];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // API Base URL - ensure this is consistent with your other providers
  static const String _apiBaseUrl = "https://courseservice.anbesgames.com/api";

  Future<void> fetchDepartments() async {
    if (_departments.isNotEmpty) return; // Avoid refetching if already loaded

    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/departments');

    try {
      print("Fetching departments from: $url");
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      });
      print("Departments Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          _departments = extractedData
              .map((deptData) => Department.fromJson(deptData as Map<String, dynamic>))
              .toList();
        } else {
          _error = 'Failed to load departments: Response format is not a list.';
          print(_error);
        }
      } else {
        String errorMessage = 'Failed to load departments. Status: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData != null && errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (response.body.isNotEmpty) {
            errorMessage += "\nResponse: ${response.body}";
          }
        } catch (e) {
          errorMessage += "\nRaw response: ${response.body}";
        }
        _error = errorMessage;
        print("Error fetching departments: $_error");
      }
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      print("Exception fetching departments: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}