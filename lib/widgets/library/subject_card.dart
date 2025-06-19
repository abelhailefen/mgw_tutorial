//lib/widgets/library/subject_card.dart
import 'package:flutter/material.dart';


class SubjectCard extends StatelessWidget {
  final String title;
  final String imageUrl; // Or IconData
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple stays within bounds
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, size: 50)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}