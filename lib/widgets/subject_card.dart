// lib/widgets/subject_card.dart

import 'package:flutter/material.dart';
// Corrected import path
import 'package:mgw_tutorial/screens/sidebar/chapter_list_screen.dart';

class SubjectCard extends StatelessWidget {
  final int id;
  final String name;
  final String category;
  final String year;
  final String imageUrl;

  const SubjectCard({
    super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.year,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
           Navigator.pushNamed(
             context,
             ChapterListScreen.routeName,
             arguments: {
               'subjectId': id,
               'subjectName': name,
             },
           );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
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
                    : Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                'Category: $category, Year: $year',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}