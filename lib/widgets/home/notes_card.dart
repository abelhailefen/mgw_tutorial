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
    return Card(
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title Tapped (Not Implemented)')),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1), // Dark Blue
                ),
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
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(color: Colors.grey[800], fontSize: 15),
              ),
              const SizedBox(height: 8),
              // Placeholder for dots if this were a carousel
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: List.generate(3, (index) => // ... dot indicator ... ),
              // )
            ],
          ),
        ),
      ),
    );
  }
}