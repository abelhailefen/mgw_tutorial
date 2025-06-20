import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/testimonial.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart'; // For BuildContext if needed, though generally avoid UI

class TestimonialProvider with ChangeNotifier {
  List<Testimonial> _testimonials = [];
  bool _isLoading = false;
  String? _error;

  List<Testimonial> get testimonials => [..._testimonials];
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String apiBaseUrl = "https://courseservice.mgwcommunity.com/api";

  static const String _networkErrorMessage =
      "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage =
      "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadMessage = "Failed to load testimonials.";
  static const String _failedToCreateTestimonialMessage =
      "Failed to submit testimonial.";

  Future<void> fetchTestimonials({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    if (forceRefresh || _testimonials.isEmpty) {
      _testimonials = [];
    }

    String apiUrl = '$apiBaseUrl/testimonials/approved';
    final url = Uri.parse(apiUrl);

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
        // Add Authentication header if needed for fetching (e.g., if fetching requires user ID)
        // "X-User-ID": userId.toString(), // Example if needed here too
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        if (decodedData is List) {
          _testimonials = decodedData
              .map((testimonialJson) {
                try {
                  return Testimonial.fromJson(
                      testimonialJson as Map<String, dynamic>);
                } catch (e) {
                  // Log individual item parsing error if needed
                  return null;
                }
              })
              .whereType<Testimonial>()
              .toList();

          _testimonials.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _error = null;
        } else {
          _error =
              '$_failedToLoadMessage: API response was not a list as expected.';
          _testimonials = [];
        }
      } else {
        String errorMessage =
            '$_failedToLoadMessage. Status: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map &&
              errorData.containsKey('message') &&
              errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          // Ignore JSON parsing error if response wasn't JSON
        }
        _error = errorMessage;
        _testimonials = [];
      }
    } on TimeoutException {
      _error = _timeoutErrorMessage;
      _testimonials = [];
    } on SocketException {
      _error = _networkErrorMessage;
      _testimonials = [];
    } on FormatException {
      _error = "$_failedToLoadMessage: Could not parse server response.";
      _testimonials = [];
    } on http.ClientException catch (e) {
      _error = "$_networkErrorMessage: ${e.message}";
      _testimonials = [];
    } catch (e, s) {
      _error = _unexpectedErrorMessage;
      // Log the full exception and stack trace if needed for debugging
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTestimonial({
    required String title,
    required String description,
    required int userId,
    List<XFile>? imageFiles,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (userId <= 0) {
      _error = "Invalid user ID. Please log in again.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final url = Uri.parse('$apiBaseUrl/testimonials');

    try {
      var request = http.MultipartRequest('POST', url);

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['userId'] = userId.toString();
      request.fields['status'] = 'pending';

      // Add Authentication Header
      request.headers['X-User-ID'] = userId.toString();

      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles) {
          String fileExtension = imageFile.path.split('.').last.toLowerCase();
          MediaType? contentType;

          if (fileExtension == 'jpg' ||
              fileExtension == 'jpeg' ||
              fileExtension == 'jfif') {
            contentType = MediaType('image', 'jpeg');
          } else if (fileExtension == 'png') {
            contentType = MediaType('image', 'png');
          } else if (fileExtension == 'gif') {
            contentType = MediaType('image', 'gif');
          } else if (fileExtension == 'webp') {
            contentType = MediaType('image', 'webp');
          } else {
            contentType = MediaType('application', 'octet-stream');
          }

          request.files.add(await http.MultipartFile.fromPath(
            'images', // <-- Field name for your list of images
            imageFile.path,
            contentType: contentType,
            filename: imageFile.name,
          ));
        }
      }

      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        _error = null;
        notifyListeners();
        // Optionally refresh the list if needed (new testimonial won't be approved yet)
        // await fetchTestimonials(forceRefresh: true);
        return true;
      } else {
        String errorMessage =
            "$_failedToCreateTestimonialMessage. Status: ${response.statusCode}";
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map &&
              errorData.containsKey('message') &&
              errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          // Ignore JSON parsing error
        }
        _error = errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException {
      _error = _timeoutErrorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException {
      _error = _networkErrorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } on http.ClientException catch (e) {
      _error = "$_networkErrorMessage: ${e.message}";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, s) {
      _isLoading = false;
      _error = "$_unexpectedErrorMessage (Create): ${e.toString()}";
      notifyListeners();
      // Log the full exception and stack trace if needed for debugging
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
    _isLoading = false;
    notifyListeners();
  }
}
