// lib/widgets/discussion/shared_discussion_input_field.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
class SharedDiscussionInputField extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final String hintText;
  final String submitButtonTooltip;
  final bool isLoading;
  final VoidCallback onSubmit;
  final FormFieldValidator<String>? validator;
  final AppLocalizations l10n;
  final FocusNode? focusNode;

  const SharedDiscussionInputField({
    super.key,
    required this.controller,
    required this.formKey,
    required this.hintText,
    required this.submitButtonTooltip,
    required this.isLoading,
    required this.onSubmit,
    this.validator,
    required this.l10n,
    this.focusNode,
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
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Form(
        key: formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor?.withOpacity(0.8) ?? theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  isDense: true,
                ),
                validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? l10n.editFieldValidationEmpty : null,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => onSubmit(),
                maxLines: 3, 
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            isLoading
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
                    tooltip: submitButtonTooltip,
                  ),
          ],
        ),
      ),
    );
  }
}