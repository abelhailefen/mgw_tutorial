// lib/screens/sidebar/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
// TODO: Add AppLocalizations import if you use l10n for labels/buttons
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreatePostScreen extends StatefulWidget {
  static const routeName = '/create-post';

  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

 Future<void> _submitPost() async {
  print("[CreatePostScreen] _submitPost: Method entered.");

  if (_formKey.currentState == null) {
    print("[CreatePostScreen] _submitPost: _formKey.currentState is NULL. This is a problem!");
    return;
  }

  if (!_formKey.currentState!.validate()) {
    print("[CreatePostScreen] _submitPost: Form validation failed.");
    return;
  }
  print("[CreatePostScreen] _submitPost: Form validation passed.");
  _formKey.currentState!.save();

  setState(() {
    _isLoading = true;
  });
  print("[CreatePostScreen] _submitPost: _isLoading set to true.");

  final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  print("[CreatePostScreen] _submitPost: Providers fetched.");

  if (authProvider.currentUser == null) {
    print("[CreatePostScreen] _submitPost: authProvider.currentUser is NULL.");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error: User not logged in.')),
      );
    }
    setState(() { _isLoading = false; });
    return;
  }
  print("[CreatePostScreen] _submitPost: authProvider.currentUser.id is ${authProvider.currentUser!.id}");


  print("[CreatePostScreen] _submitPost: Calling discussionProvider.createPost...");
  bool success = false; // Initialize
  String? errorFromProvider;

  try {
    success = await discussionProvider.createPost(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      authProvider: authProvider,
    );
    errorFromProvider = discussionProvider.createPostError; // Get error after the call
    print("[CreatePostScreen] _submitPost: discussionProvider.createPost finished. Success: $success, Error: $errorFromProvider");
  } catch (e) {
    print("[CreatePostScreen] _submitPost: EXCEPTION during discussionProvider.createPost: $e");
    errorFromProvider = "An unexpected client-side error occurred: $e";
    success = false;
  }


  if (mounted) {
    setState(() {
      _isLoading = false;
    });
    print("[CreatePostScreen] _submitPost: _isLoading set to false (after API call).");

    if (success) {
      print("[CreatePostScreen] _submitPost: Post creation successful.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      Navigator.of(context).pop(true);
    } else {
      print("[CreatePostScreen] _submitPost: Post creation failed. Error from provider: $errorFromProvider");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorFromProvider ?? 'Failed to create post. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } else {
     print("[CreatePostScreen] _submitPost: Widget unmounted before UI update for API response.");
  }
}

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!; // Uncomment if using l10n

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'), // TODO: l10n
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Post Title', // TODO: l10n
                  hintText: 'Enter a clear and concise title', // TODO: l10n
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title.'; // TODO: l10n
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters long.'; // TODO: l10n
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Post Description', // TODO: l10n
                  hintText: 'Share your thoughts or questions in detail...', // TODO: l10n
                  alignLabelWithHint: true, // Good for multi-line fields
                ),
                maxLines: 8,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.'; // TODO: l10n
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters long.'; // TODO: l10n
                  }
                  return null;
                },
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitPost,
                      child: const Text('Submit Post'), // TODO: l10n
                    ),
            ],
          ),
        ),
      ),
    );
  }
}