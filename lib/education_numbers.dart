import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laweh_app/education_category.dart';
import 'package:confetti/confetti.dart';

class NumbersScreen extends StatefulWidget {
  const NumbersScreen({super.key});

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  List<DocumentSnapshot> numbers = [];
  int currentIndex = 0;
  bool isLoading = true;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initialize();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Education-Numbers')
          .orderBy('NumOrder')
          .get();

      setState(() {
        numbers = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading numbers: $e');
      setState(() => isLoading = false);
    }
  }

  void _next(BuildContext context) {
    if (currentIndex < numbers.length - 1) {
      setState(() => currentIndex++);
    } else {
      _showLessonCompleteDialog(context);
    }
  }

  void _prev() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  void _showLessonCompleteDialog(BuildContext context) {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        alignment: Alignment.topCenter,
        children: [
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFFF1F4FA),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'الدرس مكتمل',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF153C64),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF153C64),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const EducationCategoryScreen()),
                      );
                    },
                    child: const Text(
                      'العودة لصفحة الدروس',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.02,
              numberOfParticles: 10,
              gravity: 0.3,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE9ECF7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (numbers.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFE9ECF7),
        body: Center(child: Text('No numbers found')),
      );
    }

    final doc = numbers[currentIndex];
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['Numberimg'] ?? '';
    final label = data['Number']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / numbers.length,
                      backgroundColor: Colors.grey.shade400,
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 300,
                                fit: BoxFit.contain,
                              )
                            : const Text("لا توجد صورة"),
                      ),
                      const SizedBox(height: 36),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 64),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Next button (left)
                          CircleAvatar(
                            backgroundColor: const Color(0xFF153C64),
                            radius: 28,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => _next(context),
                            ),
                          ),
                          // Prev button (right)
                          if (currentIndex > 0)
                            CircleAvatar(
                              backgroundColor: const Color(0xFF153C64),
                              radius: 28,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                onPressed: _prev,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}