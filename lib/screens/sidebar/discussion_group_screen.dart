// lib/screens/sidebar/discussion_group_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart'; 
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/screens/sidebar/post_detail_screen.dart';
import 'package:intl/intl.dart';
import 'create_post_screen.dart';

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
      if (discussionProvider.posts.isEmpty) {
        discussionProvider.fetchPosts();
      }
    });
  }

  void _navigateToCreatePostScreen() async {
    final result = await Navigator.of(context).pushNamed(CreatePostScreen.routeName);
    if (result == true && mounted) {
      // List will be updated by provider after successful post creation
    }
  }

   void _navigateToPostDetailScreen(Post post) { // Modified
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );
    
  }

  @override
  Widget build(BuildContext context) {
    final discussionProvider = Provider.of<DiscussionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // Get AuthProvider here

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Group'), // TODO: Localize
      ),
      body: RefreshIndicator(
        onRefresh: () => discussionProvider.fetchPosts(),
        child: _buildPostBody(discussionProvider, authProvider), // <<< PASS authProvider HERE
      ),
      floatingActionButton: authProvider.currentUser != null ? FloatingActionButton(
        onPressed: _navigateToCreatePostScreen,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create Post', // TODO: Localize
      ) : null,
    );
  }

  // VVVVV MODIFY METHOD SIGNATURE HERE VVVVV
  Widget _buildPostBody(DiscussionProvider discussionProvider, AuthProvider authProvider) {
  // ^^^^^ PASS authProvider AS ARGUMENT ^^^^^
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
              Text(discussionProvider.postsError!, style: TextStyle(color: Colors.red[700]), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => discussionProvider.fetchPosts(),
                child: const Text('Retry'), // TODO: Localize
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
                'No discussions yet. Be the first to start one!', // TODO: Localize
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 20),
              // VVVVV ACCESS authProvider PASSED AS ARGUMENT VVVVV
              if (authProvider.currentUser != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text("Start a Discussion"), // TODO: Localize
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
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: InkWell(
            onTap: () => _navigateToPostDetailScreen(post),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w600
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By: ${post.author.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm().format(post.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
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