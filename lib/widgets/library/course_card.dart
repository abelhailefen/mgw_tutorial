// lib/widgets/library/course_card.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'dart:io'; // Needed for File

class CourseCard extends StatelessWidget {
  final ApiCourse course;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the new getter that prioritizes local path
    String? imageUrl = course.displayThumbnailPath;
    bool isLocalFile = imageUrl != null && File(imageUrl).existsSync(); // Check if it's likely a valid local path

    final cardBorderRadius = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(Directionality.of(context))
        : BorderRadius.circular(12.0); // Fallback

    Widget thumbnailWidget;

    if (imageUrl != null && imageUrl.isNotEmpty) {
       if (isLocalFile) {
         // Load from local file
         thumbnailWidget = Image.file(
           File(imageUrl),
           fit: BoxFit.cover,
           // errorBuilder can still be useful if the file exists but is corrupted
           errorBuilder: (context, error, stackTrace) {
              print("Error loading local thumbnail from ${imageUrl}: $error");
              return Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(Icons.broken_image_outlined, size: 50, color: theme.colorScheme.onSurfaceVariant),
              );
           },
         );
       } else {
         // Load from network URL
         thumbnailWidget = Image.network(
           imageUrl,
           fit: BoxFit.cover,
           errorBuilder: (context, error, stackTrace) {
              print("Error loading network thumbnail from ${imageUrl}: $error");
              return Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(Icons.school_outlined, size: 50, color: theme.colorScheme.onSurfaceVariant),
              );
           },
         );
       }
    } else {
      // Fallback when no URL/path is available
      thumbnailWidget = Container(
          color: theme.colorScheme.surfaceVariant,
          child: Icon(Icons.school_outlined, size: 50, color: theme.colorScheme.onSurfaceVariant),
        );
    }


    return Card(
      // Uses CardTheme
      child: InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                 borderRadius: BorderRadius.only(
                  topLeft: cardBorderRadius.topLeft,
                  topRight: cardBorderRadius.topRight,
                ),
                child: thumbnailWidget, // Use the selected widget
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    course.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (course.shortDescription != null && course.shortDescription!.isNotEmpty)
                    Text(
                      course.shortDescription!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // TODO: Localize 'Price: ' and ' ETB'
                        'Price: ${course.discountedPrice ?? course.price} ETB',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      // You could add a "Free" chip or "Discount" chip here
                      if (course.isFreeCourse ?? false)
                        Chip(
                          label: const Text("FREE"), // TODO: Localize
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 10, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          visualDensity: VisualDensity.compact,
                        )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}