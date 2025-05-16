// lib/models/post.dart
import 'package:mgw_tutorial/models/author.dart'; // Import Author model
import 'package:mgw_tutorial/models/comment.dart';
class Post {
  final int id;
  final String title;
  final String description;
  final int userId; // The ID of the user who created the post
  final DateTime createdAt;
  final DateTime updatedAt;
  final Author author; // Nested Author object

  // Locally tracked, not from API GET /posts
  List<Comment> comments; // To hold comments related to this post

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.comments = const [], // Default to an empty list
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      userId: json['userId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      // Comments are usually fetched separately or via a nested API call for a specific post
    );
  }

  Map<String, dynamic> toJson() { // For creating/updating posts
    return {
      'id': id, // Usually not sent on creation
      'title': title,
      'description': description,
      'userId': userId,
      // createdAt and updatedAt are usually handled by the backend
      // author is usually derived from userId on the backend during creation
    };
  }
}