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
  Map<int, bool> _allRepliesLoadedForCommentId = {};

  List<Reply> repliesForComment(int commentId) => _repliesByCommentId[commentId] ?? [];
  bool isLoadingForComment(int commentId) => _isLoadingForCommentId[commentId] ?? false;
  String? errorForComment(int commentId) => _errorForCommentId[commentId];
  bool allRepliesLoadedForComment(int commentId) => _allRepliesLoadedForCommentId[commentId] ?? false;

  final String _apiBaseUrl;
  final AuthProvider _authProvider;

  ReplyProvider(this._apiBaseUrl, this._authProvider);

  List<Reply> _buildReplyTree(List<Reply> flatReplies) {
    Map<int, Reply> map = {};
    List<Reply> roots = [];

    // First pass: create a map of all replies by their ID and initialize childReplies
    for (var reply in flatReplies) {
      map[reply.id] = reply.copyWith(childReplies: []); // Ensure childReplies is mutable
    }

    // Second pass: build the tree
    for (var reply in flatReplies) {
      var currentReplyNode = map[reply.id]!;
      if (reply.parentReplyId == null) { // This is a direct reply to the comment
        roots.add(currentReplyNode);
      } else {
        var parentNode = map[reply.parentReplyId];
        if (parentNode != null) {
          // Create a new list for childReplies if it's immutable, or add to existing
          List<Reply> updatedChildReplies = List<Reply>.from(parentNode.childReplies)..add(currentReplyNode);
          map[reply.parentReplyId!] = parentNode.copyWith(childReplies: updatedChildReplies);
          
           // Update roots if the parent was a root and got updated
          int rootIndex = roots.indexWhere((r) => r.id == reply.parentReplyId);
          if (rootIndex != -1) {
            roots[rootIndex] = map[reply.parentReplyId]!;
          }

        } else {
          // Parent reply not found (orphan), treat as a root for now or handle error
          // This might happen if parent reply was deleted or data is inconsistent
          print("Warning: Parent reply with ID ${reply.parentReplyId} not found for reply ${reply.id}. Treating as root.");
          roots.add(currentReplyNode);
        }
      }
    }
    // Sort root replies and their children by creation date
    for (var root in roots) {
      _sortRepliesRecursively(root);
    }
    roots.sort((a,b) => a.createdAt.compareTo(b.createdAt));
    return roots;
  }

  void _sortRepliesRecursively(Reply replyNode) {
    // Ensure childReplies is not null before trying to sort.
    // The copyWith should initialize it, but defensive check.
    if (replyNode.childReplies.isNotEmpty) {
        replyNode.childReplies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        for (var child in replyNode.childReplies) {
          _sortRepliesRecursively(child);
        }
    }
  }


  Future<void> fetchRepliesForComment(int commentId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _repliesByCommentId.containsKey(commentId) &&
        !(_isLoadingForCommentId[commentId] ?? false) &&
        (_allRepliesLoadedForCommentId[commentId] ?? false) ) {
      return;
    }

    _isLoadingForCommentId[commentId] = true;
    _errorForCommentId[commentId] = null;
    if (forceRefresh) {
      _allRepliesLoadedForCommentId[commentId] = false;
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/post-comments/$commentId/replies');
    print("Fetching replies for comment $commentId from: $url");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      print("Fetch replies response for comment $commentId: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 200 ? 200 : response.body.length))}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Reply> flatReplies = data.map((rJson) {
          try {
            return Reply.fromJson(rJson as Map<String, dynamic>);
          } catch (e) {
            print("Error parsing reply JSON for comment $commentId: $e, JSON: $rJson");
            return null;
          }
        }).whereType<Reply>().toList();

        _repliesByCommentId[commentId] = _buildReplyTree(flatReplies);
        _errorForCommentId[commentId] = null;
        _allRepliesLoadedForCommentId[commentId] = true;
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

  // Create reply now accepts an optional parentReplyId
  Future<Map<String, dynamic>> createReply({
    required int parentCommentId,
    required String content,
    int? parentReplyId, // For replying to another reply
  }) async {
    if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;

    final url = Uri.parse('$_apiBaseUrl/post-comments/$parentCommentId/replies');
    print("Creating reply to comment $parentCommentId (parentReplyId: $parentReplyId) at: $url with content: $content by user: $userId");
    
    final Map<String, dynamic> body = {
      'content': content,
      'userId': userId,
    };
    if (parentReplyId != null) {
      body['parentReplyId'] = parentReplyId;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-User-ID": userId.toString()
        },
        body: json.encode(body),
      );

      print("Create reply response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 201) {
        await fetchRepliesForComment(parentCommentId, forceRefresh: true); 
        notifyListeners();
        return {'success': true, 'message': "Reply created."}; 
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
    final url = Uri.parse('$_apiBaseUrl/comment-replies/$replyId');
    print("Updating reply $replyId (parent $parentCommentId) at: $url with new content: $newContent");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-User-ID": userId.toString()
        },
        body: json.encode({'content': newContent}),
      );
      print("Update reply response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
         await fetchRepliesForComment(parentCommentId, forceRefresh: true); 
        notifyListeners();
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
    final url = Uri.parse('$_apiBaseUrl/comment-replies/$replyId');
    print("Deleting reply $replyId (parent $parentCommentId) at: $url");

    try {
      final response = await http.delete(
        url,
        headers: {"Accept": "application/json", "X-User-ID": userId.toString()},
      );
      print("Delete reply response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchRepliesForComment(parentCommentId, forceRefresh: true); 
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