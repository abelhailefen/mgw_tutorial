// lib/widgets/discussion/edit_input_field.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';

class EditInputField extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final bool isEditingComment;
  final DiscussionProvider discussionProvider;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const EditInputField({
    super.key,
    required this.controller,
    required this.formKey,
    required this.isEditingComment,
    required this.discussionProvider,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: controller,
              decoration: InputDecoration( // Uses global theme
                hintText: 'Edit your ${isEditingComment ? "comment" : "reply"}...', // TODO: Localize
                // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                // filled: true,
                // fillColor: theme.inputDecorationTheme.fillColor ?? theme.scaffoldBackgroundColor,
              ),
              maxLines: 3,
              minLines: 1,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Cannot be empty' : null, // TODO: Localize
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface.withOpacity(0.8)),
                    child: const Text("Cancel") // TODO: Localize
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: discussionProvider.isUpdatingItem ? null : onSubmit,
                  child: discussionProvider.isUpdatingItem
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Or use theme.colorScheme.onPrimary
                          ),
                        )
                      : const Text("Save Changes"), // TODO: Localize
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}