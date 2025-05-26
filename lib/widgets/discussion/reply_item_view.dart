// lib/widgets/discussion/reply_item_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mgw_tutorial/models/reply.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Define InputMode here
enum InputMode { none, commentingPost, replyingToComment, replyingToReply }

class ReplyItemView extends StatelessWidget {
  final Reply reply;
  final int originalCommentId; // The ID of the top-level comment this reply chain belongs to
  final DiscussionProvider discussionProvider;
  final AuthProvider authProvider;
  final Function({
    required InputMode mode, // This will now refer to the local enum
    required int targetCommentId,
    int? targetReplyId,
    String? targetAuthorName,
  }) onStartReplyFlow; // To activate input field in PostDetailScreen
  final Function(Reply reply) onStartEditReply;
  final Function(int replyId, int parentCommentId) onDeleteReply;

  const ReplyItemView({
    super.key,
    required this.reply,
    required this.originalCommentId,
    required this.discussionProvider,
    required this.authProvider,
    required this.onStartReplyFlow,
    required this.onStartEditReply,
    required this.onDeleteReply,
  });

  void _showReplyActionMenu(BuildContext context, Reply currentReply) {
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
              title: Text(l10n.appTitle.contains("መጂወ") ? "መልስ አስተካክል" : "Edit Reply", style: TextStyle(color: theme.listTileTheme.textColor)),
              onTap: () {
                Navigator.pop(ctx);
                onStartEditReply(currentReply);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text(l10n.appTitle.contains("መጂወ") ? "መልስ ሰርዝ" : "Delete Reply", style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                onDeleteReply(currentReply.id, originalCommentId); // parentCommentId is the original comment
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
    bool isReplyAuthor = authProvider.currentUser?.id == reply.userId;

    return Container(
      margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? theme.colorScheme.surfaceVariant.withOpacity(0.6)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.author.name,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 13
                      ),
                    ),
                    const SizedBox(height: 1),
                     Text(
                      DateFormat.yMd().add_jm().format(reply.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              if (isReplyAuthor)
                SizedBox(
                  height: 24,
                  width: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, size: 16, color: theme.iconTheme.color?.withOpacity(0.7)),
                    onPressed: () => _showReplyActionMenu(context, reply),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(reply.content, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (authProvider.currentUser != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: theme.colorScheme.primary,
                ),
                onPressed: () {
                  onStartReplyFlow(
                    mode: InputMode.replyingToReply,
                    targetCommentId: originalCommentId, // Always the top-level comment ID
                    targetReplyId: reply.id,            // The ID of the reply we are replying to
                    targetAuthorName: reply.author.name,
                  );
                },
                child: Text(l10n.replyButtonLabel, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
          if (reply.childReplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reply.childReplies
                    .map((childReply) => ReplyItemView(
                          reply: childReply,
                          originalCommentId: originalCommentId,
                          discussionProvider: discussionProvider,
                          authProvider: authProvider,
                          onStartReplyFlow: onStartReplyFlow,
                          onStartEditReply: onStartEditReply,
                          onDeleteReply: onDeleteReply,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}