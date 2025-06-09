import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:mgw_tutorial/models/subject.dart';
import 'package:mgw_tutorial/services/database_helper.dart';
import 'package:path/path.dart' as path;

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _subjectsApiUrl = "https://courseservice.anbesgames.com/api/subjects";
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchSubjects({bool forceRefresh = false}) async {
    print("SubjectProvider: fetchSubjects called (forceRefresh: $forceRefresh)");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Load cached subjects from database
    List<Subject> cachedSubjects = [];
    try {
      final List<Map<String, dynamic>> cached = await _dbHelper.query('subjects');
      cachedSubjects = cached.map((e) => Subject.fromJson(e)).toList();
      print("SubjectProvider: Loaded ${cachedSubjects.length} subjects from DB.");

      if (cachedSubjects.isNotEmpty && !forceRefresh) {
        // Validate local image paths
        cachedSubjects = cachedSubjects.map((subject) {
          if (subject.localImagePath != null) {
            final file = File(subject.localImagePath!);
            if (!file.existsSync()) {
              print("SubjectProvider: Local image missing for subject ${subject.id}. Setting to null.");
              return Subject(
                id: subject.id,
                name: subject.name,
                category: subject.category,
                year: subject.year,
                imageUrl: subject.imageUrl,
                localImagePath: null,
              );
            }
          }
          return subject;
        }).toList();
        _subjects = cachedSubjects;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return;
      }
    } catch (e) {
      print("SubjectProvider: Error loading subjects from DB: $e");
    }

    // Perform network fetch if forced refresh or no cached data
    if (forceRefresh || cachedSubjects.isEmpty) {
      try {
        final response = await http.get(Uri.parse(_subjectsApiUrl)).timeout(Duration(seconds: 30));
        print("SubjectProvider: Network Response Status: ${response.statusCode}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          List<Subject> fetchedSubjects = [];

          if (responseData.containsKey('data') && responseData['data'] is List) {
            List<dynamic> subjectsJson = responseData['data'];
            fetchedSubjects = subjectsJson.map((json) => Subject.fromJson(json)).toList();

            // Download and save images
            fetchedSubjects = await _downloadAndSaveImages(fetchedSubjects);
            print("SubjectProvider: Finished image download/save process.");

            // Save to database
            await _saveSubjectsToDb(fetchedSubjects, cachedSubjects);
            print("SubjectProvider: Subjects saved to DB successfully.");

            _subjects = fetchedSubjects;
            _errorMessage = null;
          } else {
            _errorMessage = 'Unable to load subjects. Please try again later.';
            _subjects = cachedSubjects;
          }
        } else {
          _errorMessage = 'Unable to load subjects. Please check your connection.';
          _subjects = cachedSubjects;
        }
      } catch (e) {
        if (e is SocketException || e is TimeoutException) {
          _errorMessage = cachedSubjects.isNotEmpty ? null : 'No internet connection. Please connect and try again.';
          _subjects = cachedSubjects;
        } else {
          _errorMessage = 'Error fetching subjects: $e';
          _subjects = cachedSubjects;
        }
        print("SubjectProvider: Error fetching subjects: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
        print("SubjectProvider: Fetch process finished. isLoading=$_isLoading, error=$_errorMessage, subjectsCount=${_subjects.length}");
      }
    }

    // Re-download images for cached subjects if missing
    if (_subjects.isNotEmpty && !forceRefresh) {
      _subjects = await _downloadAndSaveImages(_subjects);
      await _saveSubjectsToDb(_subjects, _subjects);
    }
  }

  Future<List<Subject>> _downloadAndSaveImages(List<Subject> subjects) async {
    if (subjects.isEmpty) {
      print("SubjectProvider: No subjects to download images for.");
      return subjects;
    }
    final imageDir = await _dbHelper.getThumbnailDirectory();
    final client = http.Client();
    int downloadedCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    List<Subject> updatedSubjects = [];

    try {
      for (final subject in subjects) {
        final imageUrl = subject.imageUrl;
        if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
          try {
            Uri uri = Uri.parse(imageUrl);
            String fileExtension = 'jpg';
            String pathSegment = uri.path;
            int lastDot = pathSegment.lastIndexOf('.');
            if (lastDot != -1 && pathSegment.length > lastDot + 1) {
              fileExtension = pathSegment.substring(lastDot + 1).split('?').first;
            }

            final fileName = 'subject_${subject.id}_image.$fileExtension';
            final localPath = path.join(imageDir.path, fileName);
            final localFile = File(localPath);

            if (await localFile.exists()) {
              updatedSubjects.add(Subject(
                id: subject.id,
                name: subject.name,
                category: subject.category,
                year: subject.year,
                imageUrl: subject.imageUrl,
                localImagePath: localPath,
              ));
              skippedCount++;
              continue;
            }

            print("SubjectProvider: Downloading image for subject ${subject.id} from $imageUrl");
            final response = await client.get(uri).timeout(Duration(seconds: 15));

            if (response.statusCode == 200) {
              await localFile.writeAsBytes(response.bodyBytes);
              updatedSubjects.add(Subject(
                id: subject.id,
                name: subject.name,
                category: subject.category,
                year: subject.year,
                imageUrl: subject.imageUrl,
                localImagePath: localPath,
              ));
              downloadedCount++;
              print("SubjectProvider: Saved image for subject ${subject.id} to $localPath");
            } else {
              print("SubjectProvider: Failed to download image for subject ${subject.id} (Status: ${response.statusCode})");
              updatedSubjects.add(Subject(
                id: subject.id,
                name: subject.name,
                category: subject.category,
                year: subject.year,
                imageUrl: subject.imageUrl,
                localImagePath: null,
              ));
              failedCount++;
            }
          } catch (e) {
            print("SubjectProvider: Error downloading image for subject ${subject.id} ($imageUrl): $e");
            updatedSubjects.add(Subject(
              id: subject.id,
              name: subject.name,
              category: subject.category,
              year: subject.year,
              imageUrl: subject.imageUrl,
              localImagePath: null,
            ));
            failedCount++;
          }
        } else {
          print("SubjectProvider: No valid image URL for subject ${subject.id}");
          updatedSubjects.add(Subject(
            id: subject.id,
            name: subject.name,
            category: subject.category,
            year: subject.year,
            imageUrl: subject.imageUrl,
            localImagePath: null,
          ));
          skippedCount++;
        }
      }
    } finally {
      client.close();
      print("SubjectProvider: Image download summary: Downloaded $downloadedCount, Skipped $skippedCount, Failed $failedCount.");
    }
    return updatedSubjects;
  }

  Future<void> _saveSubjectsToDb(List<Subject> subjectsToSave, List<Subject> cachedSubjects) async {
    print("SubjectProvider: Starting DB save process...");
    try {
      final db = await _dbHelper.database;
      List<String> oldImagePaths = [];
      List<String> newSubjectIds = subjectsToSave.map((s) => s.id.toString()).toList();

      await db.transaction((txn) async {
        oldImagePaths = await _dbHelper.getOldSubjectImagePathsInTxn(txn);
        await txn.delete('subjects', where: 'id NOT IN (${newSubjectIds.map((_) => '?').join(',')})', whereArgs: newSubjectIds);
      });
      print("SubjectProvider: Deleted subjects not in new data. ${oldImagePaths.length} paths collected.");

      if (oldImagePaths.isNotEmpty) {
        List<String> imagesToDelete = oldImagePaths.where((path) {
          final fileName = path.split('/').last;
          final subjectId = fileName.split('_')[1];
          return !newSubjectIds.contains(subjectId);
        }).toList();
        print("SubjectProvider: Deleting ${imagesToDelete.length} old image files...");
        await _dbHelper.deleteThumbnailFiles(imagesToDelete);
      }

      await db.transaction((txn) async {
        await _dbHelper.insertSubjectsInTxn(txn, subjectsToSave);
      });
      print("SubjectProvider: New subjects saved to DB successfully.");
    } catch (e) {
      print("SubjectProvider: Error during _saveSubjectsToDb: $e");
      rethrow;
    }
  }

  Future<void> clearSubjects() async {
    print("SubjectProvider: clearSubjects called.");
    final db = await _dbHelper.database;
    List<String> oldImagePaths = [];
    await db.transaction((txn) async {
      oldImagePaths = await _dbHelper.getOldSubjectImagePathsInTxn(txn);
      await _dbHelper.deleteSubjectsInTxn(txn);
    });
    if (oldImagePaths.isNotEmpty) {
      await _dbHelper.deleteThumbnailFiles(oldImagePaths);
      print("SubjectProvider: Deleted ${oldImagePaths.length} old image files.");
    }
    _subjects = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    print("SubjectProvider: Dispose called.");
    _dbHelper.close();
    super.dispose();
  }
}