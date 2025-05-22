// lib/screens/sidebar/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/models/comment.dart';
import 'package:mgw_tutorial/models/reply.dart';
import 'package:mgw_tutorial/models/author.dart'; // <-- Import Author model
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/widgets/discussion/post_content_view.dart';
import 'package:mgw_tutorial/widgets/discussion/comment_item_view.dart';
import 'package:mgw_tutorial/widgets/discussion/edit_input_field.dart';
import 'package:mgw_tutorial/widgets/discussion/shared_discussion_input_field.dart'; 
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/widgets/discussion/reply_item_view.dart' show InputMode; 
import 'package:intl/intl.dart';


class PostDetailScreen extends StatefulWidget {
  static const routeName = '/post-detail';
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _sharedInputController = TextEditingController();
  final _sharedInputFormKey = GlobalKey<FormState>();
  final FocusNode _sharedInputFocusNode = FocusNode();

  InputMode _currentInputMode = InputMode.commentingPost;
  int? _currentTargetCommentId; 
  int? _currentTargetReplyId;   
  String? _currentTargetAuthorName; 

  int? _editingCommentId;
  int? _editingReplyId;
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
          if (_currentPost.id != updatedPostFromList.id && !discussionProvider.posts.any((p) => p.id == _currentPost.id)) {
             print("Post appears to have been deleted. Navigating back.");
             return; 
          }
        setState(() {
          _currentPost = updatedPostFromList;
        });
      }
    }
    
    await discussionProvider.fetchCommentsForPost(_currentPost.id, forceRefresh: forceRefresh);
  }

  @override
  void dispose() {
    _sharedInputController.dispose();
    _sharedInputFocusNode.dispose();
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
          final isLoadingUpdate = context.watch<DiscussionProvider>().isUpdatingItem;

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
                onPressed: isLoadingUpdate ? null : () => Navigator.of(ctx).pop()
              ),
              ElevatedButton(
                child: isLoadingUpdate
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)))
                    : Text(l10n.saveButton),
                onPressed: isLoadingUpdate ? null : () async {
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

  void _handleStartReplyFlow({
    required InputMode mode,
    required int targetCommentId, 
    int? targetReplyId,          
    String? targetAuthorName,
  }) {
    _cancelEdit(); 
    setState(() {
      _currentInputMode = mode;
      _currentTargetCommentId = targetCommentId;
      _currentTargetReplyId = targetReplyId;
      _currentTargetAuthorName = targetAuthorName;

      if (targetAuthorName != null && targetAuthorName.isNotEmpty) {
        _sharedInputController.text = '@$targetAuthorName ';
        _sharedInputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _sharedInputController.text.length),
        );
      } else {
        _sharedInputController.clear();
      }
    });
    FocusScope.of(context).requestFocus(_sharedInputFocusNode);
  }

  void _resetInputModeToCommentingPost() {
    setState(() {
      _currentInputMode = InputMode.commentingPost;
      _currentTargetCommentId = null;
      _currentTargetReplyId = null;
      _currentTargetAuthorName = null;
      _sharedInputController.clear();
    });
  }

  Future<void> _submitSharedInput() async {
    if (!_sharedInputFormKey.currentState!.validate()) return;

    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    String content = _sharedInputController.text.trim();

    switch (_currentInputMode) {
      case InputMode.commentingPost:
        success = await discussionProvider.createTopLevelComment(
          postId: _currentPost.id,
          commentText: content,
        );
        if (success) _showSuccessSnackBar(l10n.commentPostedSuccess);
        if (!success) _showErrorSnackBar(discussionProvider.submitCommentError ?? l10n.commentPostFailed);
        break;
      case InputMode.replyingToComment:
      case InputMode.replyingToReply: 
        if (_currentTargetCommentId != null) {
          success = await discussionProvider.createReply(
            parentCommentId: _currentTargetCommentId!,
            content: content,
            parentReplyId: _currentTargetReplyId, 
          );
          if (success) _showSuccessSnackBar(l10n.replyPostedSuccess);
          if (!success) _showErrorSnackBar(discussionProvider.submitReplyError ?? l10n.replyPostFailed);
        }
        break;
      default:
        return;
    }

    if (mounted) {
      if (success) {
        _resetInputModeToCommentingPost();
        FocusScope.of(context).unfocus();
        await _fetchData(forceRefresh: true);
      }
    }
  }


  void _startEditComment(Comment comment) {
    _resetInputModeToCommentingPost(); 
    setState(() {
      _editingCommentId = comment.id;
      _editingReplyId = null;
      _editTextController.text = comment.comment;
    });
  }

  void _startEditReply(Reply reply) {
    _resetInputModeToCommentingPost(); 
    setState(() {
      _editingReplyId = reply.id;
      _editingCommentId = null;
      _editTextController.text = reply.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _editingReplyId = null;
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
    } else if (_editingReplyId != null) {
      Reply? replyToEdit;
      Comment? parentCommentOfReply;

      final comments = dp.commentsForPost(_currentPost.id);
      for (var comment in comments) {
        var directReply = comment.replies.firstWhere((r) => r.id == _editingReplyId, orElse: () => Reply(id: -2, content: '', userId: -1, commentId: -1, createdAt: DateTime.now(), updatedAt: DateTime.now(), author: Author(id: -2, name: 'NotFound')));
        if (directReply.id == _editingReplyId) {
          replyToEdit = directReply;
          parentCommentOfReply = comment;
          break;
        }
        
        Reply? findNested(List<Reply> children) {
          for (var child in children) {
            if (child.id == _editingReplyId) return child;
            var grandChild = findNested(child.childReplies);
            if (grandChild != null) return grandChild; 
          }
          return null;
        }
        Reply? nestedReply = findNested(comment.replies); 
         if (nestedReply != null) { 
          replyToEdit = nestedReply;
          parentCommentOfReply = comment;
          break;
        }
      }

      if (replyToEdit != null && parentCommentOfReply != null) {
         success = await dp.updateReply(
            parentCommentId: parentCommentOfReply.id, 
            replyId: _editingReplyId!,
            newContent: _editTextController.text.trim(),
          );
      } else {
        _showErrorSnackBar("Could not find reply to edit."); 
      }
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
    final l10n = AppLocalizations.of(context)!;
    await _confirmDeleteDialog(l10n.commentItemDisplay, commentId);
  }

  Future<void> _handleDeleteReply(int replyId, int parentCommentId) {
    final l10n = AppLocalizations.of(context)!;
    return _confirmDeleteDialog(l10n.replyItemDisplay, replyId, originalCommentId: parentCommentId);
  }

  Future<void> _confirmDeleteDialog(String itemTypeDisplay, int id, {int? originalCommentId}) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text('${l10n.deleteButton} $itemTypeDisplay', style: theme.textTheme.titleLarge),
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
      if (itemTypeDisplay == l10n.commentItemDisplay) {
        success = await dp.deleteComment(commentId: id, postId: _currentPost.id);
      } else if (itemTypeDisplay == l10n.replyItemDisplay && originalCommentId != null) {
        success = await dp.deleteReply(parentCommentId: originalCommentId, replyId: id);
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

  String _getInputHintText(AppLocalizations l10n) {
    switch (_currentInputMode) {
      case InputMode.commentingPost:
        return l10n.writeCommentHint;
      case InputMode.replyingToComment:
      case InputMode.replyingToReply:
        return l10n.writeReplyHint;
      default:
        return l10n.writeCommentHint;
    }
  }
   String _getSubmitTooltip(AppLocalizations l10n) {
    switch (_currentInputMode) {
      case InputMode.commentingPost:
        return l10n.postCommentTooltip;
      case InputMode.replyingToComment:
      case InputMode.replyingToReply:
        return l10n.appTitle.contains("መጂወ") ? "መልስ ለጥፍ" : "Post Reply"; 
      default:
        return l10n.postCommentTooltip;
    }
  }


  @override
  Widget build(BuildContext context) {
    final discussionProvider = Provider.of<DiscussionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final comments = discussionProvider.commentsForPost(_currentPost.id);

    // Calculate total number of discussion items (post + comments + all replies)
    // This is a rough count for the progress indicator
    int totalItems = 1; // For the post itself
    for (var comment in comments) {
      totalItems++; // For the comment
      totalItems += comment.replyCount; // Add count of all its replies (nested included from API count)
    }

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
                        key: ValueKey('comment-${comment.id}-${comment.updatedAt}'), 
                        comment: comment,
                        discussionProvider: discussionProvider,
                        authProvider: authProvider,
                        onStartReplyFlow: _handleStartReplyFlow,
                        onStartEditComment: _startEditComment,
                        onDeleteComment: _handleDeleteComment,
                        onStartEditReply: _startEditReply, 
                        onDeleteReply: _handleDeleteReply,
                      )).toList(),

                  if (_editingCommentId != null || _editingReplyId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0), 
                      child: EditInputField(
                          controller: _editTextController,
                          formKey: _editFormKey,
                          isEditingComment: _editingCommentId != null,
                          discussionProvider: discussionProvider, 
                          onCancel: _cancelEdit,
                          onSubmit: _submitEdit,
                      ),
                    ),
                  const SizedBox(height: 16), 
                ],
              ),
            ),
          ),
          if (authProvider.currentUser != null && !(_editingCommentId != null || _editingReplyId != null))
            SharedDiscussionInputField(
              controller: _sharedInputController,
              formKey: _sharedInputFormKey,
              hintText: _getInputHintText(l10n),
              submitButtonTooltip: _getSubmitTooltip(l10n),
              isLoading: discussionProvider.isSubmittingComment || discussionProvider.isSubmittingReply,
              onSubmit: _submitSharedInput,
              l10n: l10n,
              focusNode: _sharedInputFocusNode,
            ),
        ],
      ),
    );
  }
}