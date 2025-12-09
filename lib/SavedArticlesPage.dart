import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'articles_details_page.dart';

class SavedArticlesPage extends StatefulWidget {
  const SavedArticlesPage({super.key});

  @override
  State<SavedArticlesPage> createState() => _SavedArticlesPageState();
}

class _SavedArticlesPageState extends State<SavedArticlesPage> {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  bool sortDescending = true;
  List<String> savedArticleIds = [];

  @override
  void initState() {
    super.initState();
    fetchSavedArticleIds();
  }

  Future<void> fetchSavedArticleIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final savedSnapshot = await FirebaseFirestore.instance
        .collection('UserAccount')
        .doc(user.uid)
        .collection('SavedArticles')
        .get();

    setState(() {
      savedArticleIds = savedSnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text("الأحدث أولاً"),
                onTap: () {
                  setState(() {
                    sortDescending = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text("الأقدم أولاً"),
                onTap: () {
                  setState(() {
                    sortDescending = false;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String formatArabicDate(DateTime date) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    String arabicFormatted = formatted;
    for (int i = 0; i < western.length; i++) {
      arabicFormatted = arabicFormatted.replaceAll(western[i], eastern[i]);
    }
    return arabicFormatted;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE7EAF6),
        appBar: AppBar(
          title: const Text("المقالات المحفوظة"),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF113F67),
          elevation: 0,
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('Articles')
              .orderBy("ArticleDate", descending: sortDescending)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("خطأ في تحميل البيانات"));
            }
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final subject = data['ArticleSubject'].toString();
              final matchesSearch = searchText.isEmpty
                  ? true
                  : subject
                      .toLowerCase()
                      .contains(searchText.toLowerCase());
              final isSaved = savedArticleIds.contains(doc.id);
              return matchesSearch && isSaved;
            }).toList();

            if (docs.isEmpty) {
              return const Center(child: Text("لا توجد مقالات محفوظة"));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list,
                            color: Color(0xFF38598B)),
                        onPressed: _showSortMenu,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchText = value.trim();
                            });
                          },
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: "ابحث...",
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF38598B)),
                            filled: true,
                            fillColor:
                                // ignore: deprecated_member_use
                                const Color(0xFFA2A8D3).withOpacity(0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF38598B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final imageUrl = data['Articleimg'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArticleDetailsPage(articleData: doc),
                            ),
                          ).then((_) => fetchSavedArticleIds());
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade200, blurRadius: 6)
                            ],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back_ios,
                                  color: Color(0xFF113F67)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      data['ArticleSubject'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF113F67),
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 8),
                                    if (data['ArticleDate'] != null)
                                      Text(
                                        formatArabicDate(
                                          (data['ArticleDate'] as Timestamp)
                                              .toDate(),
                                        ),
                                        style: const TextStyle(
                                            color: Color(0xFF38598B)),
                                        textDirection: TextDirection.rtl,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: imageUrl != null &&
                                        imageUrl.toString().isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 40),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}