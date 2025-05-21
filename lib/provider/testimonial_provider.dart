// lib/provider/testimonial_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/testimonial.dart';

class TestimonialProvider with ChangeNotifier {
  List<Testimonial> _testimonials = [];
  bool _isLoading = false;
  String? _error;

  List<Testimonial> get testimonials => [..._testimonials];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // API Base URL for testimonials
  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api";

  Future<void> fetchTestimonials({bool forceRefresh = false, String? statusFilter = "approved"}) async {
    if (!forceRefresh && _testimonials.isNotEmpty && !_isLoading) {
      // Optional: Add logic here if you want to avoid refetching if a specific filter was already applied
      // For now, it refetches if forceRefresh is true or list is empty/error.
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    String apiUrl = '$_apiBaseUrl/testimonials';
    if (statusFilter != null && statusFilter.isNotEmpty) {
        apiUrl += '?status=$statusFilter'; // Example: /api/testimonials?status=approved
    }

    final url = Uri.parse(apiUrl);
    print("Fetching testimonials from: $url");

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      });

      print("Testimonials API Response Status: ${response.statusCode}");
      // print("Testimonials API Response Body: ${response.body}"); // For debugging

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        if (decodedData is List) {
          _testimonials = decodedData
              .map((testimonialJson) {
                  try {
                    return Testimonial.fromJson(testimonialJson as Map<String, dynamic>);
                  } catch (e) {
                    print("Error parsing testimonial: $e. JSON: $testimonialJson");
                    return null; // Skip problematic items
                  }
              })
              .whereType<Testimonial>() // Filter out nulls from parsing errors
              .toList();
          // Sort by creation date, newest first
          _testimonials.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _error = null;
        } else {
          print("Testimonials API response was not a list as expected. Data: $decodedData");
          _error = 'Failed to load testimonials: Unexpected API response format.';
          _testimonials = [];
        }
      } else {
        String errorMessage = 'Failed to load testimonials. Status Code: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData != null && errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (response.body.isNotEmpty) {
            errorMessage += "\nAPI Response: ${response.body}";
          }
        } catch (e) {
          errorMessage += "\nRaw API Response: ${response.body}";
        }
        _error = errorMessage;
        print("Error fetching testimonials: $_error");
      }
    } catch (e) {
      _error = 'An unexpected error occurred while fetching testimonials: ${e.toString()}';
      print("Exception during fetchTestimonials: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to allow creating a testimonial (if your app supports this)
  // This is a placeholder and needs to match your backend's requirements for POST
  Future<bool> createTestimonial({
    required String title,
    required String description,
    required int userId, // Assuming the logged-in user's ID
    List<String>? imagePaths, // For local image file paths if uploading
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/testimonials');
    // Note: Image uploading typically requires a multipart request.
    // This example shows a simple JSON POST. Adapt if you need image uploads.
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          // Add Authorization header if required
          // "Authorization": "Bearer YOUR_TOKEN",
          "X-User-ID": userId.toString(), // If your backend uses this for user ID
        },
        body: json.encode({
          'title': title,
          'description': description,
          'userId': userId,
          'status': 'pending', // New testimonials likely start as pending
          'images': imagePaths ?? [], // Send empty list if no images, or handle null
        }),
      );

      _isLoading = false;
      if (response.statusCode == 201) {
        // Optionally, fetch the new testimonial or add it locally if response contains it
        fetchTestimonials(forceRefresh: true, statusFilter: null); // Refresh list (or just approved)
        notifyListeners();
        return true;
      } else {
        _error = "Failed to create testimonial: ${response.statusCode} ${response.body}";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = "Error creating testimonial: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }


  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearTestimonials() {
    _testimonials = [];
    _error = null;
    notifyListeners();
  }
}