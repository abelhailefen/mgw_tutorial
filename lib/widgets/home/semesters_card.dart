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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subjectsLeft
                          .map((subject) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text('• $subject', style: TextStyle(color: Colors.grey[800])),
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
                                child: Text('• $subject', style: TextStyle(color: Colors.grey[800])),
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
                  label: Text('$price ETB', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}