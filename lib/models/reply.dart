// lib/models/reply.dart
import 'package:mgw_tutorial/models/author.dart'; // Ensure Author model is correctly imported

// Definition for ParentCommentInfo (information about the comment a reply belongs to)
class ParentCommentInfo {
  final int id;
  // You could add other fields here if your API provides them for the parent comment context,
  // e.g., String? contentSnippet, Author? parentAuthor.
  // For now, just the ID is assumed.

  ParentCommentInfo({required this.id});

  factory ParentCommentInfo.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    if (idValue == null) {
      throw FormatException("Field 'id' is null in ParentCommentInfo JSON. JSON: $json");
    }
    if (idValue is String) {
      final parsedValue = int.tryParse(idValue);
      if (parsedValue != null) return ParentCommentInfo(id: parsedValue);
      throw FormatException("Field 'id' is a String that cannot be parsed to int in ParentCommentInfo JSON. Value: '$idValue'. JSON: $json");
    }
    if (idValue is! int) {
      throw FormatException("Field 'id' is not an int in ParentCommentInfo JSON. Got ${idValue.runtimeType}. JSON: $json");
    }
    return ParentCommentInfo(id: idValue);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}


class Reply {
  final int id;
  final String content;
  final int userId;
  final int commentId; // This will store the ID of the parent comment
  final DateTime createdAt;
  final DateTime updatedAt;
  final Author author;
  final ParentCommentInfo? parentComment; // Optional: Info about the direct parent comment object if provided

  Reply({
    required this.id,
    required this.content,
    required this.userId,
    required this.commentId, // This is the ID of the comment it's replying to
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.parentComment,
  });

  static int _safeGetInt(Map<String, dynamic> json, String key, String modelName) {
    final value = json[key];
    if (value == null) {
      throw FormatException("Field '$key' is null in $modelName JSON, expected int. JSON: $json");
    }
    if (value is String) {
        final parsedValue = int.tryParse(value);
        if (parsedValue != null) return parsedValue;
        throw FormatException("Field '$key' is a String that cannot be parsed to int in $modelName JSON. Value: '$value'. JSON: $json");
    }
    if (value is! int) {
      throw FormatException("Field '$key' is not an int in $modelName JSON, expected int but got ${value.runtimeType}. JSON: $json");
    }
    return value;
  }

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

  factory Reply.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    if (authorJson == null || authorJson is! Map<String, dynamic>) {
        throw FormatException("Field 'author' is missing, null, or not a map in Reply JSON. JSON: $json");
    }

    int parentCommentIdValue = _safeGetInt(json, 'postCommentId', 'Reply (for parent comment ID)');

    ParentCommentInfo? parentCommentInfoObject;
    final parentPostCommentJson = json['parentPostComment'];
    if (parentPostCommentJson != null && parentPostCommentJson is Map<String, dynamic>) {
        try {
            parentCommentInfoObject = ParentCommentInfo.fromJson(parentPostCommentJson);
        } catch (e) {
            print("Warning: Could not parse 'parentPostComment' object in Reply JSON: $e. JSON: $json");
        }
    } else if (parentPostCommentJson != null) {
        print("Warning: 'parentPostComment' in Reply JSON was expected to be an object but was ${parentPostCommentJson.runtimeType}. JSON: $json");
    }
    
    if (parentCommentInfoObject == null) {
        parentCommentInfoObject = ParentCommentInfo(id: parentCommentIdValue);
    }

    return Reply(
      id: _safeGetInt(json, 'id', 'Reply'),
      content: _safeGetString(json, 'content', 'Reply'),
      userId: _safeGetInt(json, 'userId', 'Reply'),
      commentId: parentCommentIdValue,
      createdAt: DateTime.parse(_safeGetString(json, 'createdAt', 'Reply')),
      updatedAt: DateTime.parse(_safeGetString(json, 'updatedAt', 'Reply')),
      author: Author.fromJson(authorJson),
      parentComment: parentCommentInfoObject,
    );
  }

  Reply copyWith({
    int? id,
    String? content,
    int? userId,
    int? commentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Author? author,
    ParentCommentInfo? parentComment,
  }) {
    return Reply(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      commentId: commentId ?? this.commentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      parentComment: parentComment ?? this.parentComment,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'content': content,
      'userId': userId,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'content': content,
    };
  }
}