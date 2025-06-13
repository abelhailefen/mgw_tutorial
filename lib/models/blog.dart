// lib/models/blog.dart

class Blog {
  final int id;
  final String title;
  final String body;
  final String? media;
  final String createdAt;
  final int likeCount;
  final int commentCount;
  final String notificationType;

  Blog({
    required this.id,
    required this.title,
    required this.body,
    this.media,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.notificationType,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      media: json['media'] ?? null,
      createdAt: json['createdAt'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      notificationType: json['notificationType'] is Map<String, dynamic>
          ? json['notificationType']['name'] ?? 'Unknown'
          : 'Unknown',
    );
  }
}