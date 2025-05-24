import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/game_leader_model.dart';
import '../../../constants/api.dart';

class GameLeaderService {
  /// Fetches the overall leaderboard
  Future<List<GameLeader>> fetchLeaderboard() async {
    return await _fetchLeaderboard(
        '${Network.questionApi2}/api/game-results/leaderboard');
  }

  /// Fetches the leaderboard by subject ID
  Future<List<GameLeader>> fetchLeaderboardBySubjectId(int subjectId) async {
    return await _fetchLeaderboard(
        '${Network.questionApi2}/api/game-results/leaderboard/subject/$subjectId');
  }

  /// Private method to handle leaderboard fetching
  Future<List<GameLeader>> _fetchLeaderboard(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      switch (response.statusCode) {
        case 200:
          List<dynamic> data = json.decode(response.body)['data'];
          return data.map((json) => GameLeader.fromJson(json)).toList();

        case 400:
          throw Exception(
              "Bad Request: The request was invalid or cannot be processed.");

        case 401:
          throw Exception(
              "Unauthorized: Please check your authentication credentials.");

        case 403:
          throw Exception(
              "Forbidden: You don’t have permission to access this resource.");

        case 404:
          return []; // Return empty list if no leaderboard data is found

        case 500:
          throw Exception(
              "Internal Server Error: Something went wrong on the server.");

        default:
          throw Exception("Unexpected Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network Error: Unable to fetch leaderboard data. $e");
    }
  }
}
