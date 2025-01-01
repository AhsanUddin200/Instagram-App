class User {
  final String uid;
  final String email;
  final String username;
  final String? profileImageUrl;
  final List<String> followers;
  final List<String> following;

  User({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    this.followers = const [],
    this.following = const [],
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'followers': followers,
        'following': following,
      };

  static User fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'],
        email: json['email'],
        username: json['username'],
        profileImageUrl: json['profileImageUrl'],
        followers: List<String>.from(json['followers'] ?? []),
        following: List<String>.from(json['following'] ?? []),
      );
} 