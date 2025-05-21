// lib/models/comment.dart
import 'package:mgw_tutorial/models/author.dart';
import 'package:mgw_tutorial/models/reply.dart';

class CommentPostInfo {
  final int id;
  final String title;

  CommentPostInfo({required this.id, required this.title});

  factory CommentPostInfo.fromJson(Map<String, dynamic> json) {
    return CommentPostInfo(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Unknown Post',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

class Comment {
  final int id;
  final String comment; // This Dart field name can remain 'comment'
  final int userId;
  final int postId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Author author;
  final CommentPostInfo? post;

  final List<Reply> replies;
  final int replyCount;
  final bool isLoadingReplies;
  final bool areAllRepliesLoaded;

  Comment({
    required this.id,
    required this.comment,
    required this.userId,
    required this.postId,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.post,
    this.replies = const [],
    this.replyCount = 0,
    this.isLoadingReplies = false,
    this.areAllRepliesLoaded = false,
  });

  static String _safeGetString(Map<String, dynamic> json, String key, String modelName) {
    final value = json[key];
    if (value == null) {
      // Include the full JSON in the error for better debugging
      throw FormatException("Field '$key' is null in $modelName JSON, expected String. JSON: $json");
    }
    if (value is! String) {
      // Include the full JSON in the error
      throw FormatException("Field '$key' is not a String in $modelName JSON, expected String but got ${value.runtimeType}. JSON: $json");
    }
    return value;
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    List<Reply> nestedReplies = [];
    if (json['replies'] != null && json['replies'] is List) {
      nestedReplies = (json['replies'] as List)
          .map((replyJson) => Reply.fromJson(replyJson as Map<String, dynamic>))
          .toList();
    }

    final authorJson = json['author'];
    if (authorJson == null || authorJson is! Map<String, dynamic>) {
        throw FormatException("Field 'author' is missing, null, or not a map in Comment JSON. JSON: $json");
    }

    return Comment(
      id: json['id'] as int,
      // THE FIX IS HERE: Read from 'content' key from JSON
      comment: _safeGetString(json, 'content', 'Comment'), // <--- MODIFIED
      userId: json['userId'] as int,
      postId: json['postId'] as int,
      createdAt: DateTime.parse(_safeGetString(json, 'createdAt', 'Comment')),
      updatedAt: DateTime.parse(_safeGetString(json, 'updatedAt', 'Comment')),
      author: Author.fromJson(authorJson),
      post: json['post'] != null ? CommentPostInfo.fromJson(json['post'] as Map<String, dynamic>) : null,
      replies: nestedReplies,
      replyCount: json['_count']?['replies'] as int? ?? (json['replies'] as List?)?.length ?? json['replyCount'] as int? ?? 0,
      isLoadingReplies: json['isLoadingReplies'] as bool? ?? false,
      areAllRepliesLoaded: json['areAllRepliesLoaded'] as bool? ?? (json['replies'] != null && (json['replies'] as List).isNotEmpty),
    );
  }

  Comment copyWith({
    int? id,
    String? comment,
    int? userId,
    int? postId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Author? author,
    CommentPostInfo? post,
    List<Reply>? replies,
    int? replyCount,
    bool? isLoadingReplies,
    bool? areAllRepliesLoaded,
  }) {
    return Comment(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      post: post ?? this.post,
      replies: replies ?? this.replies,
      replyCount: replyCount ?? this.replyCount,
      isLoadingReplies: isLoadingReplies ?? this.isLoadingReplies,
      areAllRepliesLoaded: areAllRepliesLoaded ?? this.areAllRepliesLoaded,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
       return {
      'comment': comment,
      'userId': userId,
      'postId': postId,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    // Similarly, if backend expects 'content' for update, change key here.
     return {
      'comment': comment,
    };
  }
}