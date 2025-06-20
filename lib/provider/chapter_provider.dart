import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:mgw_tutorial/models/chapter.dart';
import 'package:mgw_tutorial/services/database_helper.dart';

class ChapterProvider with ChangeNotifier {
  final Map<int, List<Chapter>> _chaptersCache = {};
  final Map<int, bool> _loadingStatus = {};
  final Map<int, String?> _errorMessages = {};

  bool isLoading(int subjectId) => _loadingStatus[subjectId] ?? false;
  String? getErrorMessage(int subjectId) => _errorMessages[subjectId];
  List<Chapter>? getChapters(int subjectId) => _chaptersCache[subjectId];

  final String _baseApiUrl =
      "https://courseservice.mgwcommunity.com/api/chapters/subject/";
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchChaptersForSubject(int subjectId,
      {bool forceRefresh = false}) async {
    _loadingStatus[subjectId] = true;
    _errorMessages[subjectId] = null;
    notifyListeners();

    // Check SQLite cache first
    final cached = await _dbHelper.query('chapters',
        where: 'subjectId = ?', whereArgs: [subjectId], orderBy: '"order" ASC');
    if (cached.isNotEmpty && !forceRefresh) {
      _chaptersCache[subjectId] =
          cached.map((e) => Chapter.fromJson(e)).toList();
      _loadingStatus[subjectId] = false;
      _errorMessages[subjectId] = null;
      notifyListeners();
      return;
    }

    // If forceRefresh or no cache, try API
    if (forceRefresh || cached.isEmpty) {
      try {
        final url = '$_baseApiUrl$subjectId';
        final response =
            await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            List<dynamic> chaptersJson = responseData['data'];
            List<Chapter> fetchedChapters =
                chaptersJson.map((json) => Chapter.fromJson(json)).toList();

            fetchedChapters.sort((a, b) => a.order.compareTo(b.order));
            _chaptersCache[subjectId] = fetchedChapters;

            // Cache in SQLite
            for (var chapter in fetchedChapters) {
              await _dbHelper.upsert('chapters', {
                'id': chapter.id,
                'name': chapter.name,
                'description': chapter.description,
                'status': chapter.status,
                'subjectId': chapter.subjectId,
                'order': chapter.order,
              });
            }
          } else {
            _errorMessages[subjectId] =
                'Unable to load chapters. Please try again later.';
            _chaptersCache[subjectId] = cached.isNotEmpty
                ? cached.map((e) => Chapter.fromJson(e)).toList()
                : [];
          }
        } else {
          _errorMessages[subjectId] =
              'Unable to load chapters. Please check your connection.';
          _chaptersCache[subjectId] = cached.isNotEmpty
              ? cached.map((e) => Chapter.fromJson(e)).toList()
              : [];
        }
      } catch (e) {
        if (e is SocketException || e is TimeoutException) {
          _errorMessages[subjectId] = cached.isNotEmpty
              ? null
              : 'No internet connection. Please connect and try again.';
          _chaptersCache[subjectId] = cached.isNotEmpty
              ? cached.map((e) => Chapter.fromJson(e)).toList()
              : [];
        } else {
          _errorMessages[subjectId] = 'Error fetching chapters: $e';
          _chaptersCache[subjectId] = cached.isNotEmpty
              ? cached.map((e) => Chapter.fromJson(e)).toList()
              : [];
        }
      }
    }

    _loadingStatus[subjectId] = false;
    notifyListeners();
  }

  Future<void> clearChapters() async {
    _chaptersCache.clear();
    _loadingStatus.clear();
    _errorMessages.clear();
    await _dbHelper.delete('chapters');
    notifyListeners();
  }
}
