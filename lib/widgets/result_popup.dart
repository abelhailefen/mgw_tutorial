// lib/widgets/result_popup.dart

import 'dart:math' as Math; // Import for Math.pi
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
// Correct the import path for your Question model
import 'package:mgw_tutorial/models/question.dart';
// Removed UEe-specific imports like video_app/constants/styles.dart
// Consider using Theme.of(context) colors instead of hardcoded ones or AppColors
// import 'package:mgw_tutorial/constants/color.dart'; // If you want to use AppColors

class ResultPopup extends StatefulWidget {
  final bool passed;
  final int score;
  final int totalQuestions;
  final List<Question> failedQuestions;
  // This callback is typically used to dismiss the popup and potentially scroll to explanations
  final VoidCallback onShowExplanations;

  const ResultPopup({
    Key? key,
    required this.passed,
    required this.score,
    required this.totalQuestions,
    required this.failedQuestions,
    required this.onShowExplanations,
  }) : super(key: key);

  @override
  _ResultPopupState createState() => _ResultPopupState();
}

class _ResultPopupState extends State<ResultPopup> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // Animation for the main popup scale and fade
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Animation for the passed icon rotation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * Math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );
    if (widget.passed) {
      _rotateController.repeat(); // Only repeat if passed
    }


    // Animation for the "Explanation" button pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
     // Only repeat if showing explanation button (failed and has failed questions)
    if (!widget.passed && widget.failedQuestions.isNotEmpty) {
       _pulseController.repeat(reverse: true);
    }
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );


    // Confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _startCelebration(); // Play confetti if passed

    _controller.forward(); // Start the main popup animation
  }

  void _startCelebration() {
    if (widget.passed) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Helper function to draw a star shape for confetti
  Path _drawStar(Size size) {
    final path = Path();
    final numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = (2 * Math.pi) / numberOfPoints;
    final halfDegreesPerStep = degreesPerStep / 2;
    path.moveTo(size.width / 2, halfWidth - externalRadius);

    for (double step = 0; step < 2 * Math.pi; step += degreesPerStep) {
      path.lineTo(
          halfWidth + externalRadius * Math.cos(step),
          halfWidth + externalRadius * Math.sin(step));
      path.lineTo(
          halfWidth + internalRadius * Math.cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * Math.sin(step + halfDegreesPerStep));
    }

    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    // Use theme colors for better integration
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      // Allow dialog dismissal by tapping outside? Usually NOT for results.
      // barrierDismissible: false, // Set this in showDialog call

      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti layer
          if (widget.passed)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Confetti explodes outwards
              shouldLoop: false, // Play once
              numberOfParticles: 100,
              maxBlastForce: 80,
              minBlastForce: 20,
              emissionFrequency: 0.02,
              gravity: 0.3,
              createParticlePath: _drawStar,
              colors: const [ // Example colors
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.purple,
                Colors.orange,
                Colors.yellow,
                Colors.pink,
                Colors.cyan,
                Colors.teal,
                Colors.indigo,
                Colors.lime,
                Colors.amber,
              ],
            ),

          // Close button at top right
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close, color: isDarkMode ? Colors.white70 : Colors.black54), // Themed close button
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ),

          // Main result content with animations
          AnimatedBuilder(
            animation: Listenable.merge([_controller, _rotateAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: Math.min(340, MediaQuery.of(context).size.width * 0.9), // Responsive width
                    padding: const EdgeInsets.all(25.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.passed
                            ? [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer] // Use theme colors for gradient
                            : [theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer.withOpacity(0.5)], // Use theme colors for gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: widget.passed
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : theme.colorScheme.error.withOpacity(0.3),
                          blurRadius: 20, // Reduced blur
                          spreadRadius: 5, // Reduced spread
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Wrap content vertically
                      children: [
                        // Icon with rotation/pulse
                        Transform.rotate(
                          angle: widget.passed ? _rotateAnimation.value : 0, // Only rotate if passed
                          child: Transform.scale( // Only pulse if explanation button is shown
                              scale: (!widget.passed && widget.failedQuestions.isNotEmpty) ? _pulseAnimation.value : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.passed
                                        ? Colors.amber.withOpacity(0.5)
                                        : Colors.redAccent.withOpacity(0.5),
                                    blurRadius: 20, // Reduced blur
                                    spreadRadius: 5, // Reduced spread
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.passed
                                    ? Icons.emoji_events // Trophy icon
                                    : Icons.sentiment_dissatisfied, // Sad face icon
                                size: 100,
                                color: widget.passed ? Colors.amber : Colors.red, // Consider theme colors here too
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.passed ? '🎉 Congratulations! 🎉' : 'You Failed!', // TODO: Localize
                          style: TextStyle(
                            fontSize: 28, // Adjusted size
                            fontWeight: FontWeight.bold,
                            color: widget.passed
                                ? theme.colorScheme.primary // Use theme color
                                : theme.colorScheme.error, // Use theme color
                            shadows: [ // Adjusted shadows
                              Shadow(
                                color: widget.passed
                                    ? Colors.amber.withOpacity(0.5)
                                    : Colors.redAccent.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'You scored ${widget.score} out of ${widget.totalQuestions}', // TODO: Localize
                          style: TextStyle(
                            fontSize: 18, // Adjusted size
                            color: theme.colorScheme.onSurface, // Use theme color
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Explanation button - show only if failed AND there are failed questions
                        if (!widget.passed && widget.failedQuestions.isNotEmpty)
                          ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(); // Dismiss the popup FIRST
                                widget.onShowExplanations(); // Then call the callback provided by ExamTakingScreen
                              },
                              style: ElevatedButton.styleFrom(
                                // Use theme colors
                                backgroundColor: theme.colorScheme.tertiary,
                                foregroundColor: theme.colorScheme.onTertiary,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 8,
                                shadowColor: theme.colorScheme.tertiary.withOpacity(0.4), // Adjusted shadow color
                              ),
                              icon: const Icon(Icons.description),
                              label: const Text(
                                'View Explanations', // TODO: Localize
                                style: TextStyle(fontSize: 16), // Adjusted size
                              ),
                            ),


                        const SizedBox(height: 20), // Spacing before OK button

                        // OK button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Dismiss the dialog
                             // Optionally call another callback here if needed after dismissal
                          },
                           // Use theme colors
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text('OK'), // TODO: Localize
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}