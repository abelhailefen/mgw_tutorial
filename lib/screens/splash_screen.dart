// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async'; // Import Timer

import 'package:mgw_tutorial/widgets/custom_loading_widget.dart'; // Import the custom widget

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start a timer to navigate after 4 seconds
    Timer(const Duration(seconds: 4), () {
      // Navigate to the login screen and replace the splash screen route
      Navigator.of(context).pushReplacementNamed('/login');
       // OR use a Future if you need to perform async tasks before navigating
      // _performAppInitialization();
    });
  }

  // Optional: If you need to load data or check auth status during splash
  // Future<void> _performAppInitialization() async {
  //    // Example: Check auth status
  //    final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //    await authProvider.tryAutoLogin(); // Or some other init logic
  //
  //    if (authProvider.isAuthenticated) {
  //        Navigator.of(context).pushReplacementNamed('/main'); // Go to main if logged in
  //    } else {
  //        Navigator.of(context).pushReplacementNamed('/login'); // Go to login if not
  //    }
  // }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background color
      body: const CustomLoadingWidget(), // Display the custom loading widget
    );
  }
}