// lib/provider/notification_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mgw_tutorial/models/blog.dart'; // Use Blog model for notification data

class NotificationProvider extends ChangeNotifier {
  List<Blog> _notifications = []; // Use Blog model to hold notification data
  bool _isLoading = false;
  String? _errorMessage;

  List<Blog> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Hardcoded Base URL
  final String _baseUrl = "https://courseservice.anbesgames.com/api"; // New Base URL

  NotificationProvider() {
    // Automatically fetch notifications when the provider is created
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/notifications'); // New /notifications endpoint
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        List<Blog> notifications = body.map((dynamic item) => Blog.fromJson(item)).toList();

        notifications.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

        _notifications = notifications;
         print("Fetched ${_notifications.length} notifications successfully from $_baseUrl/notifications");

      } else {
        print('Failed to load notifications: ${response.statusCode}');
        print('Response body: ${response.body}');
        _errorMessage = 'Failed to load notifications: ${response.statusCode}'; // TODO: Localize
        _notifications = [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      _errorMessage = "An error occurred while fetching notifications."; // TODO: Localize
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}