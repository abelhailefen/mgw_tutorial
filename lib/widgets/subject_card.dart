// lib/widgets/subject_card.dart

import 'package:flutter/material.dart';

class SubjectCard extends StatelessWidget {
  final int id; // Added id
  final String name; // Changed from subjectName
  final String category; // New field
  final String year; // New field
  final String imageUrl; // Same field name, different source
  final VoidCallback? onTap;

  const SubjectCard({
    super.key,
    required this.id, // Added
    required this.name,
    required this.category, // Added
    required this.year, // Added
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add margin for spacing
      elevation: 2.0, // Optional: subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap ?? () {
          // Default tap behavior (optional)
          print('Tapped on subject: $name (ID: $id)');
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name, // Display subject name
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1), // Dark Blue - matching CourseCard style
                ),
              ),
              const SizedBox(height: 12),
              // Display Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                // Check if imageUrl is not empty before loading
                child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                        ),
                      )
                    : Container( // Placeholder if no image URL or invalid URL
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
                      ),
              ),
              const SizedBox(height: 12),
              // Display Category and Year
              Text(
                'Category: $category, Year: $year', // Display category and year
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700], // Adjust color as needed
                ),
              ),
              // Removed price chip as it's not in subject data
            ],
          ),
        ),
      ),
    );
  }
}