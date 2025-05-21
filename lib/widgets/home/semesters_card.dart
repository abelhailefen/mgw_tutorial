//lib/widgets/home/semesters_card.dart
import 'package:flutter/material.dart';

class SemestersCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final List<String> subjectsLeft;
  final List<String> subjectsRight;
  final String price;
  final VoidCallback? onTap;

  const SemestersCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.subjectsLeft,
    required this.subjectsRight,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      // Uses CardTheme from main.dart
      child: InkWell(
        onTap: onTap ?? () { /* ... */ },
        borderRadius: BorderRadius.circular(theme.cardTheme.shape is RoundedRectangleBorder ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(Directionality.of(context)).bottomLeft.x : 12.0), // Match card border radius
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl, // This is the URL received from HomeScreen
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: theme.colorScheme.surfaceVariant,
                    child: Center(child: Icon(Icons.broken_image, color: theme.colorScheme.onSurfaceVariant, size: 50)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subjectsLeft
                          .map((subject) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text('• $subject', style: theme.textTheme.bodyMedium),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subjectsRight
                          .map((subject) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text('• $subject', style: theme.textTheme.bodyMedium),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text('$price ETB', style: theme.chipTheme.labelStyle),
                  backgroundColor: theme.chipTheme.backgroundColor,
                  padding: theme.chipTheme.padding,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}