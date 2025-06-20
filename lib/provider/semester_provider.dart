import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/db/semister_db.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SemesterProvider with ChangeNotifier {
  List<Semester> _semesters = [];
  bool _isLoading = false;
  String? _error;

  List<Semester> get semesters => [..._semesters];
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _networkErrorMessage =
      "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage =
      "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage =
      "An unexpected error occurred while fetching semesters. Please try again later.";
  static const String _failedToLoadSemestersMessage =
      "Failed to load semesters. Please try again.";

  static const String _apiBaseUrl =
      "https://courseservice.anbesgames.com/api";

  final SemesterDB _semesterDb = SemesterDB();

  Future<void> fetchSemesters({bool forceRefresh = false}) async {
    print('[SemesterProvider] fetchSemesters called. forceRefresh: $forceRefresh');
    if (!forceRefresh && _semesters.isNotEmpty && !_isLoading) {
      print('[SemesterProvider] Semesters already loaded and not forcing refresh. Skipping fetch.');
      return;
    }

    _isLoading = true;
    print('[SemesterProvider] Loading started');
    if (forceRefresh || _semesters.isEmpty) {
      _error = null;
      print('[SemesterProvider] Error cleared due to forceRefresh or initial load');
    }
    if (forceRefresh) {
      _semesters = [];
      print('[SemesterProvider] Semesters list cleared for forceRefresh');
    }
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    print('[SemesterProvider] Connectivity check: $connectivityResult, isOnline: $isOnline');

    if (!isOnline) {
      // OFFLINE: Load from local DB
      print('[SemesterProvider] Offline detected. Loading semesters from local SQLite DB...');
      try {
        final cachedSemesters = await _semesterDb.getSemesters();
        print('[SemesterProvider] Loaded ${cachedSemesters.length} semesters from SQLite.');
        if (cachedSemesters.isNotEmpty) {
          _semesters = cachedSemesters;
          _error = null;
        } else {
          _error = "No cached data available. Please connect to the internet to load semesters.";
          _semesters = [];
          print('[SemesterProvider] No cached semesters found.');
        }
      } catch (e) {
        _error = "Failed to load local data: $e";
        _semesters = [];
        print('[SemesterProvider] Error loading semesters from SQLite: $e');
      } finally {
        _isLoading = false;
        print('[SemesterProvider] Loading finished (offline)');
        notifyListeners();
      }
      return;
    }

    // ONLINE: Fetch from API as before
    final url = Uri.parse('$_apiBaseUrl/semesters');
    print("[SemesterProvider] Fetching semesters from: $url (Force Refresh: $forceRefresh)");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 20));

      print("[SemesterProvider] Semesters API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        print("[SemesterProvider] API returned ${extractedData.length} semesters.");
        if (extractedData is List) {
          _semesters = extractedData
              .map((semesterJson) => Semester.fromJson(semesterJson as Map<String, dynamic>))
              .toList();
          _error = null;
          // --- Cache to DB ---
          print('[SemesterProvider] Caching semesters to SQLite...');
          await _semesterDb.clearSemesters();
          await _semesterDb.insertSemesters(_semesters);
          print('[SemesterProvider] Semesters successfully cached to SQLite.');
        } else {
          _error = "Failed to load semesters: Unexpected API response format.";
          _semesters = [];
          print('[SemesterProvider] API response was not a List.');
        }
      } else {
        print('[SemesterProvider] API response status not 200. Handling error.');
        _handleHttpErrorResponse(response, _failedToLoadSemestersMessage);
      }
    } on TimeoutException catch (e) {
      print("[SemesterProvider] TimeoutException fetching semesters: $e");
      _error = _timeoutErrorMessage;
      _semesters = [];
    } on SocketException catch (e) {
      print("[SemesterProvider] SocketException fetching semesters: $e");
      _error = _networkErrorMessage;
      _semesters = [];
    } on http.ClientException catch (e) {
      print("[SemesterProvider] ClientException fetching semesters: $e");
      _error = _networkErrorMessage;
      _semesters = [];
    } catch (e) {
      print("[SemesterProvider] Generic Exception during fetchSemesters: $e");
      _error = _unexpectedErrorMessage;
      _semesters = [];
    } finally {
      _isLoading = false;
      print('[SemesterProvider] Loading finished (online/API)');
      notifyListeners();
    }
  }

  void _handleHttpErrorResponse(http.Response response, String defaultUserMessage) {
    print('[SemesterProvider] Handling HTTP error response. Status: ${response.statusCode}');
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map &&
          errorBody.containsKey('message') &&
          errorBody['message'] != null &&
          errorBody['message'].toString().isNotEmpty) {
        _error = errorBody['message'].toString();
        print('[SemesterProvider] Error message from API: ${_error}');
      } else {
        _error = "$defaultUserMessage (Status: ${response.statusCode})";
        print('[SemesterProvider] No message in error body, using default error.');
      }
    } catch (e) {
      _error =
          "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.";
      print('[SemesterProvider] Error body not parsable: $e');
    }
    _semesters = [];
  }

  void clearError() {
    _error = null;
    print('[SemesterProvider] Error cleared');
  }

  void clearSemesters() {
    _semesters = [];
    _error = null;
    print('[SemesterProvider] Semesters and error cleared');
    notifyListeners();
  }
}