// lib/provider/testimonial_provider.dart
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'dart:io'; // For SocketException, File
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/testimonial.dart'; // Assuming Testimonial model exists and path is correct
import 'package:http_parser/http_parser.dart'; // Needed for MediaType
import 'package:image_picker/image_picker.dart'; // Needed for XFile
import 'package:flutter/material.dart'; // Needed for BuildContext if used in methods (e.g., delete), though try to avoid UI in provider

class TestimonialProvider with ChangeNotifier {
  // --- State for fetching testimonials ---
  List<Testimonial> _testimonials = [];
  bool _isLoading = false;
  String? _error;

  // --- Getters for state ---
  List<Testimonial> get testimonials => [..._testimonials]; // Return a copy to prevent external modification
  bool get isLoading => _isLoading;
  String? get error => _error; // Expose the error state

  // --- Constants ---
  static const String apiBaseUrl = "https://mgw-backend.onrender.com/api"; // Your backend URL

  // Standard error messages for the UI
  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadMessage = "Failed to load testimonials."; // Fixed typo here
  static const String _failedToCreateTestimonialMessage = "Failed to submit testimonial.";


  // --- Method to fetch testimonials (assumes fetching only Approved ones) ---
  Future<void> fetchTestimonials({bool forceRefresh = false}) async {
    print("[Provider] fetchTestimonials CALLED - forceRefresh: $forceRefresh, current isLoading: $_isLoading");

    // Prevent fetching if already loading, unless force refresh is requested
    if (_isLoading && !forceRefresh) {
       print("[Provider] fetchTestimonials SKIPPED - already loading and not forcing.");
       return;
    }

    _isLoading = true;
    _error = null; // Clear error on a new fetch attempt
    // Clear existing data immediately if force refreshing or doing initial fetch
    if (forceRefresh || _testimonials.isEmpty) { // Also clear if list is empty initially
      print("[Provider] fetchTestimonials - Clearing existing data due to force refresh or empty list.");
      _testimonials = [];
    }
    // Notify listeners that loading has started (optional, but can show loader immediately)
    // notifyListeners(); // Consider if you want a rapid initial loading state change

    // Fetch ONLY Approved based on the provided URL structure
    // Adjust endpoint if your API handles fetching based on different criteria
    String apiUrl = '$apiBaseUrl/testimonials/approved';
    print("[Provider] fetchTestimonials - Fetching Approved from API via: $apiUrl");
    final url = Uri.parse(apiUrl);

    try {
      // Perform the HTTP GET request
      // Note: fetch testimonials might also require user authentication if the API is protected.
      // If so, you'd need to add the same header here as in createTestimonial.
      final response = await http.get(url, headers: {
        "Accept": "application/json", // Request JSON response
        // Add Authentication header if needed for fetching (e.g., userId)
        // "X-User-ID": userId.toString(), // Example if needed here too
      }).timeout(const Duration(seconds: 20)); // Set a timeout for the request

      print("[Provider] fetchTestimonials - API Response Status: ${response.statusCode}");

      // Handle the HTTP response
      if (response.statusCode == 200) {
        // Successful response, parse the body
        final dynamic decodedData = json.decode(response.body);
        if (decodedData is List) {
          // Map JSON list to List<Testimonial> objects
          _testimonials = decodedData
              .map((testimonialJson) {
                try {
                  // Attempt to parse each JSON object into a Testimonial model
                  return Testimonial.fromJson(testimonialJson as Map<String, dynamic>);
                } catch (e) {
                  // Log errors for individual items if parsing fails, but continue with others
                  print("[Provider] fetchTestimonials - ERROR parsing single testimonial JSON: $e. JSON: $testimonialJson");
                  return null; // Return null for failed items
                }
              })
              .whereType<Testimonial>() // Filter out any nulls created by parsing errors
              .toList(); // Convert the iterable back to a list

          _testimonials.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by creation date (newest first)
          _error = null; // Clear error on success
          print("[Provider] fetchTestimonials - Successfully parsed ${_testimonials.length} total testimonials from API.");
        } else {
          // API returned non-list data unexpectedly
          _error = '$_failedToLoadMessage: API response was not a list as expected.';
          _testimonials = []; // Ensure list is empty on this type of error
          print("[Provider] fetchTestimonials - $_error Data: $decodedData");
        }
      } else {
        // HTTP status code is not 200
        String errorMessage = '$_failedToLoadMessage. Status: ${response.statusCode}';
        // Attempt to parse a specific error message from the response body if it's JSON
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message') && errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
           // Log the full body if parsing fails or no message key exists
           final bodySnippet = response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body;
            print("[Provider] fetchTestimonials - HTTP Error: $_error. Full Response: $bodySnippet");
        } catch (e) {
             // Catch errors if the body is not valid JSON
            print("[Provider] fetchTestimonials - HTTP Error: Failed to parse error response body for status ${response.statusCode}. Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...");
        }
        _error = errorMessage; // Set the error message
        _testimonials = []; // Ensure list is empty on fetch error
      }
    } on TimeoutException {
      // Handle request timeout
      _error = _timeoutErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonials - TimeoutException caught.");
    } on SocketException {
      // Handle network connectivity errors
      _error = _networkErrorMessage;
      _testimonials = [];
      print("[Provider] fetchTestimonials - SocketException caught.");
    } on FormatException {
       // Handle errors if the successful response body is not valid JSON
        _error = "$_failedToLoadMessage: Could not parse server response.";
        _testimonials = [];
        print("[Provider] fetchTestimonials - FormatException (JSON parsing) caught.");
    } on http.ClientException catch (e) {
       // Handle other http client errors
       _error = "$_networkErrorMessage: ${e.message}";
       _testimonials = [];
       print("[Provider] fetchTestimonials - ClientException caught: ${e.message}");
    }
    catch (e, s) {
      // Catch any other unexpected exceptions
      _error = _unexpectedErrorMessage; // Generic error message
      _testimonials = [];
      print("[Provider] fetchTestimonial - Generic Exception caught: $e\n$s"); // Log exception and stack trace
    } finally {
      // Always run this block after try/catch/on
      _isLoading = false; // Ensure loading state is false
      print("[Provider] fetchTestimonials - FINISHED. isLoading: $_isLoading, error: $_error, testimonials count: ${_testimonials.length}");
      notifyListeners(); // Notify listeners that the state has changed (loading finished, data/error updated)
    }
  }


  // --- Method to create a new testimonial ---
  // Accepts a list of XFile? for multiple image uploads
  Future<bool> createTestimonial({
    required String title,
    required String description, // Expecting the description here
    required int userId, // UserId is needed for the header
    List<XFile>? imageFiles, // Accepts a list of XFile?
  }) async {
    // Log the values received by the provider method for debugging
    print("[Provider] createTestimonial CALLED with title='$title', description='$description', userId='$userId', imageFiles count: ${imageFiles?.length}");

    // Set loading state and clear previous errors before starting the request
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify listeners to show loading indicator


    // --- Check if userId is valid (not -1 or some default) ---
    // Assuming 0 or -1 indicates an invalid user ID before sending
    if (userId <= 0) {
       print("[Provider] createTestimonial - Invalid userId provided: $userId");
       _error = "Invalid user ID. Please log in again."; // TODO: Localize
       _isLoading = false;
       notifyListeners();
       return false;
    }

    // POST to the testimonial collection endpoint
    final url = Uri.parse('$apiBaseUrl/testimonials');
    print("[Provider] createTestimonial - Posting Multipart to: $url");

    try {
      // Create a MultipartRequest to send both text fields and files
      var request = http.MultipartRequest('POST', url);

      // Add text fields to the request - Use the EXACT names your backend expects
      print("[Provider] createTestimonial - Adding fields to request:");
      print("  'title': '$title'");
      print("  'description': '$description'"); // Log description again before adding to fields
      print("  'userId': '$userId' (as field)"); // Log field value
      print("  'status': 'pending'"); // Assuming initial status is pending review

      // IMPORTANT: Even if you send userId in a header, some backends might also expect it as a form field.
      // Add it as a field as well, as per your previous working log, unless backend docs say otherwise.
      request.fields['title'] = title;
      request.fields['description'] = description; // Add description field
      request.fields['userId'] = userId.toString(); // Send userId as a string form field
      request.fields['status'] = 'pending'; // Set initial status field


      // --- ADD AUTHENTICATION HEADER(S) HERE ---
      // As requested, using userId in a header.
      // CONFIRM the exact header name and format your backend expects.
      // Example 1: Custom header X-User-ID
      request.headers['X-User-ID'] = userId.toString();
      print("[Provider] createTestimonial - Added X-User-ID header: ${userId.toString()}");

      // Example 2: Authorization header with User-ID scheme (less common but possible)
      // request.headers['Authorization'] = 'User-ID ${userId.toString()}';
      // print("[Provider] createTestimonial - Added Authorization header: User-ID ${userId.toString()}");

      // Example 3: If userId IS the token (unlikely, but just illustrates)
      // request.headers['Authorization'] = 'Bearer ${userId.toString()}';
      // print("[Provider] createTestimonial - Added Authorization header: Bearer ${userId.toString()}");

       // Add other headers if needed
       // request.headers.addAll({
       //   "Content-Type": "multipart/form-data", // Not always needed, http package handles this
       // });


      // Add the image file(s) if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
         print("[Provider] createTestimonial - Attaching ${imageFiles.length} image file(s) under field 'images'"); // Log plural field name (Assumption)
         // Iterate through the list of files and add each one
         for (var imageFile in imageFiles) {
             // Determine the Content-Type (MIME type) based on file extension
             String fileExtension = imageFile.path.split('.').last.toLowerCase();
              MediaType? contentType;
              // Common image types
              if (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'jfif') {
                contentType = MediaType('image', 'jpeg');
              } else if (fileExtension == 'png') {
                contentType = MediaType('image', 'png');
              } else if (fileExtension == 'gif') {
                  contentType = MediaType('image', 'gif');
              } else if (fileExtension == 'webp') {
                  contentType = MediaType('image', 'webp');
              } else {
                   // Fallback for other potential image types or unknown
                   // If backend is strict, you might want to only allow known types
                   print("[Provider] createTestimonial - Warning: Unknown image file extension: $fileExtension for ${imageFile.name}. Using application/octet-stream. Backend might reject.");
                  contentType = MediaType('application', 'octet-stream'); // Generic binary type
              }

             // Create a MultipartFile for the current file
             request.files.add(await http.MultipartFile.fromPath(
               'images', // <--- **IMPORTANT:** Use the field name your backend expects for the list of files (ASSUMPTION: 'images')
               imageFile.path, // Path to the file on the device
               contentType: contentType, // Set the determined content type
               filename: imageFile.name, // Optional: Include original filename sent to server
             ));
             print("[Provider] createTestimonial - Added file: ${imageFile.name} (Field: 'images', Type: $contentType)"); // Log details
         }
      } else {
         print("[Provider] createTestimonial - No image files to attach."); // Log if no files
      }


      // Send the multipart request
      var streamedResponse = await request.send().timeout(const Duration(seconds: 45)); // Use a longer timeout for uploads
      // Convert the streamed response to a standard HTTP response
      var response = await http.Response.fromStream(streamedResponse);

      print("[Provider] createTestimonial - API Response Status: ${response.statusCode}");
      print("[Provider] createTestimonial - API Response Body: ${response.body}"); // Log full body for debugging

      // Handle the HTTP response status code
      if (response.statusCode == 201 || response.statusCode == 200) { // Check for 200 OK or 201 Created (common success codes)
        print("[Provider] createTestimonial - Testimonial creation successful.");
        _isLoading = false; // Stop loading
        _error = null; // Clear error on success
        notifyListeners(); // Notify listeners of success state change

        // Optionally, refresh the list of testimonials after successful creation
        // Note: If your API only returns 'approved' testimonials via fetchTestimonials,
        // the newly created 'pending' testimonial won't appear until approved.
        // If you need to show it immediately, you'd need a different fetch endpoint
        // or add it to the local list (less accurate if sorting/filtering applied on backend).
        await fetchTestimonials(forceRefresh: true); // Refresh the displayed list (fetches approved only)

        return true; // Indicate success
      } else {
        // Handle non-success HTTP status codes (like 401 Unauthorized, 400 Bad Request, 500 Internal Error, etc.)
        String errorMessage = "$_failedToCreateTestimonialMessage. Status: ${response.statusCode}";
        // Attempt to parse a specific error message from the response body if it's JSON
        try {
            final errorData = json.decode(response.body);
            if (errorData is Map && errorData.containsKey('message') && errorData['message'] != null) {
              // Use the specific message from the backend if available
              errorMessage = errorData['message'].toString();
            } else {
               // If no 'message' key or not JSON, include status and body snippet in error
               final bodySnippet = response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body;
               errorMessage = "$_failedToCreateTestimonialMessage. Status: ${response.statusCode}, Body: $bodySnippet";
            }
        } catch(e) {
             // Catch errors if the body is not valid JSON
            errorMessage = "$_failedToCreateTestimonialMessage. Status: ${response.statusCode}. Could not parse error details from response body.";
        }
        _error = errorMessage; // Set the specific or generic error message
        _isLoading = false; // Stop loading
        notifyListeners(); // Notify listeners of the error state
        print("[Provider] createTestimonial - HTTP Error: $_error");
        return false; // Indicate failure
      }
    } on TimeoutException {
      // Handle request timeout exception
      _error = _timeoutErrorMessage;
      _isLoading = false;
      notifyListeners();
      print("[Provider] createTestimonial - TimeoutException caught.");
      return false; // Indicate failure
    } on SocketException {
      // Handle network connectivity errors (no internet, server unreachable, etc.)
      _error = _networkErrorMessage;
      _isLoading = false;
      notifyListeners();
      print("[Provider] createTestimonial - SocketException caught.");
      return false; // Indicate failure
    } on http.ClientException catch (e) {
       // Handle other client-side HTTP errors (e.g., invalid URL)
       _error = "$_networkErrorMessage: ${e.message}"; // Include specific client error message
       _isLoading = false;
       notifyListeners();
       print("[Provider] createTestimonial - ClientException caught: ${e.message}");
       return false; // Indicate failure
    }
    catch (e, s) {
      // Catch any other unexpected exceptions (e.g., assertion errors, null pointer issues within this method)
      _isLoading = false; // Stop loading
      _error = "$_unexpectedErrorMessage (Create): ${e.toString()}"; // Include exception details
      notifyListeners(); // Notify listeners of the error state
      print("[Provider] createTestimonial - Generic Exception caught: $e\n$s"); // Log exception and stack trace
      return false; // Indicate failure
    }
  }

  // --- Method to clear the current error state ---
  void clearError() {
    if (_error != null) {
      _error = null; // Set error to null
      notifyListeners(); // Notify listeners that error is cleared
      print("[Provider] clearError called.");
    }
  }

   // --- Method to clear the list of testimonials and reset state ---
  void clearTestimonials() {
    _testimonials = []; // Clear the list
    _error = null; // Clear any error
    _isLoading = false; // Ensure loading is false
    notifyListeners(); // Notify listeners of the reset state
    print("[Provider] clearTestimonials called.");
  }
}