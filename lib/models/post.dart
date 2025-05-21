// lib/models/post.dart
import 'package:mgw_tutorial/models/author.dart';
import 'package:mgw_tutorial/models/comment.dart'; // Though comments list is not populated here

class Post {
  final int id;
  final String title;
  final String description;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Author author;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.comments = const [],
  });
  
  static String _safeGetString(Map<String, dynamic> json, String key, String modelName) {
    final value = json[key];
    if (value == null) {
      throw FormatException("Field '$key' is null in $modelName JSON, expected String. JSON: $json");
    }
    if (value is! String) {
      throw FormatException("Field '$key' is not a String in $modelName JSON, expected String but got ${value.runtimeType}. JSON: $json");
    }
    return value;
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    if (authorJson == null || authorJson is! Map<String, dynamic>) {
        throw FormatException("Field 'author' is missing, null, or not a map in Post JSON. JSON: $json");
    }

    return Post(
      id: json['id'] as int,
      title: _safeGetString(json, 'title', 'Post'),
      description: _safeGetString(json, 'description', 'Post'),
      userId: json['userId'] as int,
      createdAt: DateTime.parse(_safeGetString(json, 'createdAt', 'Post')),
      updatedAt: DateTime.parse(_safeGetString(json, 'updatedAt', 'Post')),
      author: Author.fromJson(authorJson),
      // Comments are usually fetched separately
    );
  }
  // copyWith and toJson methods remain the same
   Post copyWith({
    int? id,
    String? title,
    String? description,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Author? author,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'userId': userId,
    };
  }
}