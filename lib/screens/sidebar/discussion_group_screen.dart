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
      // Fetch posts if the list is empty or to ensure freshness on screen entry
      discussionProvider.fetchPosts(); // Consider adding forceRefresh: true if always needed
    });
  }

  void _navigateToCreatePostScreen() async {
    final result = await Navigator.of(context).pushNamed(CreatePostScreen.routeName);
    if (result == true && mounted) {
      // Data will be updated by the provider if createPost was successful and it refetches or adds.
      // Optionally, explicitly call fetchPosts here if needed.
      // Provider.of<DiscussionProvider>(context, listen: false).fetchPosts();
    }
  }

   void _navigateToPostDetailScreen(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discussionProvider = Provider.of<DiscussionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context); // Get theme

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discussiongroup),
      ),
      body: RefreshIndicator(
        onRefresh: () => discussionProvider.fetchPosts(),
        child: _buildPostBody(discussionProvider, authProvider, theme, l10n), // Pass theme & l10n
      ),
      floatingActionButton: authProvider.currentUser != null ? FloatingActionButton(
        onPressed: _navigateToCreatePostScreen,
        // --- COLOR CORRECTION FOR FAB ---
        backgroundColor: theme.colorScheme.primary, // Will be dark blue on light, light blue on dark
        child: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary, // Should contrast with primary
        ),
        // --- END COLOR CORRECTION ---
        tooltip: l10n.appTitle.contains("መጂወ") ? "ልጥፍ ፍጠር" : 'Create Post',
      ) : null,
    );
  }

  Widget _buildPostBody(DiscussionProvider discussionProvider, AuthProvider authProvider, ThemeData theme, AppLocalizations l10n) {
    if (discussionProvider.isLoadingPosts && discussionProvider.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (discussionProvider.postsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(discussionProvider.postsError!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
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
              Text(
                l10n.appTitle.contains("መጂወ") ? 'ምንም ውይይቶች የሉም። የመጀመሪያ ይሁኑ!' : 'No discussions yet. Be the first to start one!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
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
        return Card(
          // elevation, margin, shape from CardTheme
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
                          color: theme.colorScheme.primary, // Make title stand out
                          fontWeight: FontWeight.w600
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.85)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By: ${post.author.name}', // TODO: Localize "By: "
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