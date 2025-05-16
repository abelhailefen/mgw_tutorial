// lib/provider/discussion_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/models/comment.dart'; // Make sure Comment model is imported
import 'package:mgw_tutorial/provider/auth_provider.dart';

class DiscussionProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoadingPosts = false;
  String? _postsError;
  bool _isCreatingPost = false;
  String? _createPostError;

  // State for comments of a single, currently viewed post
  List<Comment> _currentPostComments = [];
  bool _isLoadingComments = false;
  String? _commentsError;
  int? _currentlyViewedPostId; // To know which post's comments are loaded

  List<Post> get posts => [..._posts];
  bool get isLoadingPosts => _isLoadingPosts;
  String? get postsError => _postsError;
  bool get isCreatingPost => _isCreatingPost;
  String? get createPostError => _createPostError;

  List<Comment> get currentPostComments => [..._currentPostComments];
  bool get isLoadingComments => _isLoadingComments;
  String? get commentsError => _commentsError;
  int? get currentlyViewedPostId => _currentlyViewedPostId;


  static const String _apiBaseUrl = "https://mgw-backend-1.onrender.com/api";

  // --- Post Methods ---
  Future<void> fetchPosts() async {
    // ... (existing fetchPosts logic - no change)
    _isLoadingPosts = true;
    _postsError = null;
    notifyListeners();
    final url = Uri.parse('$_apiBaseUrl/posts');
    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        _posts = extractedData.map((postData) => Post.fromJson(postData as Map<String, dynamic>)).toList();
        _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _postsError = "Failed to load posts. Status: ${response.statusCode}, Body: ${response.body}";
      }
    } catch (e) {
      _postsError = "Error fetching posts: ${e.toString()}";
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String title,
    required String description,
    required AuthProvider authProvider,
  }) async {
    // ... (existing createPost logic - no change other than error var if needed)
    if (authProvider.currentUser == null) { /* ... */ return false; }
    final int? userId = authProvider.currentUser!.id;
    if (userId == null) { /* ... */ return false; }

    _isCreatingPost = true;
    _createPostError = null;
    notifyListeners();
    final url = Uri.parse('$_apiBaseUrl/posts');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-User-ID": userId.toString(),
        },
        body: json.encode({'title': title, 'description': description, 'userId': userId}),
      );
      if (response.statusCode == 201) {
        await fetchPosts(); // Refreshes the main post list
        _isCreatingPost = false;
        return true;
      } else {
        try {
            final errorData = json.decode(response.body);
            _createPostError = errorData['message'] ?? "Failed to create post. Status: ${response.statusCode}";
        } catch (e) { _createPostError = "Failed to create post. Status: ${response.statusCode}, Body: ${response.body}"; }
        _isCreatingPost = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _createPostError = "An error occurred while creating post: ${e.toString()}";
      _isCreatingPost = false;
      notifyListeners();
      return false;
    }
  }

  // --- Comment Methods ---
  Future<void> fetchCommentsForPost(int postId) async {
    _isLoadingComments = true;
    _commentsError = null;
    _currentlyViewedPostId = postId;
    // Clear previous comments if fetching for a new post, or append if implementing pagination
    _currentPostComments = [];
    notifyListeners();

    // Assuming the API supports fetching comments by postId
    final url = Uri.parse('$_apiBaseUrl/comments?postId=$postId');
    // If your API is simply /api/comments and you filter client-side (not recommended for many comments):
    // final url = Uri.parse('$_apiBaseUrl/comments');

    try {
      print("Fetching comments for post $postId from: $url");
      final response = await http.get(url, headers: {"Accept": "application/json"});
      print("Comments Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        // If API returns all comments and you need to filter:
        // _currentPostComments = extractedData
        //     .map((commentData) => Comment.fromJson(commentData as Map<String, dynamic>))
        //     .where((comment) => comment.postId == postId) // Client-side filter
        //     .toList();
        
        // If API returns comments already filtered by postId (preferred):
        _currentPostComments = extractedData
            .map((commentData) => Comment.fromJson(commentData as Map<String, dynamic>))
            .toList();

        _currentPostComments.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest first
      } else {
        _commentsError = "Failed to load comments. Status: ${response.statusCode}, Body: ${response.body}";
        print(_commentsError);
      }
    } catch (e) {
      _commentsError = "Error fetching comments: ${e.toString()}";
      print(_commentsError);
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  Future<bool> createComment({
    required int postId,
    required String commentText,
    required AuthProvider authProvider,
  }) async {
    if (authProvider.currentUser == null) {
      _commentsError = "User not authenticated to comment."; // Use _commentsError or a new specific error state
      notifyListeners();
      return false;
    }
    final int? userId = authProvider.currentUser!.id;
    if (userId == null) {
      _commentsError = "User ID is missing. Cannot create comment.";
      notifyListeners();
      return false;
    }

    // Consider a specific loading state for creating a comment if needed
    // _isCreatingComment = true; notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/comments');
    try {
      final requestBody = {
        'comment': commentText,
        'userId': userId,
        'postId': postId,
      };
      print("[DiscussionProvider] Create Comment Request Body: ${json.encode(requestBody)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-User-ID": userId.toString(), // For mock auth
        },
        body: json.encode(requestBody),
      );

      print("Create Comment Response Status: ${response.statusCode}");
      print("Create Comment Response Body: ${response.body}");

      if (response.statusCode == 201) { // HTTP 201 Created
        // Refetch comments for the current post to show the new one
        await fetchCommentsForPost(postId);
        // _isCreatingComment = false; notifyListeners();
        return true;
      } else {
        try {
            final errorData = json.decode(response.body);
            _commentsError = errorData['message'] ?? "Failed to create comment. Status: ${response.statusCode}";
        } catch (e) {
            _commentsError = "Failed to create comment. Status: ${response.statusCode}, Body: ${response.body}";
        }
        // _isCreatingComment = false;
        notifyListeners(); // For the error
        return false;
      }
    } catch (e) {
      _commentsError = "An error occurred while creating comment: ${e.toString()}";
      // _isCreatingComment = false;
      notifyListeners(); // For the error
      return false;
    }
  }
}