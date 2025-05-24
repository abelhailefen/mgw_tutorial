import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/api.dart';
import '../../models/subject_model.dart';

class SubjectService {
  Future<List<Subject>> fetchSubjects() async {
    try {
      final response =
          await http.get(Uri.parse('${Network.questionApi2}/api/subjects'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List subjects = data['data'];
        return subjects.map((json) => Subject.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw "No subjects found.";
      } else if (response.statusCode == 500) {
        throw "Internal server error. Please try again later.";
      } else {
        throw "Unexpected error occurred. Status Code: ${response.statusCode}";
      }
    } catch (e) {
      // Rethrow the error message as a string (not an Exception)
      rethrow;
    }
  }
}
