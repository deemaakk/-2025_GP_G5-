import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleDetailsPage extends StatefulWidget {
  final DocumentSnapshot articleData;

  const ArticleDetailsPage({super.key, required this.articleData});

  @override
  // ignore: library_private_types_in_public_api
  _ArticleDetailsPageState createState() => _ArticleDetailsPageState();
}

class _ArticleDetailsPageState extends State<ArticleDetailsPage> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    checkIfSaved();
  }

  Future<void> checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final savedDoc = await FirebaseFirestore.instance
        .collection('UserAccount')
        .doc(user.uid)
        .collection('SavedArticles')
        .doc(widget.articleData.id)
        .get();

    setState(() {
      isSaved = savedDoc.exists;
    });
  }

  Future<void> toggleSaveStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final savedRef = FirebaseFirestore.instance
        .collection('UserAccount')
        .doc(user.uid)
        .collection('SavedArticles')
        .doc(widget.articleData.id);

    final snapshot = await savedRef.get();

    if (snapshot.exists) {
      await savedRef.delete();
    } else {
      await savedRef.set({
        'articleId': widget.articleData.id,
        'savedAt': Timestamp.now(),
      });
    }

    await checkIfSaved();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.articleData.data() as Map<String, dynamic>;

    final String? imageUrl = data['Articleimg'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF355B8C),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            data['ArticleSubject'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          actions: [
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              onPressed: toggleSaveStatus,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage('assets/laweh_logo.png'),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    data['ArticleContent'] ?? '',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}