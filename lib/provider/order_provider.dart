// lib/provider/order_provider.dart
import 'dart:convert';
import 'dart:io'; // For SocketException
import 'dart:async'; // For TimeoutException
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mgw_tutorial/models/order.dart'; // Ensure this is your AppOrder.Order
import 'package:http_parser/http_parser.dart';

class OrderProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Order? _lastCreatedOrder;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get lastCreatedOrder => _lastCreatedOrder;

  static const String _apiBaseUrl = "https://adminservicefx.amtprinting19.com/api";

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while creating the order. Please try again later.";
  static const String _failedToCreateOrderMessage = "Failed to create order. Please try again.";


  Future<bool> createOrder({
    required Order orderData,
    XFile? screenshotFile, // This is the XFile from image_picker
  }) async {
    _isLoading = true;
    _error = null;
    _lastCreatedOrder = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/orders');
    print("Creating order at URL: $url");

    try {
      var request = http.MultipartRequest('POST', url);

      Map<String, String> orderFields = orderData.toJsonForApiFields();
      request.fields.addAll(orderFields);
      
      print('Order Multipart Request Fields: ${request.fields}');

      if (screenshotFile != null) {
        String fileExtension = screenshotFile.path.split('.').last.toLowerCase();
        MediaType? contentType;
        if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExtension == 'png') {
          contentType = MediaType('image', 'png');
        } else if (fileExtension == 'jfif') {
            contentType = MediaType('image', 'jpeg'); // Commonly treated as jpeg
        }
        // Add more types if needed, or a generic 'application/octet-stream'

        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // <<< CHANGED FROM 'screenshot' TO 'image'
            screenshotFile.path,
            contentType: contentType,
            filename: screenshotFile.name, 
          ),
        );
        print('Order Multipart Request File: ${screenshotFile.name} (Field: image), Type: ${contentType?.toString()}');
      } else {
        print('Order Multipart Request: No screenshot file provided.');
        // Backend will decide if this is an error.
      }
      
      // Add headers if your API requires them (e.g., Authorization)
      // request.headers.addAll({
      //   "Accept": "application/json",
      //   // "Authorization": "Bearer YOUR_TOKEN_HERE", 
      // });

      var streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);

      print('Order Creation Response Status: ${response.statusCode}');
      print('Order Creation Response Body: ${response.body}'); // Log the full body for debugging

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('order')) {
            _lastCreatedOrder = Order.fromJson(responseData['order'] as Map<String, dynamic>);
        } else {
            _lastCreatedOrder = Order.fromJson(responseData as Map<String, dynamic>);
        }
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleHttpErrorResponse(response, _failedToCreateOrderMessage);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException catch (e) {
      print("TimeoutException creating order: $e");
      _error = _timeoutErrorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      print("SocketException creating order: $e");
      _error = _networkErrorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } on http.ClientException catch (e) {
      print("ClientException creating order: $e");
      _error = _networkErrorMessage; // Or a more specific client error message
      _isLoading = false;
      notifyListeners();
      return false;
    }
    catch (e, s) {
      print("Generic Exception during createOrder: $e");
      print("Stacktrace: $s");
      _error = _unexpectedErrorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _handleHttpErrorResponse(http.Response response, String defaultUserMessage) {
    // If the response is HTML (like the MulterError page), don't try to json.decode it.
    if (response.headers['content-type']?.toLowerCase().contains('text/html') ?? false) {
        _error = "$defaultUserMessage (Status: ${response.statusCode}). Server returned an unexpected HTML response. Please check server logs.";
        print("Server returned HTML error page: ${response.body.substring(0, (response.body.length > 300 ? 300 : response.body.length))}"); // Log snippet
        return;
    }
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
        _error = errorBody['message'].toString();
      } else {
        _error = "$defaultUserMessage (Status: ${response.statusCode})";
      }
    } catch (e) {
      _error = "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable. Body: ${response.body.substring(0, (response.body.length > 200 ? 200 : response.body.length))}";
    }
  }

  void clearError() {
    _error = null;
  }
}