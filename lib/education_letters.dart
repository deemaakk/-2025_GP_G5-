import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:laweh_app/education_category.dart';
import 'package:laweh_app/name_to_sign.dart';

class LettersScreen extends StatefulWidget {
  const LettersScreen({super.key});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  static const String kOrderField = 'lettrrorder';

  List<DocumentSnapshot<Map<String, dynamic>>> letters = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Education-letters')
          .orderBy(kOrderField)
          .get();

      setState(() {
        letters = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _next(BuildContext context) {
    if (currentIndex < letters.length - 1) {
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

  Future<void> _openPicker() async {
    if (letters.isEmpty) return;
    final int? pickedIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => LettersPickerPage(
          letters: letters,
          currentIndex: currentIndex,
        ),
      ),
    );
    if (pickedIndex != null && pickedIndex >= 0 && pickedIndex < letters.length) {
      setState(() => currentIndex = pickedIndex);
    }
  }

  void _showLessonCompleteDialog(BuildContext context) {
    final confetti = ConfettiController(duration: const Duration(seconds: 3));
    confetti.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        alignment: Alignment.topCenter,
        children: [
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: const Color(0xFFE9ECF7),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'الدرس مكتمل',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113F67),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF153C64),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      confetti.stop();
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
                  const SizedBox(height: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      confetti.stop();
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NameToSignScreen()),
                      );
                    },
                    child: const Text(
                      'جرب كتابة اسمك',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -20,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.1,
              numberOfParticles: 10,
              maxBlastForce: 8,
              minBlastForce: 4,
              gravity: 0.4,
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

    if (letters.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFE9ECF7),
        body: Center(child: Text('لا توجد حروف حالياً')),
      );
    }

    final doc = letters[currentIndex].data()!;
    final imageUrl = (doc['imgletter'] ?? '').toString();
    final label = (doc['letter'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.list_alt_rounded, size: 28, color: Color(0xFF153C64)),
                    onPressed: _openPicker,
                    tooltip: 'قائمة الحروف',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / letters.length,
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
                        child: Image.network(
                          imageUrl,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
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
                          CircleAvatar(
                            backgroundColor: const Color(0xFF153C64),
                            radius: 28,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => _next(context),
                            ),
                          ),
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

class LettersPickerPage extends StatelessWidget {
  final List<DocumentSnapshot<Map<String, dynamic>>> letters;
  final int currentIndex;

  const LettersPickerPage({
    super.key,
    required this.letters,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF7),
      appBar: AppBar(
        title: const Text(
          'قائمة الحروف',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF153C64),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: letters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final data = letters[i].data() ?? {};
          final letter = (data['letter'] ?? '').toString();
          final imgUrl = (data['imgletter'] ?? '').toString();

          return InkWell(
            onTap: () => Navigator.pop<int>(context, i),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: i == currentIndex ? const Color(0xFF153C64) : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF153C64),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imgUrl.isEmpty
                        ? const SizedBox(width: 64, height: 64)
                        : Image.network(
                            imgUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
