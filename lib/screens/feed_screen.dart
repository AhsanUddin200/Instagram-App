import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'post_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_card.dart';
import '../models/post.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedIndex = 0;

  void _navigateToPostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostScreen()),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {  // Add post button index
      _navigateToPostScreen();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Instagram',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        actions: [
          IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: _navigateToPostScreen,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                  onPressed: () {
                    // TODO: Show activity feed
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.messenger_outline, color: Colors.black),
                  onPressed: () {
                    // TODO: Show direct messages
                  },
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Feed
          Column(
            children: [
              // Stories section
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: 10,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.purple, Colors.orange],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: Text(
                                    'U${index + 1}',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                            if (index == 0)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 15),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          index == 0 ? 'Your Story' : 'User ${index}',
                          style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
                  ),
                ),
              ),
              // Posts section
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Post.fromJson(data);
          }).toList();

          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) => PostCard(post: posts[index]),
          );
        },
      ),
                ),
              ],
            ),
          // Search Screen
          const SearchScreen(),
          // Add Post Screen (handled by navigation)
          const SizedBox(),
          // Reels Screen
          const Center(child: Text('Reels')),
          // Profile Screen
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                _selectedIndex == 1 ? Icons.search : Icons.search_outlined),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Add Post',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(_selectedIndex == 3 ? Icons.movie : Icons.movie_outlined),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: const Text('U', style: TextStyle(color: Colors.black54)),
                        ),
                        title: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Text('Loading...');
                            return Text(snapshot.data?['username'] ?? '');
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () async {
                          try {
                            final authService = AuthService();
                            await authService.signOut();
                            if (mounted) {
                              // Clear navigation stack and go to login
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false, // Remove all previous routes
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error logging out: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
              child: CircleAvatar(
                radius: 12,
                backgroundColor: _selectedIndex == 4 ? Colors.black : Colors.transparent,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.grey[200],
                  child: const Text('U', style: TextStyle(color: Colors.black54)),
                ),
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
