// lib/widgets/password_form_field.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

class PasswordFormField extends StatelessWidget {
  final TextEditingController controller;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final AppLocalizations l10n;

  const PasswordFormField({
    super.key,
    required this.controller,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    this.labelText,
    this.hintText,
    this.validator,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        // labelText, hintText, border, contentPadding will be largely handled by main.dart's InputDecorationTheme
        labelText: labelText ?? l10n.passwordLabel,
        hintText: hintText ?? l10n.passwordHint,
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: theme.iconTheme.color?.withOpacity(0.7), // Use theme icon color
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      obscureText: !isPasswordVisible,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return l10n.passwordValidationErrorRequired;
        }
        if (value.length < 6) {
          return l10n.passwordValidationErrorLength;
        }
        return null;
      },
    );
  }
}