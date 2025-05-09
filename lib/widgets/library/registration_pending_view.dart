import 'package:flutter/material.dart';

class RegistrationPendingView extends StatelessWidget {
  const RegistrationPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 100, color: Colors.blue[700]),
          const SizedBox(height: 24),
          Text(
            'Your request is under verification.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You will gain access to our extensive library of pdfs, notes and video tutorials once your request is verified.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}