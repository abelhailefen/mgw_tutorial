import 'dart:io';

class Subject {
  final int id;
  final String name;
  final String category;
  final String year;
  final String imageUrl;
  final String? localImagePath;

  Subject({
    required this.id,
    required this.name,
    required this.category,
    required this.year,
    required this.imageUrl,
    this.localImagePath,
  });

  String? get displayImagePath {
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      try {
        final file = File(localImagePath!);
        if (file.existsSync()) {
          return localImagePath;
        } else {
          print("Subject(${id}): Local image file not found: $localImagePath. Falling back to network.");
        }
      } catch (e) {
        print("Subject(${id}): Error checking local image file: $e. Falling back to network.");
      }
    }
    return imageUrl.isNotEmpty ? imageUrl : null;
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Subject',
      category: json['category'] ?? 'N/A',
      year: json['year'] ?? 'N/A',
      imageUrl: json['image'] ?? '',
      localImagePath: json['localImagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'year': year,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
    };
  }
}