// lib/provider/section_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/section.dart'; // Import from models
import 'package:mgw_tutorial/services/database_helper.dart'; // Import DatabaseHelper
import 'package:sqflite/sqflite.dart' as sqflite; // Import sqflite with prefix

class SectionProvider with ChangeNotifier {
  final Map<int, List<Section>> _sectionsByCourseId = {};
  final Map<int, bool> _isLoadingForCourseId = {};
  final Map<int, String?> _errorForCourseId = {};
  // Keep track of ongoing fetches to prevent duplicates
  final Map<int, Future<void>> _ongoingFetches = {};

  List<Section> sectionsForCourse(int courseId) =>
      _sectionsByCourseId[courseId] ?? [];
  bool isLoadingForCourse(int courseId) =>
      _isLoadingForCourseId[courseId] ?? false;
  String? errorForCourse(int courseId) => _errorForCourseId[courseId];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _networkErrorMessage =
      "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage =
      "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage =
      "An unexpected error occurred while fetching chapters. Please try again later.";
  static const String _failedToLoadSectionsMessage =
      "Failed to load chapters for this course. Please try again.";

  static const String _apiBaseUrl =
      "https://sectionservice.mgwcommunity.com/api";

  Future<void> fetchSectionsForCourse(int courseId,
      {bool forceRefresh = false}) async {
    // Prevent multiple concurrent fetches for the same course
    if (_ongoingFetches.containsKey(courseId)) {
      print("SectionProvider: Fetch already ongoing for course $courseId.");
      return _ongoingFetches[courseId]!;
    }

    print(
        "SectionProvider: fetchSectionsForCourse called for course $courseId (forceRefresh: $forceRefresh)");

    // Set loading state early if there's no data yet or force refreshing
    bool hasExistingData = _sectionsByCourseId.containsKey(courseId) &&
        _sectionsByCourseId[courseId]!.isNotEmpty;
    bool showLoadingIndicator = forceRefresh || !hasExistingData;

    if (showLoadingIndicator) {
      _isLoadingForCourseId[courseId] = true;
      _errorForCourseId[courseId] = null; // Clear error when starting fetch
      notifyListeners();
      print("SectionProvider: Initial loading state set for course $courseId.");
    } else {
      print(
          "SectionProvider: Showing cached data while fetching for course $courseId. No initial loading indicator.");
    }

    // --- 1. Load from DB (Cache-First Display) ---
    // Always attempt to load from DB immediately to show cached data quickly if available.
    // Only load if we don't already have data in the provider's map or if forcing refresh
    // (in case the data in the map is stale compared to DB).
    if (!hasExistingData || forceRefresh) {
      print(
          "SectionProvider: Attempting to load sections for course $courseId from DB...");
      try {
        final List<Map<String, dynamic>> sectionMaps = await _dbHelper.query(
          'sections',
          where: 'courseId = ?',
          whereArgs: [courseId],
          orderBy:
              "'order' ASC, title ASC", // Add secondary sort for consistency
        );
        final loadedSections =
            sectionMaps.map((map) => Section.fromMap(map)).toList();
        if (loadedSections.isNotEmpty) {
          _sectionsByCourseId[courseId] = loadedSections;
          print(
              "SectionProvider: Loaded ${loadedSections.length} sections for course $courseId from DB. Notifying listeners.");
          notifyListeners(); // Notify to show cached data immediately
        } else {
          _sectionsByCourseId[courseId] =
              []; // Ensure the key exists, even if empty
          print(
              "SectionProvider: No sections found in DB for course $courseId.");
        }
      } catch (e) {
        print(
            "SectionProvider: Error loading sections for course $courseId from DB: $e");
        // Keep _sectionsByCourseId[courseId] potentially null or empty if DB load failed
        _sectionsByCourseId[courseId] =
            []; // Ensure key exists to avoid null checks later
      }
    }

    // --- 2. Attempt Network Fetch (Prioritized Data Source) ---
    // Always attempt network fetch unless specifically told not to force refresh
    // AND we already have data in the provider's map.
    // The refresh indicator or initial load handles the loading state.
    if (forceRefresh || !hasExistingData) {
      // We always attempt network if forced, or if we had no data initially.
      // If !forceRefresh and hasExistingData is true, we skipped the network fetch.
      // If !forceRefresh and hasExistingData is false, we loaded from DB (found nothing)
      // and now we MUST fetch from network.
      // So, the logic simplifies: always fetch network if forced, OR if we had no data initially.
      // If we had data AND not forced, we skip network now. This matches the original logic.
      // Let's rethink the goal: "always prioritizes data from the api and update the sql lite only when that fails it should show data from the sqllite local storage"
      // This isn't what we implemented. The user asked for "always prioritizes data from the api", which usually means:
      // 1. Show cache immediately (if exists).
      // 2. Fetch from API regardless.
      // 3. If API succeeds and data is different, update cache and UI.
      // 4. If API fails, keep showing cache (if any) and show an error message *if no cache*.
      // Let's implement that Cache-First, Network-Always strategy.

      final fetchFuture = _performNetworkFetch(courseId);
      _ongoingFetches[courseId] = fetchFuture;

      try {
        await fetchFuture; // Wait for the network fetch to complete
        print("SectionProvider: Network fetch for course $courseId completed.");
      } finally {
        _ongoingFetches.remove(courseId); // Clean up the ongoing fetch map
        _isLoadingForCourseId[courseId] =
            false; // Always turn off loading when fetch finishes
        notifyListeners(); // Ensure UI updates after network attempt, even if data didn't change or failed
        print(
            "SectionProvider: Fetch process finished for course $courseId. Notified listeners. Error: ${_errorForCourseId[courseId]}. Sections count: ${_sectionsByCourseId[courseId]?.length}");
      }
    } else {
      print(
          "SectionProvider: Not forcing refresh and existing data is available for course $courseId. Skipping network fetch.");
      _isLoadingForCourseId[courseId] = false; // Ensure loading is off
      // Don't notify listeners here if no state change occurred (unless explicitly needed)
    }
  }

  Future<void> _performNetworkFetch(int courseId) async {
    final url = Uri.parse('$_apiBaseUrl/sections/course/$courseId');
    print(
        "SectionProvider: Attempting network fetch for course $courseId from $url");

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json"
      }).timeout(const Duration(
          seconds: 20)); // Shorter timeout for sections? Or maybe 45 is fine.

      print(
          "SectionProvider: Sections API Response for course $courseId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        List<dynamic> extractedData = []; // Declare extractedData here

        if (decodedBody is List) {
          extractedData = decodedBody;
          print("SectionProvider: API returned a list directly.");
        } else {
          // Handle cases where API might return an object wrap like the course list
          // This is just a guess based on the course API, adjust if section API differs
          if (decodedBody is Map<String, dynamic> &&
              decodedBody.containsKey('sections') &&
              decodedBody['sections'] is List) {
            extractedData = decodedBody['sections'];
            print("SectionProvider: API returned object with 'sections' key.");
          } else {
            String parseError =
                'Failed to load chapters: Unexpected API response format.';
            print("SectionProvider: $parseError Body: ${response.body}");
            // Only set error if there's no cached data being displayed
            if (!(_sectionsByCourseId.containsKey(courseId) &&
                _sectionsByCourseId[courseId]!.isNotEmpty)) {
              _errorForCourseId[courseId] = parseError;
            } else {
              print(
                  "SectionProvider: Network parse error after showing cached data for course $courseId.");
              // Keep cached data, no critical error banner
            }
            // Return early as parsing failed
            return;
          }
        }

        final List<Section> fetchedSections = extractedData
            .map((sectionJson) {
              try {
                return Section.fromJson(sectionJson as Map<String, dynamic>);
              } catch (e, s) {
                print(
                    "SectionProvider: Error parsing individual section JSON: ${e.runtimeType}: $e");
                print("Stacktrace: $s");
                print("Problematic section JSON: $sectionJson");
                return null; // Return null for problematic items
              }
            })
            .whereType<Section>() // Filter out nulls
            .toList();

        // Compare with current data before saving and updating state
        final currentSections = _sectionsByCourseId[courseId] ?? [];
        if (!listEquals(currentSections, fetchedSections)) {
          print(
              "SectionProvider: Network data for course $courseId is different. Saving and updating state.");
          await _saveSectionsToDb(courseId, fetchedSections);

          // Sort before updating state
          fetchedSections
              .sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          _sectionsByCourseId[courseId] = fetchedSections;
          _errorForCourseId[courseId] = null; // Clear network errors on success
          // State update happens in the finally block of fetchSectionsForCourse
        } else {
          print(
              "SectionProvider: Network data for course $courseId is the same as current. No update needed.");
          _errorForCourseId[courseId] =
              null; // Clear any previous network error if fetch was successful
        }
      } else {
        _handleHttpErrorResponse(
            response, courseId, _failedToLoadSectionsMessage);
      }
    } on TimeoutException catch (e) {
      print(
          "SectionProvider: TimeoutException fetching sections for course $courseId: $e");
      // Only set error if there's no cached data being displayed
      if (!(_sectionsByCourseId.containsKey(courseId) &&
          _sectionsByCourseId[courseId]!.isNotEmpty)) {
        _errorForCourseId[courseId] = _timeoutErrorMessage;
      } else {
        print(
            "SectionProvider: Network timeout after showing cached data for course $courseId.");
        _errorForCourseId[courseId] =
            null; // Keep cached data, no critical error banner
      }
    } on SocketException catch (e) {
      print(
          "SectionProvider: SocketException fetching sections for course $courseId: $e");
      // Only set error if there's no cached data being displayed
      if (!(_sectionsByCourseId.containsKey(courseId) &&
          _sectionsByCourseId[courseId]!.isNotEmpty)) {
        _errorForCourseId[courseId] = _networkErrorMessage;
      } else {
        print(
            "SectionProvider: Network socket error after showing cached data for course $courseId.");
        _errorForCourseId[courseId] =
            null; // Keep cached data, no critical error banner
      }
    } on http.ClientException catch (e, s) {
      // Added stacktrace capture
      print(
          "SectionProvider: ClientException fetching sections for course $courseId: ${e.message}");
      print("Stacktrace: $s"); // Print stacktrace
      // Only set error if there's no cached data being displayed
      if (!(_sectionsByCourseId.containsKey(courseId) &&
          _sectionsByCourseId[courseId]!.isNotEmpty)) {
        _errorForCourseId[courseId] = "$_networkErrorMessage: ${e.message}";
      } else {
        print(
            "SectionProvider: Network client error after showing cached data for course $courseId.");
        _errorForCourseId[courseId] =
            null; // Keep cached data, no critical error banner
      }
    } catch (e, s) {
      // Added stacktrace capture
      print(
          "SectionProvider: Generic Exception during network fetch for course $courseId: $e");
      print("Stacktrace: $s"); // Print stacktrace
      // Only set error if there's no cached data being displayed
      if (!(_sectionsByCourseId.containsKey(courseId) &&
          _sectionsByCourseId[courseId]!.isNotEmpty)) {
        _errorForCourseId[courseId] =
            "$_unexpectedErrorMessage: ${e.toString()}";
      } else {
        print(
            "SectionProvider: Generic network error after showing cached data for course $courseId.");
        _errorForCourseId[courseId] =
            null; // Keep cached data, no critical error banner
      }
    }
  }

  Future<void> _saveSectionsToDb(
      int courseId, List<Section> sectionsToSave) async {
    try {
      final db =
          await _dbHelper.database; // Get DB instance once for transaction
      await db.transaction((txn) async {
        print(
            "SectionProvider: Clearing existing sections for course $courseId from DB in transaction...");
        await txn
            .delete('sections', where: 'courseId = ?', whereArgs: [courseId]);
        print(
            "SectionProvider: Deleted existing sections for course $courseId.");

        if (sectionsToSave.isEmpty) {
          print(
              "SectionProvider: No sections to save to DB for course $courseId.");
          return;
        }

        print(
            "SectionProvider: Saving ${sectionsToSave.length} sections for course $courseId to DB in transaction...");
        for (final section in sectionsToSave) {
          // Use the prefix for ConflictAlgorithm
          await txn.insert('sections', section.toMap(),
              conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
        }
        print(
            "SectionProvider: Sections for course $courseId saved to DB successfully in transaction.");
      });
    } catch (e, s) {
      print(
          "SectionProvider: Error saving sections for course $courseId to DB: $e\n$s");
      // Decide if you want to rethrow or just log. For critical errors, rethrowing might be needed.
      // For this case, logging is likely sufficient as the network data is already in state.
    }
  }

  bool listEquals(List<Section> a, List<Section> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      // Basic comparison, can add more fields if needed
      // Compare order, title, and ID for equality
      if (a[i].id != b[i].id ||
          a[i].title != b[i].title ||
          a[i].order != b[i].order) {
        return false;
      }
    }
    return true;
  }

  void _handleHttpErrorResponse(
      http.Response response, int courseId, String defaultUserMessage) {
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map &&
          errorBody.containsKey('message') &&
          errorBody['message'] != null &&
          errorBody['message'].toString().isNotEmpty) {
        // Only set error if there's no cached data being displayed
        if (!(_sectionsByCourseId.containsKey(courseId) &&
            _sectionsByCourseId[courseId]!.isNotEmpty)) {
          _errorForCourseId[courseId] = errorBody['message'].toString();
        } else {
          print(
              "SectionProvider: Network API error after showing cached data for course $courseId: ${errorBody['message']}");
          // No critical error banner needed as cached data is shown
        }
      } else {
        // Only set error if there's no cached data being displayed
        if (!(_sectionsByCourseId.containsKey(courseId) &&
            _sectionsByCourseId[courseId]!.isNotEmpty)) {
          _errorForCourseId[courseId] =
              "$defaultUserMessage (Status: ${response.statusCode})";
        } else {
          print(
              "SectionProvider: Network HTTP error after showing cached data for course $courseId (Status: ${response.statusCode}).");
          // No critical error banner needed as cached data is shown
        }
      }
    } catch (e) {
      // Only set error if there's no cached data being displayed
      if (!(_sectionsByCourseId.containsKey(courseId) &&
          _sectionsByCourseId[courseId]!.isNotEmpty)) {
        _errorForCourseId[courseId] =
            "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.";
      } else {
        print(
            "SectionProvider: Network HTTP error (non-parsable body) after showing cached data for course $courseId (Status: ${response.statusCode}).");
        // No critical error banner needed as cached data is shown
      }
    }
  }

  void clearErrorForCourse(int courseId) {
    // Clear error and notify only if an error was actually set
    if (_errorForCourseId.containsKey(courseId) &&
        _errorForCourseId[courseId] != null) {
      _errorForCourseId[courseId] = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    print("SectionProvider: Dispose called.");
    // Consider cancelling ongoing futures if any are active, though for simple HTTP calls it might not be strictly necessary
    // if the screen is popping, the future will likely complete or error out harmlessly.
    _ongoingFetches.clear(); // Clear map on dispose
    super.dispose();
  }
}
