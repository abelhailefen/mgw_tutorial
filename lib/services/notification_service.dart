// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/blog.dart'; // CORRECTED import path

class NotificationService {
  final String _baseUrl = "https://usersservicefx.amtprinting19.com/api";

  Future<List<Blog>> fetchNotifications() async {
    try {
      final url = Uri.parse('$_baseUrl/notification');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        List<Blog> notifications = body.map((dynamic item) => Blog.fromJson(item)).toList();
        notifications.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
        return notifications;
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to load notifications');
    }
  }
}