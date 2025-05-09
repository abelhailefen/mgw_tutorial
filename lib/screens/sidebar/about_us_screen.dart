import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  // Define the routeName for navigation
  static const String routeName = '/about-us';

  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar's appearance will be controlled by the AppBarTheme in main.dart
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView( // Use SingleChildScrollView if content might overflow
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome to MGW Tutorial!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark, // Or Colors.black
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'MGW Tutorial is dedicated to providing high-quality educational resources to help students excel in their studies. Our platform offers a wide range of tutorials, notes, practice exams, and more, tailored to the curriculum.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Our Mission',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'To empower students with the knowledge and tools they need to achieve academic success and unlock their full potential.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Contact Us',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.email),
              title: Text('info@mgwtutorial.com'),
              // onTap: () { /* TODO: Launch email client */ },
            ),
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('+251 9XX XXX XXX'),
              // onTap: () { /* TODO: Launch phone dialer */ },
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© ${DateTime.now().year} MGW Tutorial. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            )
          ],
        ),
      ),
    );
  }
}