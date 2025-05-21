// lib/widgets/auth/auth_screen_header.dart
import 'package:flutter/material.dart';

class AuthScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary, // Use theme color
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.7), // Use theme color
          ),
        ),
      ],
    );
  }
}