import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/leader_subject_model.dart';
import 'package:video_app/constants/api.dart';

class LeaderSubjectService {
  Future<List<LeaderSubject>> fetchLeaderboardBySubject(int subjectId) async {
    final response = await http.get(
        Uri.parse('${Network.questionApi2}/api/results/leaderboard/subject/$subjectId'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => LeaderSubject.fromJson(data)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('No users found for this subject');
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  Future<List<LeaderSubject>> fetchLeaderboardByChapter(
      int subjectId, int chapterId) async {
    final response = await http.get(Uri.parse(
        '${Network.questionApi2}/api/results/leaderboard/subject/$subjectId/chapter/$chapterId'));
 print("Fetching leaderboard for subjectId: $subjectId"); // Debug
  print("Response: ${response.body}");
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => LeaderSubject.fromJson(data)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('No users found for this chapter');
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  Future<UserDetails> fetchUserDetails(int userId) async {
    final response =
        await http.get(Uri.parse('https://userservice.zsecreteducation.com/api/users/$userId'));
  print("Fetching user details for user_id: $userId"); // Debug
  print("Response: ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return UserDetails.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load user details');
    }
  }
}