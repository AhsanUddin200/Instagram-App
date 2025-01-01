class User {
  final String uid;
  final String email;
  final String username;

  User({
    required this.uid,
    required this.email,
    required this.username,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'username': username,
      };

  static User fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'],
        email: json['email'],
        username: json['username'],
      );
} 