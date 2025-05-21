// lib/screens/sidebar/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/models/comment.dart';
import 'package:mgw_tutorial/models/reply.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/widgets/discussion/post_content_view.dart';
import 'package:mgw_tutorial/widgets/discussion/comment_item_view.dart';
import 'package:mgw_tutorial/widgets/discussion/comment_input_field.dart';
import 'package:mgw_tutorial/widgets/discussion/edit_input_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatefulWidget {
  static const routeName = '/post-detail';
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _topLevelCommentController = TextEditingController();
  final _topLevelCommentFormKey = GlobalKey<FormState>();

  int? _replyingToCommentId;
  final _replyController = TextEditingController();
  final _replyFormKey = GlobalKey<FormState>();

  int? _editingCommentId;
  int? _editingReplyId;
  int? _editingReplyParentCommentId;
  final _editTextController = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();

  final _editPostTitleController = TextEditingController();
  final _editPostDescriptionController = TextEditingController();
  final _editPostFormKey = GlobalKey<FormState>();

  late Post _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _fetchData();
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (!mounted) return;
    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    
    if (forceRefresh) {
      await discussionProvider.fetchPosts(); 
      final updatedPostFromList = discussionProvider.posts.firstWhere(
            (p) => p.id == widget.post.id,
            orElse: () => _currentPost);
      if (mounted) {
        setState(() {
          _currentPost = updatedPostFromList;
        });
      }
    }
    
    await discussionProvider.fetchCommentsForPost(_currentPost.id, forceRefresh: forceRefresh);
    
    if (mounted) {
      final comments = discussionProvider.commentsForPost(_currentPost.id);
      for (var comment in comments) {
        if (forceRefresh || !discussionProvider.allRepliesLoadedForComment(comment.id)) {
           await discussionProvider.fetchRepliesForComment(comment.id, forceRefresh: forceRefresh);
        }
      }
    }
  }

  @override
  void dispose() {
    _topLevelCommentController.dispose();
    _replyController.dispose();
    _editTextController.dispose();
    _editPostTitleController.dispose();
    _editPostDescriptionController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
        backgroundColor: theme.colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditPostDialog() {
    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    _editPostTitleController.text = _currentPost.title;
    _editPostDescriptionController.text = _currentPost.description;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final authProviderLoading = Provider.of<DiscussionProvider>(context, listen: true).isUpdatingItem; // Listen to specific loading state

          return AlertDialog(
            backgroundColor: theme.dialogBackgroundColor,
            title: Text(l10n.editPostTitle, style: theme.textTheme.titleLarge),
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
            content: Form(
              key: _editPostFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _editPostTitleController,
                      decoration: InputDecoration(labelText: l10n.generalTitleLabel),
                      validator: (value) => (value == null || value.trim().isEmpty) ? l10n.generalTitleEmptyValidation : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _editPostDescriptionController,
                      decoration: InputDecoration(labelText: l10n.generalDescriptionLabel, alignLabelWithHint: true),
                      maxLines: 5, minLines: 3,
                      validator: (value) => (value == null || value.trim().isEmpty) ? l10n.generalDescriptionEmptyValidation : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text(l10n.cancelButton, style: TextStyle(color: theme.colorScheme.primary)),
                onPressed: authProviderLoading ? null : () => Navigator.of(ctx).pop()
              ),
              ElevatedButton(
                child: authProviderLoading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)))
                    : Text(l10n.saveButton),
                onPressed: authProviderLoading ? null : () async {
                  if (_editPostFormKey.currentState!.validate()) {
                    final success = await discussionProvider.updatePost(
                      postId: _currentPost.id,
                      title: _editPostTitleController.text.trim(),
                      description: _editPostDescriptionController.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.of(ctx).pop();
                    if (success) {
                      _showSuccessSnackBar(l10n.postUpdatedSuccess);
                      await _fetchData(forceRefresh: true);
                    } else {
                      _showErrorSnackBar(discussionProvider.updateItemError ?? l10n.postUpdateFailed);
                    }
                  }
                },
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _handleDeletePost() async {
    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(l10n.deletePostTitle, style: theme.textTheme.titleLarge),
        content: Text(l10n.deletePostConfirmation, style: theme.textTheme.bodyMedium),
        actions: <Widget>[
          TextButton(child: Text(l10n.cancelButton, style: TextStyle(color: theme.colorScheme.primary)), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
            child: Text(l10n.deleteButton, style: TextStyle(color: theme.colorScheme.error)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final success = await discussionProvider.deletePost(_currentPost.id);
      if (mounted) {
        if (success) {
          _showSuccessSnackBar(l10n.postDeletedSuccess);
          Navigator.of(context).pop();
        } else {
          _showErrorSnackBar(discussionProvider.deleteItemError ?? l10n.postDeleteFailed);
        }
      }
    }
  }

  Future<void> _submitTopLevelComment() async {
    if (!_topLevelCommentFormKey.currentState!.validate()) return;
    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final success = await discussionProvider.createTopLevelComment(
      postId: _currentPost.id,
      commentText: _topLevelCommentController.text.trim(),
    );
    if (mounted) {
      if (success) {
        _topLevelCommentController.clear();
        FocusScope.of(context).unfocus();
        _showSuccessSnackBar(l10n.commentPostedSuccess);
        await _fetchData(forceRefresh: true);
      } else {
        _showErrorSnackBar(discussionProvider.submitCommentError ?? l10n.commentPostFailed);
      }
    }
  }

  void _handleToggleReplyField(int commentId) {
    _cancelEdit();
    setState(() {
      if (_replyingToCommentId == commentId) {
        _replyingToCommentId = null;
      } else {
        _replyingToCommentId = commentId;
        _replyController.clear();
      }
    });
  }

  Future<void> _submitReply(int parentCommentId) async {
    if (!_replyFormKey.currentState!.validate()) return;
    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final success = await discussionProvider.createReply(
      parentCommentId: parentCommentId,
      content: _replyController.text.trim(),
    );
    if (mounted) {
      if (success) {
        _replyController.clear();
        setState(() { _replyingToCommentId = null; });
        FocusScope.of(context).unfocus();
        _showSuccessSnackBar(l10n.replyPostedSuccess);
        await _fetchData(forceRefresh: true);
      } else {
        _showErrorSnackBar(discussionProvider.submitReplyError ?? l10n.replyPostFailed);
      }
    }
  }

  void _startEditComment(Comment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _editingReplyId = null;
      _editingReplyParentCommentId = null;
      _editTextController.text = comment.comment;
      _replyingToCommentId = null;
    });
  }

  void _startEditReply(Reply reply, int parentCommentId) {
    setState(() {
      _editingReplyId = reply.id;
      _editingReplyParentCommentId = parentCommentId;
      _editingCommentId = null;
      _editTextController.text = reply.content;
      _replyingToCommentId = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _editingReplyId = null;
      _editingReplyParentCommentId = null;
      _editTextController.clear();
    });
  }

  Future<void> _submitEdit() async {
    if (!_editFormKey.currentState!.validate()) return;
    final dp = Provider.of<DiscussionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    bool success = false;

    if (_editingCommentId != null) {
      success = await dp.updateComment(
        commentId: _editingCommentId!,
        postId: _currentPost.id,
        newCommentText: _editTextController.text.trim(),
      );
    } else if (_editingReplyId != null && _editingReplyParentCommentId != null) {
      success = await dp.updateReply(
        parentCommentId: _editingReplyParentCommentId!,
        replyId: _editingReplyId!,
        newContent: _editTextController.text.trim(),
      );
    }

    if (mounted) {
      if (success) {
        _cancelEdit();
        _showSuccessSnackBar(l10n.updateGenericSuccess);
        await _fetchData(forceRefresh: true);
      } else {
        _showErrorSnackBar(dp.updateItemError ?? l10n.updateGenericFailed);
      }
    }
  }

  Future<void> _handleDeleteComment(int commentId) async {
    await _confirmDeleteDialog("comment", commentId);
  }

  Future<void> _handleDeleteReply(int replyId, int parentCommentId) async {
    await _confirmDeleteDialog("reply", replyId, parentId: parentCommentId);
  }

  Future<void> _confirmDeleteDialog(String typeKey, int id, {int? parentId}) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    String itemTypeDisplay = typeKey == "comment" ? l10n.commentItemDisplay : l10n.replyItemDisplay;

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text('${l10n.deleteButton} $itemTypeDisplay', style: theme.textTheme.titleLarge), // Using deleteButton for title prefix
        content: Text(l10n.deleteItemConfirmation(itemTypeDisplay), style: theme.textTheme.bodyMedium),
        actions: <Widget>[
          TextButton(child: Text(l10n.cancelButton, style: TextStyle(color: theme.colorScheme.primary)), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
            child: Text(l10n.deleteButton, style: TextStyle(color: theme.colorScheme.error)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final dp = Provider.of<DiscussionProvider>(context, listen: false);
      bool success = false;
      if (typeKey == "comment") {
        success = await dp.deleteComment(commentId: id, postId: _currentPost.id);
      } else if (typeKey == "reply" && parentId != null) {
        success = await dp.deleteReply(parentCommentId: parentId, replyId: id);
      }

      if (mounted) {
        if (success) {
          _showSuccessSnackBar(l10n.itemDeletedSuccess(itemTypeDisplay));
          await _fetchData(forceRefresh: true);
        } else {
          _showErrorSnackBar(dp.deleteItemError ?? l10n.itemDeleteFailed(itemTypeDisplay));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discussionProvider = Provider.of<DiscussionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final comments = discussionProvider.commentsForPost(_currentPost.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPost.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchData(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                children: [
                  PostContentView(
                    post: _currentPost,
                    authProvider: authProvider,
                    onEditPost: _showEditPostDialog,
                    onDeletePost: _handleDeletePost,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      '${l10n.commentsSectionHeader} (${comments.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (discussionProvider.isLoadingCommentsForPost(_currentPost.id) && comments.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(16.0),child: CircularProgressIndicator())),
                  if (discussionProvider.commentErrorForPost(_currentPost.id) != null && comments.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(discussionProvider.commentErrorForPost(_currentPost.id)! ))),
                  if (comments.isEmpty && !discussionProvider.isLoadingCommentsForPost(_currentPost.id) && discussionProvider.commentErrorForPost(_currentPost.id) == null)
                     Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text(l10n.noCommentsYet))),

                  ...comments.map((comment) => CommentItemView(
                        key: ValueKey(comment.id.toString() + comment.updatedAt.toIso8601String()),
                        comment: comment,
                        discussionProvider: discussionProvider,
                        authProvider: authProvider,
                        onToggleReplyField: _handleToggleReplyField,
                        isReplyFieldOpen: _replyingToCommentId == comment.id && _editingCommentId == null && _editingReplyId == null,
                        onSubmitReply: _submitReply,
                        replyController: _replyController,
                        replyFormKey: _replyFormKey,
                        onStartEditComment: _startEditComment,
                        onDeleteComment: _handleDeleteComment,
                        onStartEditReply: _startEditReply,
                        onDeleteReply: _handleDeleteReply,
                      )).toList(),

                  if (_editingCommentId != null || _editingReplyId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: EditInputField(
                          controller: _editTextController,
                          formKey: _editFormKey,
                          isEditingComment: _editingCommentId != null,
                          discussionProvider: discussionProvider,
                          onCancel: _cancelEdit,
                          onSubmit: _submitEdit,
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (authProvider.currentUser != null && _editingCommentId == null && _editingReplyId == null)
            CommentInputField(
              controller: _topLevelCommentController,
              formKey: _topLevelCommentFormKey,
              discussionProvider: discussionProvider,
              onSubmit: _submitTopLevelComment,
              l10n: l10n, // Pass l10n
            ),
        ],
      ),
    );
  }
}

