// lib/widgets/auth/auth_navigation_link.dart
import 'package:flutter/material.dart';

class AuthNavigationLink extends StatelessWidget {
  final String leadingText;
  final String linkText;
  final VoidCallback onLinkPressed;

  const AuthNavigationLink({
    super.key,
    required this.leadingText,
    required this.linkText,
    required this.onLinkPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          leadingText,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)), // Use theme color
        ),
        TextButton(
          onPressed: onLinkPressed,
          child: Text(
            linkText,
            style: TextStyle(
              color: theme.colorScheme.primary, // Use theme color
              fontWeight: FontWeight.bold,
            ),
          ),
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft),
        ),
      ],
    );
  }
}