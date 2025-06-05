// lib/provider/discussion_provider.dart
import 'package:flutter/foundation.dart';
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/models/comment.dart';
import 'package:mgw_tutorial/models/reply.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/post_provider.dart';
import 'package:mgw_tutorial/provider/comment_provider.dart';
import 'package:mgw_tutorial/provider/reply_provider.dart';

class DiscussionProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  late final PostProvider _postProvider;
  late final CommentProvider _commentProvider;
  late final ReplyProvider _replyProvider;

  static const String _apiBaseUrl = "https://courseservice.anbesgames.com/api";

  // UI specific error states for submission forms
  String? _submitPostError;
  String? _submitCommentError;
  String? _submitReplyError;
  String? _updateItemError; // Generic for updates
  String? _deleteItemError; // Generic for deletes

  // UI specific loading states for submission/action
  bool _isSubmittingPost = false;
  bool _isSubmittingComment = false;
  bool _isSubmittingReply = false;
  bool _isUpdatingItem = false;
  bool _isDeletingItem = false;


  DiscussionProvider(this._authProvider) {
    _postProvider = PostProvider(_apiBaseUrl, _authProvider);
    _commentProvider = CommentProvider(_apiBaseUrl, _authProvider);
    _replyProvider = ReplyProvider(_apiBaseUrl, _authProvider);

    // Listen to changes in sub-providers to trigger notifyListeners in DiscussionProvider
    // This ensures that consumers of DiscussionProvider update when sub-provider data changes.
    _postProvider.addListener(_notifyDiscussionListeners);
    _commentProvider.addListener(_notifyDiscussionListeners);
    _replyProvider.addListener(_notifyDiscussionListeners);
  }

  void _notifyDiscussionListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    _postProvider.removeListener(_notifyDiscussionListeners);
    _commentProvider.removeListener(_notifyDiscussionListeners);
    _replyProvider.removeListener(_notifyDiscussionListeners);
    _postProvider.dispose();
    _commentProvider.dispose();
    _replyProvider.dispose();
    super.dispose();
  }

  // --- Getters for Data (delegating to sub-providers) ---
  List<Post> get posts => _postProvider.posts;
  bool get isLoadingPosts => _postProvider.isLoading;
  String? get postsError => _postProvider.error;

  List<Comment> commentsForPost(int postId) => _commentProvider.commentsForPost(postId);
  bool isLoadingCommentsForPost(int postId) => _commentProvider.isLoadingForPost(postId);
  String? commentErrorForPost(int postId) => _commentProvider.errorForPost(postId);
  
  List<Reply> repliesForComment(int commentId) => _replyProvider.repliesForComment(commentId);
  bool isLoadingRepliesForComment(int commentId) => _replyProvider.isLoadingForComment(commentId);
  String? replyErrorForComment(int commentId) => _replyProvider.errorForComment(commentId);
  bool allRepliesLoadedForComment(int commentId) => _replyProvider.allRepliesLoadedForComment(commentId);


  // --- Getters for UI-specific states ---
  String? get submitPostError => _submitPostError;
  String? get submitCommentError => _submitCommentError;
  String? get submitReplyError => _submitReplyError;
  String? get updateItemError => _updateItemError;
  String? get deleteItemError => _deleteItemError;

  bool get isSubmittingPost => _isSubmittingPost;
  bool get isSubmittingComment => _isSubmittingComment;
  bool get isSubmittingReply => _isSubmittingReply;
  bool get isUpdatingItem => _isUpdatingItem;
  bool get isDeletingItem => _isDeletingItem;

  // --- Post Methods ---
  Future<void> fetchPosts() async => await _postProvider.fetchPosts();

  Future<bool> createPost({required String title, required String description}) async {
    _isSubmittingPost = true;
    _submitPostError = null;
    notifyListeners();
    final result = await _postProvider.createPost(title: title, description: description);
    _isSubmittingPost = false;
    if (!result['success']) _submitPostError = result['message'];
    notifyListeners();
    return result['success'];
  }
  // ... (Update/Delete Post methods delegating and managing UI state)
  Future<bool> updatePost({required int postId, required String title, required String description}) async {
    _isUpdatingItem = true; _updateItemError = null; notifyListeners();
    final result = await _postProvider.updatePost(postId: postId, title: title, description: description);
    _isUpdatingItem = false;
    if (!result['success']) _updateItemError = result['message'];
    notifyListeners();
    return result['success'];
  }

  Future<bool> deletePost(int postId) async {
    _isDeletingItem = true; _deleteItemError = null; notifyListeners();
    final result = await _postProvider.deletePost(postId);
    _isDeletingItem = false;
    if (!result['success']) _deleteItemError = result['message'];
    notifyListeners();
    return result['success'];
  }


  // --- Comment Methods ---
  Future<void> fetchCommentsForPost(int postId, {bool forceRefresh = false}) async {
      await _commentProvider.fetchCommentsForPost(postId, forceRefresh: forceRefresh);
      // After fetching comments, iterate and fetch their replies if not already loaded or forced
      if (forceRefresh || _commentProvider.commentsForPost(postId).any((c) => !_replyProvider.allRepliesLoadedForComment(c.id))) {
          for (var comment in _commentProvider.commentsForPost(postId)) {
              await _replyProvider.fetchRepliesForComment(comment.id, forceRefresh: forceRefresh);
          }
      }
  }

  Future<bool> createTopLevelComment({required int postId, required String commentText}) async {
    _isSubmittingComment = true;
    _submitCommentError = null;
    notifyListeners();
    final result = await _commentProvider.createComment(postId: postId, commentText: commentText);
    _isSubmittingComment = false;
    if (!result['success']) _submitCommentError = result['message'];
    notifyListeners();
    return result['success'];
  }
   Future<bool> updateComment({required int commentId, required int postId, required String newCommentText}) async {
    _isUpdatingItem = true; _updateItemError = null; notifyListeners();
    final result = await _commentProvider.updateComment(commentId: commentId, postId: postId, newCommentText: newCommentText);
    _isUpdatingItem = false;
    if (!result['success']) _updateItemError = result['message'];
    notifyListeners();
    return result['success'];
  }

  Future<bool> deleteComment({required int commentId, required int postId}) async {
    _isDeletingItem = true; _deleteItemError = null; notifyListeners();
    final result = await _commentProvider.deleteComment(commentId: commentId, postId: postId);
    _isDeletingItem = false;
    if (!result['success']) _deleteItemError = result['message'];
    notifyListeners();
    return result['success'];
  }


  // --- Reply Methods ---
  Future<void> fetchRepliesForComment(int commentId, {bool forceRefresh = false}) async => await _replyProvider.fetchRepliesForComment(commentId, forceRefresh: forceRefresh);
  
  Future<bool> createReply({required int parentCommentId, required String content, int? parentReplyId}) async {
    _isSubmittingReply = true;
    _submitReplyError = null;
    notifyListeners();
    final result = await _replyProvider.createReply(
        parentCommentId: parentCommentId, 
        content: content,
        parentReplyId: parentReplyId,
    );
    _isSubmittingReply = false;
    if (!result['success']) _submitReplyError = result['message'];
    notifyListeners();
    return result['success'];
  }
  Future<bool> updateReply({required int parentCommentId, required int replyId, required String newContent}) async {
    _isUpdatingItem = true; _updateItemError = null; notifyListeners();
    final result = await _replyProvider.updateReply(parentCommentId: parentCommentId, replyId: replyId, newContent: newContent);
    _isUpdatingItem = false;
    if (!result['success']) _updateItemError = result['message'];
    notifyListeners();
    return result['success'];
  }

  Future<bool> deleteReply({required int parentCommentId, required int replyId}) async {
    _isDeletingItem = true; _deleteItemError = null; notifyListeners();
    final result = await _replyProvider.deleteReply(parentCommentId: parentCommentId, replyId: replyId);
    _isDeletingItem = false;
    if (!result['success']) _deleteItemError = result['message'];
    notifyListeners();
    return result['success'];
  }
}