// lib/widgets/phone_form_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhoneFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final AppLocalizations l10n;

  const PhoneFormField({
    super.key,
    required this.controller,
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
        labelText: labelText ?? l10n.phoneNumberLabel,
        hintText: hintText ?? l10n.phoneNumberHint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0), // Match contentPadding
          child: Text(
            '+251 ',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)), // Use theme color
          ),
        ),
      ),
      keyboardType: TextInputType.phone,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return l10n.phoneNumberValidationErrorRequired;
        }
        if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
          return l10n.phoneNumberValidationErrorInvalid;
        }
        return null;
      },
    );
  }
}