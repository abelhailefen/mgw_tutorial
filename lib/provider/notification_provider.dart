// lib/provider/notification_provider.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/blog.dart'; // CORRECTED import path
import 'package:mgw_tutorial/services/notification_service.dart'; // CORRECTED import path

class NotificationProvider extends ChangeNotifier {
  List<Blog> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Blog> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final NotificationService _notificationService = NotificationService();

  NotificationProvider() {
    // Automatically fetch notifications when the provider is created
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _notifications = await _notificationService.fetchNotifications();
    } catch (e) {
      print("Error loading notifications: $e");
      _errorMessage = "Failed to load notifications. Please try again."; // TODO: Localize
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}