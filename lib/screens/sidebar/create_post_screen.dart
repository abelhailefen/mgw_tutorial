// lib/screens/sidebar/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For localization

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    bool success = await discussionProvider.createPost(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
               content: Text(l10n.appTitle.contains("መጂወ") ? 'ልጥፍ በተሳካ ሁኔታ ተፈጥሯል!' : 'Post created successfully!'),
               backgroundColor: theme.colorScheme.primaryContainer,
               behavior: SnackBarBehavior.floating,
           ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(discussionProvider.submitPostError ?? (l10n.appTitle.contains("መጂወ") ? 'ልጥፍ መፍጠር አልተሳካም። እባክዎ እንደገና ይሞክሩ።' : 'Failed to create post. Please try again.')),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discussionProvider = Provider.of<DiscussionProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    // final theme = Theme.of(context); // Not strictly needed here as InputDecorationTheme handles it

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle.contains("መጂወ") ? 'አዲስ ልጥፍ ፍጠር' : 'Create New Post'),
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
                decoration: InputDecoration(
                  labelText: l10n.appTitle.contains("መጂወ") ? 'የልጥፍ ርዕስ' : 'Post Title',
                  hintText: l10n.appTitle.contains("መጂወ") ? 'ግልጽ እና አጭር ርዕስ ያስገቡ' : 'Enter a clear and concise title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.appTitle.contains("መጂወ") ? 'እባክዎ ርዕስ ያስገቡ።' : 'Please enter a title.';
                  }
                  if (value.trim().length < 5) {
                    return l10n.appTitle.contains("መጂወ") ? 'ርዕስ ቢያንስ 5 ቁምፊዎች መሆን አለበት።' : 'Title must be at least 5 characters long.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.appTitle.contains("መጂወ") ? 'የልጥፍ መግለጫ' : 'Post Description',
                  hintText: l10n.appTitle.contains("መጂወ") ? 'ሀሳቦችዎን ወይም ጥያቄዎችዎን በዝርዝር ያካፍሉ...' : 'Share your thoughts or questions in detail...',
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.appTitle.contains("መጂወ") ? 'እባክዎ መግለጫ ያስገቡ።' : 'Please enter a description.';
                  }
                  if (value.trim().length < 10) {
                    return l10n.appTitle.contains("መጂወ") ? 'መግለጫ ቢያንስ 10 ቁምፊዎች መሆን አለበት።' : 'Description must be at least 10 characters long.';
                  }
                  return null;
                },
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),
              discussionProvider.isSubmittingPost
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitPost,
                      child: Text(l10n.appTitle.contains("መጂወ") ? 'ልጥፍ አስገባ' : 'Submit Post'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}