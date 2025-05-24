import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/chapter_model.dart';
import '../../../constants/api.dart';

class ChapterService {
  Future<List<Chapter>> fetchChaptersBySubjectId(int subjectId) async {
    try {
      final response = await http.get(Uri.parse('${Network.questionApi2}/api/chapters/subject/$subjectId'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Chapter.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw ("No chapters found for this subject.");
      } else if (response.statusCode == 500) {
        throw ("Internal server error. Please try again later.");
      } else {
        throw ("Unexpected error occurred. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      // Instead of wrapping the exception, just rethrow it to avoid duplicate errors
      rethrow;
    }
  }
}
