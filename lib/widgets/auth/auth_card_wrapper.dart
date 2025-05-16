// lib/widgets/auth/auth_card_wrapper.dart
import 'package:flutter/material.dart';

class AuthCardWrapper extends StatelessWidget {
  final Widget child;

  const AuthCardWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: child,
      ),
    );
  }
}