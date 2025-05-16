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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          leadingText,
          style: TextStyle(color: Colors.grey[700]),
        ),
        TextButton(
          onPressed: onLinkPressed,
          child: Text(
            linkText,
            style: TextStyle(
              color: Colors.blue[700],
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