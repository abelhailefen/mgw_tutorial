// lib/provider/testimonial_provider.dart
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'dart:io'; // For SocketException
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/testimonial.dart';

class TestimonialProvider with ChangeNotifier {
  List<Testimonial> _testimonials = []; // This will now hold all testimonials
  bool _isLoading = false;
  String? _error;

  List<Testimonial> get testimonials => [..._testimonials]; // UI consumes this directly
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api";
  static const String _networkErrorMessage = "Network error. Check connection.";
  static const String _timeoutErrorMessage = "Request timed out.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadMessage = "Failed to load testimonials.";

  Future<void> fetchTestimonials({bool forceRefresh = false}) async { // Removed statusFilter/clientSideFilter
    print("[Provider] fetchTestimonials CALLED - forceRefresh: $forceRefresh, current isLoading: $_isLoading");

    if (_isLoading && !forceRefresh) {
      print("[Provider] fetchTestimonials SKIPPED - already loading and not forcing.");
      return;
    }

    _isLoading = true;
    _error = null;
    if (forceRefresh) {
      print("[Provider] fetchTestimonials - Force refreshing, clearing existing testimonials data.");
      _testimonials = [];
    }
    notifyListeners();

    // Always fetch ALL testimonials
    String apiUrl = '$_apiBaseUrl/testimonials';
    print("[Provider] fetchTestimonials - Fetching ALL from API via: $apiUrl");
    final url = Uri.parse(apiUrl);

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 20));

      print("[Provider] fetchTestimonials - API Response Status: ${response.statusCode}");
      final responseBodySnippet = response.body.length > 300 ? response.body.substring(0, 300) : response.body;
      print("[Provider] fetchTestimonials - API Response Body (Snippet): $responseBodySnippet...");

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        if (decodedData is List) {
          _testimonials = decodedData
              .map((testimonialJson) {
                try {
                  return Testimonial.fromJson(testimonialJson as Map<String, dynamic>);
                } catch (e) {
                  print("[Provider] fetchTestimonials - ERROR parsing single testimonial: $e. JSON: $testimonialJson");
                  return null;
                }
              })
              .whereType<Testimonial>()
              .toList();
          _testimonials.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by date
          _error = null;
          print("[Provider] fetchTestimonials - Successfully parsed ${_testimonials.length} total testimonials from API.");
        } else {
          _error = '$_failedToLoadMessage: API response was not a list as expected.';
          _testimonials = [];
          print("[Provider] fetchTestimonials - $_error Data: $decodedData");
        }
      } else {
        String errorMessage = '$_failedToLoadMessage. Status: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message') && errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {/* ignore */}
        _error = errorMessage;
        _testimonials = [];
        print("[Provider] fetchTestimonials - HTTP Error: $_error. Full Response: ${response.body}");
      }
    } on TimeoutException catch (e, s) {
      _error = _timeoutErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonials - TimeoutException: $e\n$s");
    } on SocketException catch (e, s) {
      _error = _networkErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonials - SocketException: $e\n$s");
    } on FormatException catch (e, s) {
        _error = "$_failedToLoadMessage: Could not parse server response.";
        _testimonials = [];
        print("[Provider] fetchTestimonials - FormatException (JSON parsing): $e\n$s");
    } catch (e, s) {
      _error = _unexpectedErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonials - Generic Exception: $e\n$s");
    } finally {
      _isLoading = false;
      print("[Provider] fetchTestimonials - FINISHED. isLoading: $_isLoading, error: $_error, testimonials count: ${_testimonials.length}");
      notifyListeners(); // Notify after all operations
    }
  }

  Future<bool> createTestimonial({
    required String title,
    required String description,
    required int userId,
    List<String>? imagePaths,
  }) async {
    print("[Provider] createTestimonial CALLED");
    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/testimonials');
    print("[Provider] createTestimonial - Posting to: $url");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-User-ID": userId.toString(),
        },
        body: json.encode({
          'title': title,
          'description': description,
          'userId': userId,
          'status': 'pending',
          'images': imagePaths ?? [],
        }),
      ).timeout(const Duration(seconds: 30));

      print("[Provider] createTestimonial - API Response Status: ${response.statusCode}");
      print("[Provider] createTestimonial - API Response Body: ${response.body}");

      if (response.statusCode == 201) {
        // After successful creation, refresh ALL testimonials from API.
        // The fetchTestimonials method will handle loading states and notify.
        await fetchTestimonials(forceRefresh: true);
        return true;
      } else {
        try {
            final errorData = json.decode(response.body);
            _error = (errorData is Map && errorData['message'] != null) ? errorData['message'].toString() : "$_failedToLoadMessage (Create): ${response.statusCode}";
        } catch(e) {
            _error = "$_failedToLoadMessage (Create): ${response.statusCode}, Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}";
        }
        _isLoading = false; // Manually set isLoading if fetchTestimonials is not called or fails
        notifyListeners();
        return false;
      }
    } on TimeoutException catch (e) {
      _error = _timeoutErrorMessage;
      _isLoading = false;
      notifyListeners();
      print("[Provider] createTestimonial - Timeout: $e");
      return false;
    } on SocketException catch (e) {
      _error = _networkErrorMessage;
      _isLoading = false;
      notifyListeners();
      print("[Provider] createTestimonial - SocketException: $e");
      return false;
    }
    catch (e) {
      _isLoading = false;
      _error = "$_unexpectedErrorMessage (Create): ${e.toString()}";
      notifyListeners();
      print("[Provider] createTestimonial - Generic Error: $e");
      return false;
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
      print("[Provider] clearError called.");
    }
  }

  void clearTestimonials() {
    _testimonials = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
    print("[Provider] clearTestimonials called.");
  }
}