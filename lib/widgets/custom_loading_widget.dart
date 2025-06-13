// lib/widgets/custom_loading_widget.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/constants/color.dart'; // Assuming AppColors is in constants/color.dart

class CustomLoadingWidget extends StatefulWidget {
  const CustomLoadingWidget({super.key});

  @override
  State<CustomLoadingWidget> createState() => _CustomLoadingWidgetState();
}

class _CustomLoadingWidgetState extends State<CustomLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Animation duration
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation back and forth

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Smooth animation curve
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final onBackgroundColor = isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          // Placeholder for your app logo or a themed icon
          ScaleTransition(
            scale: _animation.drive(Tween(begin: 0.8, end: 1.0)), // Scale animation
            child: FadeTransition(
              opacity: _animation, // Fade animation
              child: Image.asset(
                'assets/images/logo.png', // You can replace this with your app logo image
                width: 200.0,
                height: 200.0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'MGW Tutorial', // Your app name
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onBackgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}