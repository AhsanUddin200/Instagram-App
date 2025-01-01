import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({
    super.key,
    this.userId,
  });

  Future<void> _followUser(BuildContext context, String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userRef = FirebaseFirestore.instance.collection('users');
    final currentUserDoc = userRef.doc(currentUser.uid);
    final targetUserDoc = userRef.doc(userId);

    final currentUserData = await currentUserDoc.get();
    final isFollowing = (currentUserData.data()?['following'] as List<dynamic>?)
            ?.contains(userId) ??
        false;

    if (isFollowing) {
      // Unfollow
      await currentUserDoc.update({
        'following': FieldValue.arrayRemove([userId])
      });
      await targetUserDoc.update({
        'followers': FieldValue.arrayRemove([currentUser.uid])
      });
    } else {
      // Follow
      await currentUserDoc.update({
        'following': FieldValue.arrayUnion([userId])
      });
      await targetUserDoc.update({
        'followers': FieldValue.arrayUnion([currentUser.uid])
      });
    }
  }

  Future<void> _updateProfileImage(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');

      try {
        await storageRef.putFile(file);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'profileImageUrl': imageUrl});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser =
        userId == null || userId == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Loading...');
            return Text(
              snapshot.data?['username'] ?? 'Profile',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Add new post
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              // TODO: Show menu
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final user = User.fromJson(userData);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('userId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, postsSnapshot) {
              if (!postsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = postsSnapshot.data!.docs;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: isCurrentUser
                                    ? () => _updateProfileImage(context)
                                    : null,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundImage: user.profileImageUrl != null
                                      ? NetworkImage(user.profileImageUrl!)
                                      : null,
                                  child: user.profileImageUrl == null
                                      ? Text(
                                          user.username[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 24),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatColumn(posts.length, 'Posts'),
                                    _buildStatColumn(
                                        user.followers.length, 'Followers'),
                                    _buildStatColumn(
                                        user.following.length, 'Following'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _followUser(context, userId!),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: user.followers.contains(
                                          FirebaseAuth
                                              .instance.currentUser?.uid)
                                      ? Colors.grey[300]
                                      : Colors.blue,
                                ),
                                child: Text(
                                  user.followers.contains(FirebaseAuth
                                          .instance.currentUser?.uid)
                                      ? 'Unfollow'
                                      : 'Follow',
                                  style: TextStyle(
                                    color: user.followers.contains(FirebaseAuth
                                            .instance.currentUser?.uid)
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = Post.fromJson(
                          posts[index].data() as Map<String, dynamic>,
                        );
                        return post.imageUrl != null
                            ? Image.network(
                                post.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox();
                      },
                      childCount: posts.length,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
