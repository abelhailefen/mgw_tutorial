// lib/widgets/common/animated_list_item.dart
import 'package:flutter/material.dart';

/// A widget that animates its child with a scale and fade effect when it appears.
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    this.scaleStart = 0.9, // Start slightly smaller
  }) : super(key: key);

  final Widget child;
  final Duration duration;
  final Curve curve;
  final double scaleStart;

  @override
  _AnimatedListItemState createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin { // Use SingleTickerProviderStateMixin for the AnimationController

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this, // The TickerProvider
    );

    // Scale animation: Goes from scaleStart to 1.0
    _scaleAnimation = Tween<double>(begin: widget.scaleStart, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Fade animation: Goes from 0.0 (fully transparent) to 1.0 (fully opaque)
    // We can often use the same curved animation controller
     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve, // Use the same curve
      ),
    );


    // Start the animation when the widget is initialized
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the child (the CourseCard) with the transition widgets
    return FadeTransition(
      opacity: _fadeAnimation, // Apply fade animation
      child: ScaleTransition(
        scale: _scaleAnimation, // Apply scale animation
        child: widget.child, // The CourseCard
      ),
    );
  }
}