// lib/widgets/phone_form_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhoneFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText; // Make label optional or use l10n directly
  final String? hintText;  // Make hint optional or use l10n directly
  final FormFieldValidator<String>? validator;
  final AppLocalizations l10n; // To access localized strings

  const PhoneFormField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    required this.l10n, // Pass AppLocalizations instance
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText ?? l10n.phoneNumberLabel,
        hintText: hintText ?? l10n.phoneNumberHint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
          child: Text(
            '+251 ', // Or make this configurable if needed
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
        border: const OutlineInputBorder(), // Ensure border is consistent
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      ),
      keyboardType: TextInputType.phone,
      validator: validator ?? (value) { // Default validator using l10n
        if (value == null || value.isEmpty) {
          return l10n.phoneNumberValidationErrorRequired;
        }
        if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) { // Assumes 9 digits after +251
          return l10n.phoneNumberValidationErrorInvalid;
        }
        return null;
      },
    );
  }
}