// lib/provider/order_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Import XFile
import 'package:mgw_tutorial/models/order.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType

class OrderProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Order? _lastCreatedOrder;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get lastCreatedOrder => _lastCreatedOrder;

  static const String _apiBaseUrl = "https://adminservicefx.amtprinting19.com/api";

  // Modify createOrder to accept XFile
  Future<bool> createOrder({
    required Order orderData, // Contains all non-file data
    XFile? screenshotFile,   // The image file
  }) async {
    _isLoading = true;
    _error = null;
    _lastCreatedOrder = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/orders');
    
    try {
      var request = http.MultipartRequest('POST', url);

      // Add text fields from orderData.toJsonForApi()
      // Note: The API might expect all fields as strings in multipart.
      // If so, you might need to convert numbers/booleans to strings here.
      Map<String, dynamic> orderFields = orderData.toJsonForApi();
      orderFields.forEach((key, value) {
        // The 'screenshot' field from toJsonForApi might be a path or null,
        // we are sending the actual file below, so we can choose to exclude it here
        // or ensure the backend can handle both a 'screenshot' text field and a file.
        // For now, let's assume the backend primarily looks for the file part.
        if (key != 'screenshot' && value != null) { // Exclude null values and the text 'screenshot' field
             request.fields[key] = value.toString(); // Ensure value is a string
        }
      });
      
      print('Order Multipart Request Fields: ${request.fields}');


      // Add the screenshot file if it exists
     /*  if (screenshotFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'screenshot', // This is the field name the backend expects for the file
            screenshotFile.path,
            contentType: MediaType('image', screenshotFile.path.split('.').last), // e.g., image/jpeg, image/png
          ),
        );
        print('Order Multipart Request File: ${screenshotFile.name}');
      } else {
        print('Order Multipart Request: No screenshot file provided.');
        // If screenshot is mandatory, you might want to return false here or handle it.
        // Or, if the API allows orders without screenshots, this is fine.
        // The 'screenshot' field in request.fields will be null or absent if not in toJsonForApi
      } */
      
      // Add headers if needed
      // request.headers.addAll({
      //   "Accept": "application/json",
      //   // "Authorization": "Bearer YOUR_ADMIN_TOKEN_IF_NEEDED",
      // });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Order Creation Response (Multipart): ${response.statusCode} ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _lastCreatedOrder = Order.fromJson(responseData);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Failed to create order. Status: ${response.statusCode}. Body: ${response.body}";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "An exception occurred while creating order: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    // notifyListeners();
  }
}