import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/user.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot> _getUsers(String searchTerm) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final searchTermLower = searchTerm.toLowerCase();

    if (searchTerm.isEmpty) {
      return FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUser?.uid)
          .limit(50)
          .snapshots();
    }

    // Search by username or email
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('username')
        .startAt([searchTermLower])
        .endAt([searchTermLower + '\uf8ff'])
        .where('uid', isNotEqualTo: currentUser?.uid)
        .limit(20)
        .snapshots();
  }

  Future<void> _followUser(String userId) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            // Users List with debug info
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUsers(_searchController.text),
                builder: (context, snapshot) {
                  // Add debug info
                  print("Connection state: ${snapshot.connectionState}");
                  print("Has data: ${snapshot.hasData}");
                  print("Has error: ${snapshot.hasError}");
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;
                  print("Number of users: ${users.length}"); // Debug print

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final user = User.fromJson(userData);
                      final currentUser = FirebaseAuth.instance.currentUser;

                      // Don't show current user in the list
                      if (user.uid == currentUser?.uid) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? Text(user.username[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user.username),
                        trailing: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser?.uid)
                              .snapshots(),
                          builder: (context, currentUserSnapshot) {
                            if (!currentUserSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final currentUserData = User.fromJson(
                                currentUserSnapshot.data!.data()
                                    as Map<String, dynamic>);
                            final isFollowing =
                                currentUserData.following.contains(user.uid);

                            return ElevatedButton(
                              onPressed: () => _followUser(user.uid),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? Colors.grey[300]
                                    : Colors.blue,
                              ),
                              child: Text(
                                isFollowing ? 'Unfollow' : 'Follow',
                                style: TextStyle(
                                  color:
                                      isFollowing ? Colors.black : Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
