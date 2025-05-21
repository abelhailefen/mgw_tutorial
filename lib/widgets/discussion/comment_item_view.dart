// lib/widgets/discussion/comment_item_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mgw_tutorial/models/comment.dart';
import 'package:mgw_tutorial/models/reply.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';

class CommentItemView extends StatefulWidget {
  final Comment comment;
  final DiscussionProvider discussionProvider;
  final AuthProvider authProvider;
  final Function(int commentId) onToggleReplyField;
  final bool isReplyFieldOpen;
  final Function(int commentId) onSubmitReply;
  final TextEditingController replyController;
  final GlobalKey<FormState> replyFormKey;
  final Function(Comment comment) onStartEditComment;
  final Function(int commentId) onDeleteComment;
  final Function(Reply reply, int parentCommentId) onStartEditReply;
  final Function(int replyId, int parentCommentId) onDeleteReply;

  const CommentItemView({
    super.key,
    required this.comment,
    required this.discussionProvider,
    required this.authProvider,
    required this.onToggleReplyField,
    required this.isReplyFieldOpen,
    required this.onSubmitReply,
    required this.replyController,
    required this.replyFormKey,
    required this.onStartEditComment,
    required this.onDeleteComment,
    required this.onStartEditReply,
    required this.onDeleteReply,
  });

  @override
  State<CommentItemView> createState() => _CommentItemViewState();
}

class _CommentItemViewState extends State<CommentItemView> {
  void _showCommentActionMenu(BuildContext context, Comment comment) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor, // Use theme for modal bg
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit_outlined, color: theme.listTileTheme.iconColor),
              title: Text('Edit Comment', style: TextStyle(color: theme.listTileTheme.textColor)), // TODO: Localize
              onTap: () {
                Navigator.pop(ctx);
                widget.onStartEditComment(comment);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('Delete Comment', style: TextStyle(color: theme.colorScheme.error)), // TODO: Localize
              onTap: () {
                Navigator.pop(ctx);
                widget.onDeleteComment(comment.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _showReplyActionMenu(BuildContext context, Reply reply, int parentCommentId) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit_outlined, color: theme.listTileTheme.iconColor),
              title: Text('Edit Reply', style: TextStyle(color: theme.listTileTheme.textColor)), // TODO: Localize
              onTap: () {
                Navigator.pop(ctx);
                widget.onStartEditReply(reply, parentCommentId);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('Delete Reply', style: TextStyle(color: theme.colorScheme.error)), // TODO: Localize
              onTap: () {
                Navigator.pop(ctx);
                widget.onDeleteReply(reply.id, parentCommentId);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Reply> replies = widget.discussionProvider.repliesForComment(widget.comment.id);
    final bool isLoadingReplies = widget.discussionProvider.isLoadingRepliesForComment(widget.comment.id);
    final String? replyError = widget.discussionProvider.replyErrorForComment(widget.comment.id);
    bool isCommentAuthor = widget.authProvider.currentUser?.id == widget.comment.userId;

    return Card(
      // elevation and shape are themed
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(widget.comment.author.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(widget.comment.comment, style: theme.textTheme.bodyMedium),
            ),
            trailing: isCommentAuthor
              ? IconButton(
                  icon: Icon(Icons.more_vert, size: 20, color: theme.iconTheme.color?.withOpacity(0.7)),
                  onPressed: () => _showCommentActionMenu(context, widget.comment),
                )
              : Text(
                  DateFormat.yMd().add_jm().format(widget.comment.createdAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: 16.0,
                bottom: widget.isReplyFieldOpen ? 0 : 8.0,
                right: 8.0,
                top:0
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (widget.authProvider.currentUser != null)
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.primary,
                    ),
                    onPressed: () => widget.onToggleReplyField(widget.comment.id),
                    child: Text(widget.isReplyFieldOpen ? 'Cancel' : 'Reply', style: const TextStyle(fontSize: 13)), // TODO: Localize
                  ),
              ],
            ),
          ),
          if (widget.isReplyFieldOpen) _buildReplyInputField(theme),

          if (isLoadingReplies && replies.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
          if (replyError != null && replies.isEmpty && !isLoadingReplies)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0), child: Text(replyError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: replies.map((reply) => _buildReplyItem(context, reply, theme)).toList(),
              ),
            ),
          if (!isLoadingReplies && !widget.discussionProvider.allRepliesLoadedForComment(widget.comment.id) && widget.comment.replyCount > replies.length)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.secondary),
                onPressed: () => widget.discussionProvider.fetchRepliesForComment(widget.comment.id, forceRefresh: true),
                child: Text('View all ${widget.comment.replyCount} replies...', style: const TextStyle(fontSize: 13)), // TODO: Localize
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyInputField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
      child: Form(
        key: widget.replyFormKey,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: widget.replyController,
                autofocus: true,
                decoration: InputDecoration( // Uses global theme, can override specific parts
                    hintText: 'Write a reply...', // TODO: Localize
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0), borderSide: BorderSide(color: theme.colorScheme.outline))
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Reply cannot be empty.' : null, // TODO: Localize
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => widget.onSubmitReply(widget.comment.id),
              ),
            ),
            const SizedBox(width: 8),
            widget.discussionProvider.isSubmittingReply
                ? const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(2.0), child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(icon: Icon(Icons.send, color: theme.colorScheme.primary, size: 24), onPressed: () => widget.onSubmitReply(widget.comment.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyItem(BuildContext context, Reply reply, ThemeData theme) {
    bool isReplyAuthor = widget.authProvider.currentUser?.id == reply.userId;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5), // Use a variant for reply background
        borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reply.author.name, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (isReplyAuthor)
                SizedBox(
                  height: 24, width: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, size: 16, color: theme.iconTheme.color?.withOpacity(0.7)),
                    onPressed: () => _showReplyActionMenu(context, reply, widget.comment.id),
                  ),
                )
              else
                Text(
                  DateFormat.yMd().add_jm().format(reply.createdAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(reply.content, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}