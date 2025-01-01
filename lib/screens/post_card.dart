import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  Future<void> _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
    
    if (post.likes.contains(user.uid)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid])
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid])
      });
    }
  }

  Future<void> _addComment(BuildContext context) async {
    final commentController = TextEditingController();
    bool isPosting = false;
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPosting)
                      const CircularProgressIndicator()
                    else
                      TextButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          
                          setState(() => isPosting = true);
                          
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            
                            final username = userDoc.data()?['username'] ?? 'Anonymous';
                            
                            final comment = Comment(
                              id: DateTime.now().toString(),
                              userId: user.uid,
                              username: username,
                              text: commentController.text.trim(),
                              timestamp: DateTime.now(),
                            );

                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(post.id)
                                .update({
                              'comments': FieldValue.arrayUnion([comment.toJson()])
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            setState(() => isPosting = false);
                          }
                        },
                        child: const Text('Post'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(post.username[0].toUpperCase()),
            ),
            title: Text(post.username),
          ),
          if (post.imageUrl.isNotEmpty)
            Image.network(
              post.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      onPressed: () => _toggleLike(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () => _addComment(context),
                    ),
                  ],
                ),
                Text(
                  '${post.likes.length} likes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (post.caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: post.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(text: post.caption),
                      ],
                    ),
                  ),
                ],
                if (post.comments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'View all ${post.comments.length} comments',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  ...post.comments.take(2).map((comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: comment.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: comment.text),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 