// lib/widgets/testimonials/testimonial_list.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/testimonial.dart';
import 'package:mgw_tutorial/widgets/testimonials/testimonial_item.dart';

class TestimonialList extends StatelessWidget {
  final List<Testimonial> testimonials;
  final String apiBaseUrl; // Pass the base URL down to the items
  final VoidCallback onRefresh;

  const TestimonialList({
    super.key,
    required this.testimonials,
    required this.apiBaseUrl,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async { onRefresh(); },
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: ListView.separated(
        key: const ValueKey("all_testimonial_list"),
        padding: const EdgeInsets.all(16.0),
        itemCount: testimonials.length,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (ctx, index) {
          final testimonial = testimonials[index];
          return TestimonialListItem(
            testimonial: testimonial,
            apiBaseUrl: apiBaseUrl,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }
}