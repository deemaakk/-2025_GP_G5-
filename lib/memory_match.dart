import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'play_withlaweh.dart';
import 'homepage.dart';

void main() {
  runApp(const MemoryMatch());
}

class MemoryMatch extends StatelessWidget {
  const MemoryMatch({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Match Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MemoryMatchGameScreen(),
    );
  }
}

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  _MemoryMatchGameScreenState createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  final List<String> _allArabicLetters = [
    "أ","ب","ت","ث","ج","ح","خ","د","ذ","ر",
    "ز","س","ش","ص","ض","ط","ظ","ع","غ","ف",
    "ق","ك","ل","م","ن","ه","و","ي"
  ];

  List<String> _shuffledCards = [];
  List<bool> _cardFlips = [];
  List<int> _flippedIndexes = [];
  int _matchCount = 0;
  bool _canFlip = true;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _startNewGame();

    // Show tutorial automatically when the game first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroDialog();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _startNewGame() {
    List<String> selectedLetters = List.from(_allArabicLetters)..shuffle();
    selectedLetters = selectedLetters.take(4).toList();

    List<String> pairs = [];
    for (var letter in selectedLetters) {
      pairs.add(letter);
      pairs.add("assets/signs/signs/$letter.jpg");
    }

    pairs.shuffle();

    setState(() {
      _shuffledCards = pairs;
      _cardFlips = List.filled(pairs.length, false);
      _flippedIndexes = [];
      _matchCount = 0;
      _canFlip = true;
    });
  }

  void _flipCard(int index) {
    if (!_canFlip || _cardFlips[index]) return;

    setState(() {
      _cardFlips[index] = true;
      _flippedIndexes.add(index);
    });

    if (_flippedIndexes.length == 2) {
      _canFlip = false;

      final first = _shuffledCards[_flippedIndexes[0]];
      final second = _shuffledCards[_flippedIndexes[1]];

      bool isMatch = false;

      if (first.contains('assets') && !second.contains('assets')) {
        isMatch = first.contains(second);
      } else if (!first.contains('assets') && second.contains('assets')) {
        isMatch = second.contains(first);
      }

      if (isMatch) {
        setState(() {
          _matchCount++;
          _flippedIndexes.clear();
          _canFlip = true;
        });

        if (_matchCount == 4) {
          _confettiController.play();
          Future.delayed(const Duration(milliseconds: 600), () => _showGameOverDialog());
        }
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _cardFlips[_flippedIndexes[0]] = false;
            _cardFlips[_flippedIndexes[1]] = false;
            _flippedIndexes.clear();
            _canFlip = true;
          });
        });
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF38598B),
        title: const Text("🎉 أحسنت!", style: TextStyle(color: Colors.white)),
        content: const Text("أنهيت اللعبة بنجاح! 🎊", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text("🔁 العب مجدداً", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PlayWithLaweh()),
              );
            },
            child: const Text("🔙 العودة إلى القائمة الرئيسية", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

void _showIntroDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFE7EAF6),
        title: Align(
          alignment: Alignment.centerRight, // Right-align the title
          child: const Text(
            "شرح اللعبة",
            style: TextStyle(
              color: Color(0xFF113F67),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: const Text(
          "⭐ طابق كل حرف عربي مع صورة لغة الإشارة الخاصة به.\n"
          "⭐ اكشف بطاقتين في كل مرة.\n"
          "⭐ اجمع كل الأزواج لتربح! 🎉",
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Color(0xFF113F67)),
        ),
        
        actionsAlignment: MainAxisAlignment.start,
actions: [
  TextButton(
    child: const Text(
      "حسناً",
      style: TextStyle(color: Color(0xFF113F67)),
    ),
    onPressed: () => Navigator.of(context).pop(),
  ),
],

      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF38598B),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PlayWithLaweh()),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: _showIntroDialog, // Access tutorial anytime
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: _shuffledCards.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _flipCard(index),
                        child: Card(
                          color: const Color(0xFFE7EAF6),
                          child: Center(child: _buildCardContent(index)),
                        ),
                      );
                    },
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
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.white, Colors.amber, Colors.redAccent, Colors.green],
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(int index) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _cardFlips[index]
          ? (_shuffledCards[index].contains("assets")
              ? Image.asset(_shuffledCards[index])
              : Text(
                  _shuffledCards[index],
                  style: const TextStyle(fontSize: 24, color: Colors.black),
                ))
          : Image.asset('assets/logo.png'),
    );
  }
}
