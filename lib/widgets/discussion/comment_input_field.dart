// lib/widgets/discussion/comment_input_field.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import AppLocalizations

class CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final DiscussionProvider discussionProvider;
  final VoidCallback onSubmit;
  final AppLocalizations l10n; // <<< ADDED l10n parameter

  const CommentInputField({
    super.key,
    required this.controller,
    required this.formKey,
    required this.discussionProvider,
    required this.onSubmit,
    required this.l10n, // <<< ADDED l10n to constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          )
        ],
      ),
      child: Form(
        key: formKey,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.writeCommentHint, // <<< USE l10n
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor?.withOpacity(0.8) ?? theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commentValidationEmpty : null, // <<< USE l10n
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            discussionProvider.isSubmittingComment
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: onSubmit,
                    tooltip: l10n.postCommentTooltip, // <<< USE l10n
                  ),
          ],
        ),
      ),
    );
  }
}