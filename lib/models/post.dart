import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String? imageUrl;
  final String caption;
  final DateTime timestamp;
  final List<String> likes;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    this.imageUrl,
    required this.caption,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'imageUrl': imageUrl,
        'caption': caption,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': likes,
        'comments': comments.map((comment) => comment.toJson()).toList(),
      };

  static Post fromJson(Map<String, dynamic> json) {
    var timestamp = json['timestamp'];
    DateTime dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      dateTime = DateTime.now();
    }

    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      imageUrl: json['imageUrl'],
      caption: json['caption'] ?? '',
      timestamp: dateTime,
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((comment) => Comment.fromJson(comment))
          .toList(),
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

  static Comment fromJson(Map<String, dynamic> json) {
    var timestamp = json['timestamp'];
    DateTime dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      dateTime = DateTime.now();
    }

    return Comment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      text: json['text'] ?? '',
      timestamp: dateTime,
    );
  }
}
