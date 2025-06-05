// lib/provider/comment_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/comment.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';

class CommentProvider with ChangeNotifier {
  Map<int, List<Comment>> _commentsByPostId = {};
  Map<int, bool> _isLoadingForPostId = {};
  Map<int, String?> _errorForPostId = {};

  List<Comment> commentsForPost(int postId) => _commentsByPostId[postId] ?? [];
  bool isLoadingForPost(int postId) => _isLoadingForPostId[postId] ?? false;
  String? errorForPost(int postId) => _errorForPostId[postId];

  final String _apiBaseUrl; // This will be "https://courseservice.anbesgames.com/api"
  final AuthProvider _authProvider;

  CommentProvider(this._apiBaseUrl, this._authProvider);

  Future<void> fetchCommentsForPost(int postId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _commentsByPostId.containsKey(postId) && !(_isLoadingForPostId[postId] ?? false)) {
      return;
    }
    _isLoadingForPostId[postId] = true;
    _errorForPostId[postId] = null;
    notifyListeners();

    // UPDATED URL
    final url = Uri.parse('$_apiBaseUrl/post-comments?postId=$postId');
    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _commentsByPostId[postId] = data.map((cJson) => Comment.fromJson(cJson as Map<String, dynamic>)).toList();
        _commentsByPostId[postId]?.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _errorForPostId[postId] = null;
      } else {
        _errorForPostId[postId] = "Failed to load comments for post $postId: ${response.body}";
      }
    } catch (e) {
      _errorForPostId[postId] = "Error fetching comments for post $postId: ${e.toString()}";
    } finally {
      _isLoadingForPostId[postId] = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createComment({required int postId, required String commentText}) async {
     if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;
    // UPDATED URL
    final url = Uri.parse('$_apiBaseUrl/post-comments');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Accept": "application/json", "X-User-ID": userId.toString()},
        body: json.encode({'comment': commentText, 'userId': userId, 'postId': postId}),
      );
      if (response.statusCode == 201) {
        final newComment = Comment.fromJson(json.decode(response.body) as Map<String, dynamic>);
        _commentsByPostId[postId] = [...(_commentsByPostId[postId] ?? []), newComment];
        _commentsByPostId[postId]?.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
        return {'success': true, 'message': "Comment created.", 'comment': newComment};
      } else {
        return {'success': false, 'message': "Failed to create comment: ${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': "Error creating comment: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> updateComment({required int commentId, required int postId, required String newCommentText}) async {
     if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;
    // UPDATED URL
    final url = Uri.parse('$_apiBaseUrl/post-comments/$commentId');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json", "Accept": "application/json", "X-User-ID": userId.toString()},
        body: json.encode({'comment': newCommentText, 'userId': userId}), // Assuming API still takes userId for update validation
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (_commentsByPostId.containsKey(postId)) {
          final index = _commentsByPostId[postId]!.indexWhere((c) => c.id == commentId);
          if (index != -1) {
            _commentsByPostId[postId]![index] = _commentsByPostId[postId]![index].copyWith(comment: newCommentText, updatedAt: DateTime.now());
            notifyListeners();
          }
        }
        return {'success': true, 'message': "Comment updated."};
      } else {
        return {'success': false, 'message': "Failed to update comment: ${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': "Error updating comment: ${e.toString()}"};
    }
  }
  Future<Map<String, dynamic>> deleteComment({required int commentId, required int postId}) async {
    if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;
    // UPDATED URL
    final url = Uri.parse('$_apiBaseUrl/post-comments/$commentId');
    try {
      final response = await http.delete(url, headers: {"Accept": "application/json", "X-User-ID": userId.toString()});
      if (response.statusCode == 200 || response.statusCode == 204) {
        _commentsByPostId[postId]?.removeWhere((c) => c.id == commentId);
        notifyListeners();
        return {'success': true, 'message': "Comment deleted."};
      } else {
        return {'success': false, 'message': "Failed to delete comment: ${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': "Error deleting comment: ${e.toString()}"};
    }
  }
}