// lib/widgets/auth/auth_screen_header.dart

import 'package:flutter/material.dart';
// Assuming you might use l10n for context, keep the import if it was there
// import 'package:mgw_tutorial/l10n/app_localizations.dart';


// Change from StatelessWidget to StatefulWidget to manage animation state
class AuthScreenHeader extends StatefulWidget {
  const AuthScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<AuthScreenHeader> createState() => _AuthScreenHeaderState();
}

// Add SingleTickerProviderStateMixin for the AnimationController
class _AuthScreenHeaderState extends State<AuthScreenHeader> with SingleTickerProviderStateMixin {
  // Declare animation variables
  late AnimationController _controller;

  // Animations for the Title
  late Animation<double> _titleFadeAnimation;

  // Animations for the Subtitle (fade and slide)
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController with a duration suitable for the *entire sequence*
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500), // Total duration for the sequence (adjust as needed, e.g., 3000 for 3s)
      vsync: this, // Use the SingleTickerProviderStateMixin
    );

    // Define Intervals for sequencing the animations within the controller's duration (0.0 to 1.0)
    // The title fades in during the first part of the animation
    const titleFadeInterval = Interval(0.0, 0.3, curve: Curves.easeOut); // Title fades from 0% to 30% of the total time

    // The subtitle animation starts shortly after the title begins and takes longer
    const subtitleStart = 0.2; // Subtitle animation starts at 20% of the total time
    const subtitleInterval = Interval(subtitleStart, 1.0, curve: Curves.easeOutCubic); // Subtitle animates from 20% to 100% of the total time

    // Create animations for the Title
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: titleFadeInterval, // Apply the specific interval for the title
      ),
    );

    // Create animations for the Subtitle
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
       CurvedAnimation(
         parent: _controller,
         curve: subtitleInterval, // Apply the specific interval for the subtitle fade
       ),
    );

    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.7), // Start further down for a more dramatic slide (adjust 0.7 for desired start position)
      end: Offset.zero,           // End at its original position (no offset)
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: subtitleInterval, // Apply the specific interval for the subtitle slide
      ),
    );


    // Start the animation when the widget is built and mounted
    // Using addPostFrameCallback ensures the animation starts after the first frame is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Ensure the widget is still in the tree before starting
             _controller.forward();
        }
    });

  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed from the tree
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access l10n if needed for context-based styling or logic within this widget
    // final l10n = AppLocalizations.of(context)!; // Example

    final theme = Theme.of(context);

    return Column(
      // No crossAxisAlignment specified, defaults to center, which works with textAlign: TextAlign.center
      children: <Widget>[
        // Title - Now wrapped in FadeTransition
        FadeTransition(
          opacity: _titleFadeAnimation, // Apply the title fade animation
          child: Text(
            widget.title, // Access title via widget.
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 32, // Keep original styling
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary, // Use theme color
            ),
          ),
        ),
        const SizedBox(height: 8), // Space between title and subtitle

        // Subtitle - Wrapped in Slide and Fade Transitions with longer interval
        SlideTransition(
           position: _subtitleSlideAnimation, // Apply the subtitle slide animation
           child: FadeTransition(
              opacity: _subtitleFadeAnimation, // Apply the subtitle fade animation
              child: Text(
                widget.subtitle, // Access subtitle via widget.
                textAlign: TextAlign.center, // Keep centered alignment
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16, // Keep original styling
                  color: theme.colorScheme.onSurface.withOpacity(0.7), // Use theme color
                ),
              ),
           ),
        ),
      ],
    );
  }
}