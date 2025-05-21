// lib/provider/post_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart'; // For user ID

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => [..._posts];
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String _apiBaseUrl;
  final AuthProvider _authProvider;

  PostProvider(this._apiBaseUrl, this._authProvider) {
    // Optionally fetch posts on initialization if needed by DiscussionProvider
    // fetchPosts();
  }

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final url = Uri.parse('$_apiBaseUrl/posts');
    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        _posts = extractedData.map((postData) => Post.fromJson(postData as Map<String, dynamic>)).toList();
        _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _error = null;
      } else {
        _error = "Failed to load posts. Status: ${response.statusCode}";
      }
    } catch (e) {
      _error = "Error fetching posts: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPost({required String title, required String description}) async {
    if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;
    final url = Uri.parse('$_apiBaseUrl/posts');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Accept": "application/json", "X-User-ID": userId.toString()},
        body: json.encode({'title': title, 'description': description, 'userId': userId}),
      );
      if (response.statusCode == 201) {
        final newPost = Post.fromJson(json.decode(response.body));
        _posts.insert(0, newPost); // Add to start for newest first
        notifyListeners();
        return {'success': true, 'message': "Post created."};
      } else {
        return {'success': false, 'message': "Failed to create post: ${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': "Error creating post: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> updatePost({required int postId, required String title, required String description}) async {
    if (_authProvider.currentUser?.id == null) {
       return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!; // For validation or if API needs it
    final url = Uri.parse('$_apiBaseUrl/posts/$postId');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json", "Accept": "application/json", "X-User-ID": userId.toString()},
        body: json.encode({'title': title, 'description': description, 'userId': userId}),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
            // Assuming API doesn't return the full updated post, or we don't parse it here
             _posts[index] = _posts[index].copyWith(title: title, description: description, updatedAt: DateTime.now());
             notifyListeners();
        }
        return {'success': true, 'message': "Post updated."};
      } else {
        return {'success': false, 'message': "Failed to update post: ${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': "Error updating post: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> deletePost(int postId) async {
    if (_authProvider.currentUser?.id == null) {
      return {'success': false, 'message': "User not authenticated."};
    }
    final int userId = _authProvider.currentUser!.id!;
    final url = Uri.parse('$_apiBaseUrl/posts/$postId');
    try {
      final response = await http.delete(url, headers: {"Accept": "application/json", "X-User-ID": userId.toString()});
      if (response.statusCode == 200 || response.statusCode == 204) {
        _posts.removeWhere((post) => post.id == postId);
        notifyListeners();
        return {'success': true, 'message': "Post deleted."};
      } else {
        return {'success': false, 'message': "Failed to delete post: ${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': "Error deleting post: ${e.toString()}"};
    }
  }
}