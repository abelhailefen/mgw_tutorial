//lib/widgets/home/notes_card.dart
import 'package:flutter/material.dart';

class NotesCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback? onTap;

  const NotesCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
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
                  imageUrl,
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
              Text(
                description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}