import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_app/constants/api.dart';
import '../../models/question_model.dart';
import '../../models/result_model.dart';

class QuestionService {
  Future<List<Question>> fetchQuestions(
      int chapterId, int subjectId, String type) async {
    final response = await http.get(Uri.parse(
        '${Network.questionApi2}/api/questions/chapter/$chapterId/subject/$subjectId/type/$type'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => Question.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      throw ('No questions found for this chapter and subject.');
    } else if (response.statusCode == 500) {
      throw ('Internal server error. Please try again.');
    } else {
      throw ('Failed to load questions. Status code: ${response.statusCode}');
    }
  }

  Future<void> submitResult(Result result) async {
    final response = await http.post(
      Uri.parse('${Network.questionApi2}/api/results'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(result.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Result submitted successfully.');
    } else if (response.statusCode == 409) {
      throw ('⚠️ Result already exists for this user');
    } else {
      throw ('❌ Failed to submit result. Status code: ${response.statusCode}');
    }
  }
}
