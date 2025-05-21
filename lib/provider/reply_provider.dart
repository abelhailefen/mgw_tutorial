// lib/provider/reply_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/reply.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';

class ReplyProvider with ChangeNotifier {
  Map<int, List<Reply>> _repliesByCommentId = {};
  Map<int, bool> _isLoadingForCommentId = {};
  Map<int, String?> _errorForCommentId = {};
  Map<int, bool> _allRepliesLoadedForCommentId = {}; // To track if all replies have been fetched

  List<Reply> repliesForComment(int commentId) => _repliesByCommentId[commentId] ?? [];
  bool isLoadingForComment(int commentId) => _isLoadingForCommentId[commentId] ?? false;
  String? errorForComment(int commentId) => _errorForCommentId[commentId];
  bool allRepliesLoadedForComment(int commentId) => _allRepliesLoadedForCommentId[commentId] ?? false;

  final String _apiBaseUrl; // This will be "https://mgw-backend.onrender.com/api"
  final AuthProvider _authProvider;

  ReplyProvider(this._apiBaseUrl, this._authProvider);

  // Fetches replies for a specific comment.
  // The API endpoint /post-comments/{commentId}/replies likely gets ALL replies for that comment.
  Future<void> fetchRepliesForComment(int commentId, {bool forceRefresh = false}) async {
    // If already loaded and not forcing refresh, and all replies are marked as loaded, return.
    if (!forceRefresh &&
        _repliesByCommentId.containsKey(commentId) &&
        !(_isLoadingForCommentId[commentId] ?? false) &&
        (_allRepliesLoadedForCommentId[commentId] ?? false) ) {
      return;
    }

    _isLoadingForCommentId[commentId] = true;
    _errorForCommentId[commentId] = null;
    if (forceRefresh) { // If forcing refresh, reset loaded status
      _allRepliesLoadedForCommentId[commentId] = false;
    }
    notifyListeners();

    // UPDATED URL for fetching replies for a comment
    final url = Uri.parse('$_apiBaseUrl/post-comments/$commentId/replies');
    print("Fetching replies for comment $commentId from: $url");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      print("Fetch replies response for comment $commentId: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 200 ? 200 : response.body.length))}");


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _repliesByCommentId[commentId] = data.map((rJson) {
          try {
            return Reply.fromJson(rJson as Map<String, dynamic>);
          } catch (e) {
            print("Error parsing reply JSON for comment $commentId: $e, JSON: $rJson");
            // Return a dummy/error reply or rethrow, depending on desired behavior
            // For now, let's skip problematic replies
            return null;
          }
        }).whereType<Reply>().toList(); // Filter out nulls if any parsing failed

        _repliesByCommentId[commentId]?.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _errorForCommentId[commentId] = null;
        _allRepliesLoadedForCommentId[commentId] = true; // Mark all replies as loaded for this comment
      } else {
        _errorForCommentId[commentId] = "Failed to load replies for comment $commentId. Status: ${response.statusCode}, Body: ${response.body}";
      }
    } catch (e) {
      _errorForCommentId[commentId] = "Error fetching replies for comment $commentId: ${e.toString()}";
      print("Exception fetching replies for comment $commentId: $e");
    } finally {
      _isLoadingForCommentId[commentId] = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createReply({required int parentCommentId, required String content}) async {
    if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;

    // UPDATED URL for creating a reply to a specific comment
    final url = Uri.parse('$_apiBaseUrl/post-comments/$parentCommentId/replies');
    print("Creating reply to comment $parentCommentId at: $url with content: $content by user: $userId");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-User-ID": userId.toString() // Assuming your backend uses this header for user identification
        },
        body: json.encode({
          'content': content,
          'userId': userId,
          // 'postCommentId': parentCommentId, // The backend might infer parentCommentId from the URL
        }),
      );

      print("Create reply response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 201) {
        final newReplyJson = json.decode(response.body) as Map<String, dynamic>;
        final newReply = Reply.fromJson(newReplyJson);

        // Add to the local list
        _repliesByCommentId.putIfAbsent(parentCommentId, () => []);
        _repliesByCommentId[parentCommentId]!.add(newReply);
        _repliesByCommentId[parentCommentId]?.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        notifyListeners();
        return {'success': true, 'message': "Reply created.", 'reply': newReply};
      } else {
        return {'success': false, 'message': "Failed to create reply. Status: ${response.statusCode}, Body: ${response.body}"};
      }
    } catch (e) {
      print("Exception creating reply: $e");
      return {'success': false, 'message': "Error creating reply: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> updateReply({required int parentCommentId, required int replyId, required String newContent}) async {
    if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;

    // UPDATED URL for updating a specific reply
    // The API path implies the parentCommentId is part of the route to identify the reply.
    final url = Uri.parse('$_apiBaseUrl/comments/$parentCommentId/replies/$replyId');
    print("Updating reply $replyId (parent $parentCommentId) at: $url with new content: $newContent");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-User-ID": userId.toString()
        },
        body: json.encode({
          'content': newContent,
          // 'userId': userId, // Backend might only need content and validate user via X-User-ID
        }),
      );
      print("Update reply response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (_repliesByCommentId.containsKey(parentCommentId)) {
          final index = _repliesByCommentId[parentCommentId]!.indexWhere((r) => r.id == replyId);
          if (index != -1) {
            // If the backend returns the updated reply, parse it. Otherwise, update locally.
            try {
              if (response.body.isNotEmpty) { // Check if response body is not empty before decoding
                  final updatedReplyData = json.decode(response.body);
                  _repliesByCommentId[parentCommentId]![index] = Reply.fromJson(updatedReplyData as Map<String, dynamic>);
              } else { // If 204 No Content or empty body
                   _repliesByCommentId[parentCommentId]![index] = _repliesByCommentId[parentCommentId]![index].copyWith(content: newContent, updatedAt: DateTime.now());
              }
            } catch (e) {
                 print("Error parsing updated reply or body was empty: $e. Updating locally.");
                 _repliesByCommentId[parentCommentId]![index] = _repliesByCommentId[parentCommentId]![index].copyWith(content: newContent, updatedAt: DateTime.now());
            }
            notifyListeners();
          }
        }
        return {'success': true, 'message': "Reply updated."};
      } else {
        return {'success': false, 'message': "Failed to update reply. Status: ${response.statusCode}, Body: ${response.body}"};
      }
    } catch (e) {
      print("Exception updating reply: $e");
      return {'success': false, 'message': "Error updating reply: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> deleteReply({required int parentCommentId, required int replyId}) async {
    if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;

    // UPDATED URL for deleting a specific reply
    final url = Uri.parse('$_apiBaseUrl/comments/$parentCommentId/replies/$replyId');
    print("Deleting reply $replyId (parent $parentCommentId) at: $url");

    try {
      final response = await http.delete(
        url,
        headers: {
          "Accept": "application/json",
          "X-User-ID": userId.toString()
        },
      );
      print("Delete reply response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        _repliesByCommentId[parentCommentId]?.removeWhere((r) => r.id == replyId);
        notifyListeners();
        return {'success': true, 'message': "Reply deleted."};
      } else {
        return {'success': false, 'message': "Failed to delete reply. Status: ${response.statusCode}, Body: ${response.body}"};
      }
    } catch (e) {
      print("Exception deleting reply: $e");
      return {'success': false, 'message': "Error deleting reply: ${e.toString()}"};
    }
  }
}