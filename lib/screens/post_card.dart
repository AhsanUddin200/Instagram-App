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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    post.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  post.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // TODO: Show options menu
                  },
                ),
              ],
            ),
          ),
          // Image
          if (post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          // Action Buttons
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
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  // TODO: Open comments
                },
              ),
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () {
                  // TODO: Share post
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {
                  // TODO: Save post
                },
              ),
            ],
          ),
          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${post.likes.length} likes',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Caption
          if (post.caption?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: post.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(text: post.caption ?? ''),
                  ],
                ),
              ),
            ),
          // Comments
          if (post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show latest comment
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: post.comments.last.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(text: post.comments.last.text),
                      ],
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  // View all comments button
                  if (post.comments.length > 1)
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.8,
                            minChildSize: 0.5,
                            maxChildSize: 0.9,
                            builder: (context, scrollController) => Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: const Text(
                                    'Comments',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemCount: post.comments.length,
                                    itemBuilder: (context, index) {
                                      final comment = post.comments[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.grey[200],
                                          child: Text(
                                            comment.username[0].toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                        ),
                                        title: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: comment.username,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const TextSpan(text: ' '),
                                              TextSpan(text: comment.text),
                                            ],
                                          ),
                                        ),
                                        subtitle: Text(
                                          _getTimeAgo(comment.timestamp),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'View all ${post.comments.length} comments',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              _getTimeAgo(post.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
