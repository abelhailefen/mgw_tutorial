// lib/provider/faq_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/faq.dart'; // Your Faq model

class FaqProvider with ChangeNotifier {
  List<Faq> _faqs = [];
  bool _isLoading = false;
  String? _error;

  List<Faq> get faqs =>
      _faqs.where((faq) => faq.isActive).toList(); // Only show active FAQs
  List<Faq> get allFaqs =>
      _faqs; // If you need to access all, e.g., for an admin panel
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String _apiUrl = "https://courseservice.mgwcommunity.com/api/faqs";

  Future<void> fetchFaqs({bool forceRefresh = false}) async {
    if (_faqs.isNotEmpty && !forceRefresh && _error == null) {
      // Data already loaded and no error, no need to fetch again unless forced
      return;
    }

    _isLoading = true;
    _error = null;
    // No need to notify listeners here if you want loading state to be more subtle
    // Or notify if you have a dedicated loading UI that depends on this initial state
    // notifyListeners();

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _faqs = responseData.map((data) => Faq.fromJson(data)).toList();
        _error = null;
      } else {
        // Attempt to parse error message from backend
        try {
          final errorData = json.decode(response.body);
          _error = errorData['message'] ??
              'Failed to load FAQs. Status code: ${response.statusCode}';
        } catch (e) {
          _error = 'Failed to load FAQs. Status code: ${response.statusCode}';
        }
      }
    } catch (e) {
      print("Error fetching FAQs: $e");
      _error = 'An error occurred while fetching FAQs: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearFaqs() {
    _faqs = [];
    _error = null;
    _isLoading = false;
    // notifyListeners(); // Usually called after operations like logout
  }
}
