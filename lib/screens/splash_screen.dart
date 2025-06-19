import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mgw_tutorial/widgets/custom_loading_widget.dart';
import 'package:mgw_tutorial/screens/intro_screen.dart'; // Import the new IntroScreen

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
      Navigator.of(context).pushReplacementNamed('/intro'); // Navigate to IntroScreen
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: const CustomLoadingWidget(),
    );
  }
}