// lib/screens/sidebar/discussion_group_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/screens/sidebar/post_detail_screen.dart';
import 'package:intl/intl.dart';
import 'create_post_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For localization

class DiscussionGroupScreen extends StatefulWidget {
  static const routeName = '/discussion-group';

  const DiscussionGroupScreen({super.key});

  @override
  State<DiscussionGroupScreen> createState() => _DiscussionGroupScreenState();
}

class _DiscussionGroupScreenState extends State<DiscussionGroupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
      if (discussionProvider.posts.isEmpty || discussionProvider.postsError != null) { // Fetch if empty or error
        discussionProvider.fetchPosts();
      }
    });
  }

  void _navigateToCreatePostScreen() async {
    final result = await Navigator.of(context).pushNamed(CreatePostScreen.routeName);
    if (result == true && mounted) {
      // List will be updated by provider after successful post creation
      // Optionally, show a snackbar or trigger a refresh if needed, though provider should handle UI update.
    }
  }

   void _navigateToPostDetailScreen(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post), // No need for Provider here directly
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discussionProvider = Provider.of<DiscussionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discussiongroup),
      ),
      body: RefreshIndicator(
        onRefresh: () => discussionProvider.fetchPosts(),
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: _buildPostBody(discussionProvider, authProvider, l10n, theme),
      ),
      floatingActionButton: authProvider.currentUser != null ? FloatingActionButton(
        onPressed: _navigateToCreatePostScreen,
        // backgroundColor will be themed by FloatingActionButtonThemeData if defined, or use theme.colorScheme.secondary
        child: Icon(Icons.add, color: theme.colorScheme.onSecondary), // Assuming onSecondary is contrasting
        tooltip: l10n.appTitle.contains("መጂወ") ? 'ልጥፍ ፍጠር' : 'Create Post',
      ) : null,
    );
  }

  Widget _buildPostBody(DiscussionProvider discussionProvider, AuthProvider authProvider, AppLocalizations l10n, ThemeData theme) {
    if (discussionProvider.isLoadingPosts && discussionProvider.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (discussionProvider.postsError != null && discussionProvider.posts.isEmpty) { // Show error only if list is empty
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  discussionProvider.postsError!, // TODO: Better error localization
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => discussionProvider.fetchPosts(),
                child: Text(l10n.refresh),
              )
            ],
          ),
        ),
      );
    }

    if (!discussionProvider.isLoadingPosts && discussionProvider.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 70, color: theme.iconTheme.color?.withOpacity(0.5)),
              const SizedBox(height: 20),
              Text(
                l10n.appTitle.contains("መጂወ") ? 'እስካሁን ምንም ውይይቶች የሉም። የመጀመሪያውን ለመጀመር ይሁኑ!' : 'No discussions yet. Be the first to start one!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              if (authProvider.currentUser != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_comment_outlined),
                  label: Text(l10n.appTitle.contains("መጂወ") ? "ውይይት ጀምር" : "Start a Discussion"),
                  onPressed: _navigateToCreatePostScreen,
                )
            ],
          ),
        )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: discussionProvider.posts.length,
      itemBuilder: (ctx, index) {
        final post = discussionProvider.posts[index];
        return Card( // Uses CardTheme
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: InkWell(
            onTap: () => _navigateToPostDetailScreen(post),
            borderRadius: BorderRadius.circular(theme.cardTheme.shape is RoundedRectangleBorder ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(Directionality.of(context)).bottomLeft.x : 12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary, // Make titles stand out
                          fontWeight: FontWeight.w600
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // TODO: Localize 'By: '
                        'By: ${post.author.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm().format(post.createdAt.toLocal()),
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}