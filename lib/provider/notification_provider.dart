// lib/provider/notification_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import json decoding
import 'package:mgw_tutorial/models/blog.dart'; // Use Blog model for notification data
// Removed: import 'package:mgw_tutorial/services/notification_service.dart'; // NotificationService is removed

class NotificationProvider extends ChangeNotifier {
  List<Blog> _notifications = []; // Use Blog model to hold notification data
  bool _isLoading = false;
  String? _errorMessage;

  List<Blog> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Hardcoded Base URL
  final String _baseUrl = "https://mgw-backend.onrender.com/api";

  NotificationProvider() {
    // Automatically fetch notifications when the provider is created
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify listeners that loading has started

    try {
      // Construct the full URL using the hardcoded base URL and the endpoint
      final url = Uri.parse('$_baseUrl/notifications'); // Using the new /notifications endpoint
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        // Map the dynamic list to a list of Blog objects
        // Using Blog.fromJson works as the structure is compatible
        List<Blog> notifications = body.map((dynamic item) => Blog.fromJson(item)).toList();

        // Sort by creation date, newest first (optional but good for notifications)
        notifications.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

        _notifications = notifications; // Update the state with fetched notifications
         print("Fetched ${_notifications.length} notifications successfully."); // Debug print

      } else {
        // Handle non-200 responses
        print('Failed to load notifications: ${response.statusCode}');
        print('Response body: ${response.body}');
        // TODO: Localize this message
        _errorMessage = 'Failed to load notifications: ${response.statusCode}';
        _notifications = []; // Clear list on error
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error fetching notifications: $e');
       // TODO: Localize this message
      _errorMessage = "An error occurred while fetching notifications."; // More general error message
      _notifications = []; // Clear list on error
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading has finished (or error occurred)
    }
  }

  
}