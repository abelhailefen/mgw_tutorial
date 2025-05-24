import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_result_model.dart';
import 'package:video_app/constants/api.dart';

class UserResultService {
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      throw Exception('User ID not found in SharedPreferences');
    }
    print("Debug: Retrieved User ID from SharedPreferences: $userId"); // Debug
    return userId;
  }

  Future<List<UserResult>> fetchResultsBySubject(int subjectId) async {
    final userId = await _getUserId();

    // Debugging prints
    print("Debug: Fetching results for User ID: $userId and Subject ID: $subjectId");

    final response = await http.get(Uri.parse(
        '${Network.questionApi2}/api/results/subject/$subjectId/user/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      print("Debug: API Response for Subject Results: $jsonResponse"); // Debug
      if (jsonResponse.isEmpty) {
        throw ('No exam results found');
      }
      return jsonResponse.map((data) => UserResult.fromJson(data)).toList();
    } else {
      print("Debug: API Error - Status Code: ${response.statusCode}, Body: ${response.body}"); // Debug
      throw Exception('Failed to load results');
    }
  }
}