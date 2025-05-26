import 'package:flutter/material.dart';

class RegistrationDeniedView extends StatelessWidget {
  final VoidCallback onRegisterNow;
  const RegistrationDeniedView({super.key, required this.onRegisterNow});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.cancel, size: 100, color: Colors.red[700]),
          const SizedBox(height: 24),
          Text(
            'Your request has been denied!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your request has been denied because the screenshot you have sent was invalid. Please provide a valid screenshot.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRegisterNow,
             style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('Get Registered Now'),
          ),
        ],
      ),
    );
  }
}