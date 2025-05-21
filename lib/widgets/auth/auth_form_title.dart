// lib/widgets/auth/auth_form_title.dart
import 'package:flutter/material.dart';

class AuthFormTitle extends StatelessWidget {
  final String title;

  const AuthFormTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary, // Use theme color
      ),
    );
  }
}