// lib/widgets/discussion/comment_item_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mgw_tutorial/models/comment.dart';
import 'package:mgw_tutorial/models/reply.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/widgets/discussion/reply_item_view.dart'; 
import 'package:mgw_tutorial/l10n/app_localizations.dart';


class CommentItemView extends StatefulWidget {
  final Comment comment;
  final DiscussionProvider discussionProvider;
  final AuthProvider authProvider;
  
  final Function({
    required InputMode mode,
    required int targetCommentId,
    int? targetReplyId, 
    String? targetAuthorName,
  }) onStartReplyFlow;

  final Function(Comment comment) onStartEditComment;
  final Function(int commentId) onDeleteComment;
  final Function(Reply reply) onStartEditReply; 
  final Function(int replyId, int parentCommentId) onDeleteReply; 

  const CommentItemView({
    super.key,
    required this.comment,
    required this.discussionProvider,
    required this.authProvider,
    required this.onStartReplyFlow,
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
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit_outlined, color: theme.listTileTheme.iconColor),
              title: Text(l10n.appTitle.contains("መጂወ") ? "አስተያየት አስተካክል" : "Edit Comment", style: TextStyle(color: theme.listTileTheme.textColor)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onStartEditComment(comment);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text(l10n.appTitle.contains("መጂወ") ? "አስተያየት ሰርዝ" : "Delete Comment", style: TextStyle(color: theme.colorScheme.error)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final List<Reply> topLevelReplies = widget.discussionProvider.repliesForComment(widget.comment.id);
    final bool isLoadingReplies = widget.discussionProvider.isLoadingRepliesForComment(widget.comment.id);
    final String? replyError = widget.discussionProvider.replyErrorForComment(widget.comment.id);
    bool isCommentAuthor = widget.authProvider.currentUser?.id == widget.comment.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                widget.comment.author.name.isNotEmpty ? widget.comment.author.name[0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
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
            padding: const EdgeInsets.only(left: 72.0, bottom: 8.0, right: 16.0, top:0),
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
                    onPressed: () => widget.onStartReplyFlow(
                      mode: InputMode.replyingToComment,
                      targetCommentId: widget.comment.id,
                      targetAuthorName: widget.comment.author.name,
                    ),
                    child: Text(l10n.replyButtonLabel, style: const TextStyle(fontSize: 13)),
                  ),
                  const Spacer(),
                  if (widget.comment.replyCount > 0)
                    Text(
                      '${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? (l10n.appTitle.contains("መጂወ") ? "መልስ" : "reply") : (l10n.appTitle.contains("መጂወ") ? "መልሶች" : "replies")}', 
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
              ],
            ),
          ),
          
          if (isLoadingReplies && topLevelReplies.isEmpty)
            const Padding(padding: EdgeInsets.only(left: 72.0, right: 16.0, bottom: 8.0), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
          if (replyError != null && topLevelReplies.isEmpty && !isLoadingReplies)
              Padding(padding: const EdgeInsets.only(left: 72.0, right: 16.0, bottom: 8.0), child: Text(replyError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))),
          
          if (topLevelReplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(72.0, 0, 16.0, 8.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topLevelReplies.map((reply) => ReplyItemView(
                        key: ValueKey('reply-${reply.id}-${reply.updatedAt}'), 
                        reply: reply,
                        originalCommentId: widget.comment.id, 
                        discussionProvider: widget.discussionProvider,
                        authProvider: widget.authProvider,
                        onStartReplyFlow: widget.onStartReplyFlow,
                        onStartEditReply: widget.onStartEditReply, 
                        onDeleteReply: widget.onDeleteReply,  
                      )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}