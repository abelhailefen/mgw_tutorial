// lib/widgets/discussion/post_content_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';

class PostContentView extends StatelessWidget {
  final Post post;
  final AuthProvider authProvider;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;

  const PostContentView({
    super.key,
    required this.post,
    required this.authProvider,
    this.onEditPost,
    this.onDeletePost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isAuthor = authProvider.currentUser?.id == post.userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                post.title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground),
              ),
            ),
            if (isAuthor)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.8)),
                color: theme.popupMenuTheme.color, // Use themed popup menu color
                onSelected: (value) {
                  if (value == 'edit' && onEditPost != null) {
                    onEditPost!();
                  } else if (value == 'delete' && onDeletePost != null) {
                    onDeletePost!();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (onEditPost != null)
                     PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                          leading: Icon(Icons.edit_outlined, color: theme.listTileTheme.iconColor),
                          title: Text('Edit Post', style: TextStyle(color: theme.listTileTheme.textColor))), // TODO: Localize
                    ),
                  if (onDeletePost != null)
                     PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                          leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                          title: Text('Delete Post', style: TextStyle(color: theme.colorScheme.error))), // TODO: Localize
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('By: ${post.author.name}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            Text(
              DateFormat.yMMMd().add_jm().format(post.createdAt.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
        Divider(height: 24, thickness: 0.5, color: theme.dividerColor),
        Text(
          post.description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: theme.colorScheme.onSurface),
        ),
        Divider(height: 32, thickness: 1, color: theme.dividerColor),
      ],
    );
  }
}