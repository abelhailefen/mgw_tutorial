// lib/widgets/testimonials/testimonial_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/models/testimonial.dart';
// No need to import TestimonialProvider here, apiBaseUrl is passed as a parameter

class TestimonialListItem extends StatelessWidget {
  final Testimonial testimonial;
  final String apiBaseUrl; // Needed to construct full image URLs if paths are relative

  const TestimonialListItem({
    super.key,
    required this.testimonial,
    required this.apiBaseUrl, // Pass the base URL from the provider/screen
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Use "Anonymous" and localize it if name is missing or empty
    final String authorName = testimonial.author != null && testimonial.author.name.isNotEmpty
        ? testimonial.author.name
        : (l10n.appTitle.contains("መጂወ") ? "ስም የለም" : "Anonymous");
    final String testimonialTitle = testimonial.title;
    final String testimonialDescription = testimonial.description;
    final List<String> displayImageUrls = testimonial.images;

    return Card(
      key: ValueKey(testimonial.id),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : "A", // Use default 'A' if name is empty after check
                    style: TextStyle(fontSize: 18, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authorName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis, // Prevent long names from overflowing
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // --- Display All Images ---
            if (displayImageUrls.isNotEmpty)
              SizedBox(
                height: 180, // Fixed height for the image list/gallery
                child: ListView.builder(
                   scrollDirection: Axis.horizontal,
                   itemCount: displayImageUrls.length,
                   itemBuilder: (context, imgIndex) {
                     final imageUrl = displayImageUrls[imgIndex];
                     // Construct full URL if backend paths are relative (e.g., /uploads/image.jpg)
                     // Use the passed apiBaseUrl
                     final fullImageUrl = imageUrl.startsWith('http') || imageUrl.startsWith('https') ? imageUrl : "$apiBaseUrl$imageUrl";

                     return Container(
                       margin: EdgeInsets.only(right: imgIndex == displayImageUrls.length - 1 ? 0 : 8.0), // Add spacing between images
                       width: 250, // Fixed width for images in the horizontal list
                       child: ClipRRect(
                         borderRadius: BorderRadius.circular(8.0),
                         child: Image.network(
                           fullImageUrl,
                           fit: BoxFit.cover,
                           loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                             if (loadingProgress == null) return child;
                             return Container(
                               height: 180, // Match SizedBox height
                               color: theme.colorScheme.surfaceVariant,
                               child: Center(
                                 child: CircularProgressIndicator(
                                   value: loadingProgress.expectedTotalBytes != null
                                       ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                       : null,
                                   strokeWidth: 3, // Adjust thickness
                                 ),
                               ),
                             );
                           },
                           errorBuilder: (context, error, stackTrace) => Container(
                             height: 180, // Match SizedBox height
                             color: theme.colorScheme.surfaceVariant,
                             child: Center(child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.onSurfaceVariant, size: 40)),
                           ),
                           // Add headers if required by your backend to load images (e.g., Authorization)
                           // headers: const {"Authorization": "Bearer YOUR_TOKEN_HERE"},
                         ),
                       ),
                     );
                   },
                ),
              ),
            if (displayImageUrls.isNotEmpty) const SizedBox(height: 12), // Spacing if images are present

            Text(
              testimonialTitle,
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.secondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '"${testimonialDescription}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                    height: 1.45
                  ),
                  maxLines: 5, // Limit description lines
                  overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Display status
                Chip(
                  label: Text(
                    testimonial.status, // TODO: Localize status strings
                    style: theme.chipTheme.labelStyle?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                  backgroundColor: testimonial.status.toLowerCase() == 'approved'
                      ? Colors.green.shade100 // Example color for approved
                      : testimonial.status.toLowerCase() == 'pending'
                        ? Colors.orange.shade100 // Example for pending
                        : theme.chipTheme.backgroundColor, // Default for others
                  labelStyle: TextStyle(
                     fontSize: 10,
                     fontWeight: FontWeight.bold,
                     color: testimonial.status.toLowerCase() == 'approved'
                        ? Colors.green.shade800
                        : testimonial.status.toLowerCase() == 'pending'
                           ? Colors.orange.shade800
                           : theme.chipTheme.labelStyle?.color,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Adjusted padding
                  visualDensity: VisualDensity.compact, // Compact chip size
                ),


                Text(
                  // Use toLocal() as the timestamp from backend is often UTC
                  DateFormat.yMMMd().add_jm().format(testimonial.createdAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}