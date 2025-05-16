// lib/models/comment.dart
import 'package:mgw_tutorial/models/author.dart'; // Import Author model

// A simple representation of the post within a comment, as seen in your API
class CommentPostInfo {
  final int id;
  final String title;

  CommentPostInfo({required this.id, required this.title});

  factory CommentPostInfo.fromJson(Map<String, dynamic> json) {
    return CommentPostInfo(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Post',
    );
  }
}


class Comment {
  final int id;
  final String comment;
  final int userId;
  final int postId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Author author;
  final CommentPostInfo? post; // The 'post' info nested in the comment API response

  Comment({
    required this.id,
    required this.comment,
    required this.userId,
    required this.postId,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.post,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      comment: json['comment'] as String,
      userId: json['userId'] as int,
      postId: json['postId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      post: json['post'] != null ? CommentPostInfo.fromJson(json['post'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() { // For creating comments
    return {
      // 'id': id, // Not sent on creation
      'comment': comment,
      'userId': userId,
      'postId': postId,
    };
  }
}