// lib/screens/sidebar/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/comment.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:intl/intl.dart'; // For date formatting

class PostDetailScreen extends StatefulWidget {
  static const routeName = '/post-detail';
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _commentFormKey = GlobalKey<FormState>();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
      // Fetch comments only if they are for a different post or not loaded yet
      if (discussionProvider.currentlyViewedPostId != widget.post.id || discussionProvider.currentPostComments.isEmpty) {
        discussionProvider.fetchCommentsForPost(widget.post.id);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (!_commentFormKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;

    setState(() {
      _isSubmittingComment = true;
    });

    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await discussionProvider.createComment(
      postId: widget.post.id,
      commentText: _commentController.text.trim(),
      authProvider: authProvider,
    );

    if (mounted) {
      setState(() {
        _isSubmittingComment = false;
      });
      if (success) {
        _commentController.clear(); // Clear the input field
        FocusScope.of(context).unfocus(); // Dismiss keyboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully!')), // TODO: l10n
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(discussionProvider.commentsError ?? 'Failed to post comment.'), // TODO: l10n
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discussionProvider = Provider.of<DiscussionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // To check if user can comment

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'By: ${widget.post.author.name}', // TODO: l10n
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMd().add_jm().format(widget.post.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    widget.post.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const Divider(height: 32, thickness: 1),
                  Text(
                    'Comments', // TODO: l10n
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildCommentsSection(discussionProvider),
                ],
              ),
            ),
          ),
          if (authProvider.currentUser != null) // Only show comment box if logged in
            _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(DiscussionProvider discussionProvider) {
    if (discussionProvider.isLoadingComments) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
    }
    if (discussionProvider.commentsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text('Error loading comments: ${discussionProvider.commentsError}', style: TextStyle(color: Colors.red[700])),
      );
    }
    if (discussionProvider.currentPostComments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No comments yet. Be the first to comment!', style: Theme.of(context).textTheme.bodyMedium), // TODO: l10n
      );
    }

    return ListView.builder(
      shrinkWrap: true, // Important within SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
      itemCount: discussionProvider.currentPostComments.length,
      itemBuilder: (ctx, index) {
        final comment = discussionProvider.currentPostComments[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            title: Text(comment.author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(comment.comment),
            trailing: Text(
              DateFormat.yMd().add_jm().format(comment.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Or canvasColor
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1), // changes position of shadow
          ),
        ],
      ),
      child: Form(
        key: _commentFormKey,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Write a comment...', // TODO: l10n
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor, // Slightly different background
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Comment cannot be empty.'; // TODO: l10n
                  }
                  return null;
                },
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            _isSubmittingComment
                ? const SizedBox(width: 40, height: 40, child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ))
                : IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                    onPressed: _submitComment,
                    tooltip: 'Post Comment', // TODO: l10n
                  ),
          ],
        ),
      ),
    );
  }
}