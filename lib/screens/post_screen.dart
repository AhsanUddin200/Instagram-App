import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  File? _image;
  final _captionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    // Check if at least one of image or caption is provided
    if (_image == null && _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image or write a caption')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final username = userDoc.data()?['username'] ?? 'Anonymous';
      String? imageUrl;

      // Upload image if exists
      if (_image != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('posts/${DateTime.now().millisecondsSinceEpoch}.jpg');

          // Upload file
          final uploadTask = await storageRef.putFile(_image!);
          if (uploadTask.state == TaskState.error) {
            throw Exception('Failed to upload image');
          }

          // Get URL
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          print('Error uploading image: $e');
          throw Exception('Failed to upload image: $e');
        }
      }

      // Create post document
      final postRef = FirebaseFirestore.instance.collection('posts').doc();

      await postRef.set({
        'id': postRef.id,
        'userId': user.uid,
        'username': username,
        'imageUrl': imageUrl ?? '', // Empty string if no image
        'caption': _captionController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'likes': [],
        'comments': [],
      });

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _createPost,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : const Icon(Icons.add_photo_alternate, size: 50),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    hintText: 'Write a caption...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
