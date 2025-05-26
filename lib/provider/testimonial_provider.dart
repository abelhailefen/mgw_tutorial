// lib/provider/testimonial_provider.dart
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'dart:io'; // For SocketException
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/testimonial.dart';
import 'package:http_parser/http_parser.dart'; // Needed for MediaType
import 'package:image_picker/image_picker.dart'; // Needed for XFile

class TestimonialProvider with ChangeNotifier {
  List<Testimonial> _testimonials = [];
  bool _isLoading = false;
  String? _error;

  List<Testimonial> get testimonials => [..._testimonials];
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String apiBaseUrl = "https://mgw-backend.onrender.com/api";

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadMessage = "Failed to load testimonials.";
  static const String _failedToCreateTestimonialMessage = "Failed to submit testimonial.";


  Future<void> fetchTestimonials({bool forceRefresh = false}) async {
    print("[Provider] fetchTestimonials CALLED - forceRefresh: $forceRefresh, current isLoading: $_isLoading");

    if (_isLoading && !forceRefresh) {
       print("[Provider] fetchTestimonials SKIPPED - already loading and not forcing.");
       return;
    }

    _isLoading = true;
    _error = null; // Clear error on new fetch attempt
    if (forceRefresh) {
      print("[Provider] fetchTestimonials - Force refreshing, clearing existing data.");
      _testimonials = [];
    }
    notifyListeners();

    // Fetch ONLY Approved based on the provided URL structure
    String apiUrl = '$apiBaseUrl/testimonials/by-status?status=approved';
    print("[Provider] fetchTestimonials - Fetching Approved from API via: $apiUrl");
    final url = Uri.parse(apiUrl);

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
        // Add Authorization header if needed
        // "Authorization": "Bearer YOUR_TOKEN_HERE",
      }).timeout(const Duration(seconds: 20));

      print("[Provider] fetchTestimonials - API Response Status: ${response.statusCode}");

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
        } catch (e) {/* ignore JSON parsing errors on non-JSON error bodies */}
        _error = errorMessage;
        _testimonials = [];
        print("[Provider] fetchTestimonials - HTTP Error: $_error. Full Response: ${response.body}");
      }
    } on TimeoutException {
      _error = _timeoutErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonials - TimeoutException");
    } on SocketException {
      _error = _networkErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonials - SocketException");
    } on FormatException {
        _error = "$_failedToLoadMessage: Could not parse server response.";
        _testimonials = [];
        print("[Provider] fetchTestimonials - FormatException (JSON parsing)");
    } on http.ClientException catch (e) {
      _error = "$_networkErrorMessage: ${e.message}";
      _testimonials = [];
      print("[Provider] fetchTestimonials - ClientException: ${e.message}");
    }
    catch (e, s) {
      _error = _unexpectedErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonial - Generic Exception: $e\n$s");
    } finally {
      _isLoading = false;
      print("[Provider] fetchTestimonials - FINISHED. isLoading: $_isLoading, error: $_error, testimonials count: ${_testimonials.length}");
      notifyListeners();
    }
  }


  // --- MODIFIED createTestimonial for ONE file and description ---
  // Accepts a single XFile?, adds fields and the file to a single request
  Future<bool> createTestimonial({
    required String title,
    required String description, // Expecting the description here
    required int userId,
    XFile? imageFile, // Accepts a single XFile?
  }) async {
    // Log the values received by the provider method
    print("[Provider] createTestimonial CALLED with title='$title', description='$description', userId='$userId', imageFile: ${imageFile?.name}");
    _isLoading = true;
    _error = null;
    notifyListeners();

    // POST to the collection endpoint
    final url = Uri.parse('$apiBaseUrl/testimonials');
    print("[Provider] createTestimonial - Posting Multipart to: $url");

    try {
      var request = http.MultipartRequest('POST', url);

      // Add text fields - Use the EXACT names your backend expects
      print("[Provider] createTestimonial - Adding fields to request:");
      print("  'title': '$title'");
      print("  'description': '$description'"); // <-- Log description again before adding to fields
      print("  'userId': '$userId'");
      print("  'status': 'pending'");

      request.fields['title'] = title;
      request.fields['description'] = description; // <-- Adding description to fields
      request.fields['userId'] = userId.toString(); // Send as string
      request.fields['status'] = 'pending'; // Set initial status


       // Add headers if needed (e.g., Authorization)
       // request.headers.addAll({
       //   "Authorization": "Bearer YOUR_TOKEN_HERE",
       // });

      // Add the single image file if provided
      if (imageFile != null) {
         print("[Provider] createTestimonial - Attaching single image file: ${imageFile.name} under field 'image'"); // Log field name
         String fileExtension = imageFile.path.split('.').last.toLowerCase();
          MediaType? contentType;
          if (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'jfif') {
            contentType = MediaType('image', 'jpeg');
          } else if (fileExtension == 'png') {
            contentType = MediaType('image', 'png');
          } else if (fileExtension == 'gif') {
              contentType = MediaType('image', 'gif');
          } else if (fileExtension == 'webp') {
              contentType = MediaType('image', 'webp');
          } else {
              print("[Provider] createTestimonial - Unknown file extension: $fileExtension for ${imageFile.name}, using default MediaType.");
              contentType = MediaType('application', 'octet-stream');
          }

         request.files.add(await http.MultipartFile.fromPath(
           'image', // <--- Field name for files, confirmed as 'image' by your example response
           imageFile.path,
           contentType: contentType,
           filename: imageFile.name,
         ));
         print("[Provider] createTestimonial - Added file: ${imageFile.name} (Field: 'image', Type: $contentType)");
      } else {
         print("[Provider] createTestimonial - No image file to attach.");
      }


      // Send the request
      var streamedResponse = await request.send().timeout(const Duration(seconds: 45)); // Use a longer timeout
      var response = await http.Response.fromStream(streamedResponse);

      print("[Provider] createTestimonial - API Response Status: ${response.statusCode}");
      print("[Provider] createTestimonial - API Response Body: ${response.body}"); // Log full body for debugging

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("[Provider] createTestimonial - Creation successful.");
        _isLoading = false;
        notifyListeners();
        // Refresh the list after successful creation (still fetches only Approved)
        await fetchTestimonials(forceRefresh: true);
        return true;
      } else {
        String errorMessage = "$_failedToCreateTestimonialMessage. Status: ${response.statusCode}";
        // Attempt to parse error message from body
        try {
            final errorData = json.decode(response.body);
            if (errorData is Map && errorData.containsKey('message') && errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            } else {
               errorMessage = "$_failedToCreateTestimonialMessage. Status: ${response.statusCode}, Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...";
            }
        } catch(e) {
            errorMessage = "$_failedToCreateTestimonialMessage. Status: ${response.statusCode}. Could not parse error details.";
        }
        _error = errorMessage;
        _isLoading = false;
        notifyListeners();
        print("[Provider] createTestimonial - HTTP Error: $_error");
        return false;
      }
    } on TimeoutException {
      _error = _timeoutErrorMessage;
      _isLoading = false;
      notifyListeners();
      print("[Provider] createTestimonial - Timeout");
      return false;
    } on SocketException {
      _error = _networkErrorMessage;
      _isLoading = false;
      notifyListeners();
      print("[Provider] createTestimonial - SocketException");
      return false;
    } on http.ClientException catch (e) {
       _error = "$_networkErrorMessage: ${e.message}";
       _isLoading = false;
       notifyListeners();
       print("[Provider] createTestimonial - ClientException: ${e.message}");
       return false;
    }
    catch (e, s) {
      _isLoading = false;
      _error = "$_unexpectedErrorMessage (Create): ${e.toString()}";
      notifyListeners();
      print("[Provider] createTestimonial - Generic Exception: $e\n$s");
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