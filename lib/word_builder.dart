import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'play_withlaweh.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar', 'AE'),
      supportedLocales: const [
        Locale('ar', 'AE'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: WordBuilderGame(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}

// ignore: use_key_in_widget_constructors
class WordBuilderGame extends StatefulWidget {
  @override
  _WordBuilderGameState createState() => _WordBuilderGameState();
}

class _WordBuilderGameState extends State<WordBuilderGame> {
  final List<String> _words = [
    "بيت", "قلم", "شمس", "كتاب", "علم", "نجم", "باب", "جمل",
    "طفل", "دجاج", "قلب", "قوس", "أسد", "سقف", "قمر", "غزال",
    "سفر", "حبر", "بحر"
  ];

  final Map<String, String> letterImages = {
    'ا': 'assets/signs/signs/ا.jpg',
    'أ': 'assets/signs/signs/أ.jpg',
    'ب': 'assets/signs/signs/ب.jpg',
    'ت': 'assets/signs/signs/ت.jpg',
    'ث': 'assets/signs/signs/ث.jpg',
    'ج': 'assets/signs/signs/ج.jpg',
    'ح': 'assets/signs/signs/ح.jpg',
    'خ': 'assets/signs/signs/خ.jpg',
    'د': 'assets/signs/signs/د.jpg',
    'ذ': 'assets/signs/signs/ذ.jpg',
    'ر': 'assets/signs/signs/ر.jpg',
    'ز': 'assets/signs/signs/ز.jpg',
    'س': 'assets/signs/signs/س.jpg',
    'ش': 'assets/signs/signs/ش.jpg',
    'ص': 'assets/signs/signs/ص.jpg',
    'ض': 'assets/signs/signs/ض.jpg',
    'ط': 'assets/signs/signs/ط.jpg',
    'ظ': 'assets/signs/signs/ظ.jpg',
    'ع': 'assets/signs/signs/ع.jpg',
    'غ': 'assets/signs/signs/غ.jpg',
    'ف': 'assets/signs/signs/ف.jpg',
    'ق': 'assets/signs/signs/ق.jpg',
    'ك': 'assets/signs/signs/ك.jpg',
    'ل': 'assets/signs/signs/ل.jpg',
    'م': 'assets/signs/signs/م.jpg',
    'ن': 'assets/signs/signs/ن.jpg',
    'ه': 'assets/signs/signs/ه.jpg',
    'و': 'assets/signs/signs/و.jpg',
    'ي': 'assets/signs/signs/ي.jpg',
    'ى': 'assets/signs/signs/ى.jpg',
    'ة': 'assets/signs/signs/ة.jpg',
    'ئ': 'assets/signs/signs/ئ.jpg',
    'ؤ': 'assets/signs/signs/ؤ.jpg',
    'لا': 'assets/signs/signs/لا.jpg',
  };

  late List<String> _roundWords;
  int _currentRound = 1;
  final int _totalRounds = 5;

  String _currentWord = '';
  List<Map<String, String>> _availableLetters = [];
  List<Map<String, String>> _shuffledImages = [];
  List<String> _selectedLetters = [];
  List<bool> _letterUsed = [];

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _prepareRounds();
    _startNewRound();

    // Show tutorial once after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  void _prepareRounds() {
    _roundWords = List.from(_words)..shuffle();
    _roundWords = _roundWords.take(_totalRounds).toList();
  }

  void _startNewRound() {
    if (_currentRound > _totalRounds) {
      _showGameOverDialog();
      return;
    }

    _currentWord = _roundWords[_currentRound - 1];

    _availableLetters = _currentWord
        .split('')
        .map((letter) => {
              'letter': letter,
              'image': letterImages[letter]!,
            })
        .toList();

    _shuffledImages = List.from(_availableLetters)..shuffle();
    _selectedLetters = List.filled(_currentWord.length, '');
    _letterUsed = List.filled(_availableLetters.length, false);

    setState(() {});
  }

  void _onLetterSelected(int index, String letter) {
    int letterIndex = -1;
    for (int i = 0; i < _availableLetters.length; i++) {
      if (_availableLetters[i]['letter'] == letter && !_letterUsed[i]) {
        letterIndex = i;
        break;
      }
    }

    if (letterIndex != -1) {
      setState(() {
        _selectedLetters[index] = letter;
        _letterUsed[letterIndex] = true;
        _shuffledImages = _availableLetters
            .asMap()
            .entries
            .where((entry) => !_letterUsed[entry.key])
            .map((entry) => entry.value)
            .toList();
      });
    }
  }

  void _removeLetter(int index) {
    if (_selectedLetters[index].isNotEmpty) {
      String letter = _selectedLetters[index];
      int firstUnusedIndex = _availableLetters.indexWhere(
        (item) =>
            item['letter'] == letter &&
            !_letterUsed[_availableLetters.indexOf(item)],
      );

      if (firstUnusedIndex != -1) {
        setState(() {
          _selectedLetters[index] = '';
          _letterUsed[firstUnusedIndex] = false;
          _shuffledImages = _availableLetters
              .asMap()
              .entries
              .where((entry) => !_letterUsed[entry.key])
              .map((entry) => entry.value)
              .toList();
        });
      }
    }
  }

  void _checkAnswer() {
    if (_selectedLetters.contains('')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text("رتب حروف لغة الإشارة في الأماكن المناسبة"),
          ),
        ),
      );
    } else if (_selectedLetters.join() == _currentWord) {
      // ✅ الآن الترتيب الداخلي = نفس ترتيب الكلمة (من اليمين لليسار من ناحية القراءة)
      _confettiController.play();
      if (_currentRound < _totalRounds) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Text("أحسنت! إجابة صحيحة ✅"),
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _currentRound++;
          });
          _startNewRound();
        });
      } else {
        _showGameOverDialog();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text("إجابة غير صحيحة، حاول مرة أخرى ❌"),
          ),
        ),
      );
      setState(() {
        _selectedLetters = List.filled(_currentWord.length, '');
        _letterUsed = List.filled(_availableLetters.length, false);
        _shuffledImages = List.from(_availableLetters)..shuffle();
      });
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF38598B),
        title: const Text(
          "🎉 أحسنت!",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "لقد أنهيت جميع $_totalRounds جولات! 👏",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentRound = 1;
                _prepareRounds();
              });
              _startNewRound();
            },
            child: const Text(
              "🔁 ابدأ من جديد",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE7EAF6),
          title: const Align(
            alignment: Alignment.centerRight,
            child: Text(
              "شرح اللعبة",
              style: TextStyle(
                color: Color(0xFF113F67),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                "⭐ قم بسحب وإفلات صور حروف لغة الإشارة بالترتيب الصحيح لتكوين الكلمة.\n"
                "⭐ اضغط زر التحقق للتأكد من الإجابة.\n"
                "⭐ اللعبة تتكون من 5 جولات.",
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Color(0xFF113F67),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "تنبيه: لا يمكنك تغيير ترتيب الحروف بعد إفلاتها.",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "حسناً",
                style: TextStyle(
                  color: Color(0xFF113F67),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7EAF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTutorial,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PlayWithLaweh()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'الجولة $_currentRound من $_totalRounds',
              style: const TextStyle(fontSize: 20, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const Text(
              'رتب حروف لغة الإشارة لتكوين الكلمة الصحيحة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF113F67),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Text(
              _currentWord,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF113F67),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // صور الحروف (Draggables)
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: _shuffledImages.map((item) {
                return Draggable<String>(
                  data: item['letter']!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      item['image']!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  feedback: Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        item['image']!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  childWhenDragging: Container(width: 80, height: 80),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ✅ خانات الإسقاط (من اليمين لليسار فعلياً)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: List.generate(_currentWord.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: DragTarget<String>(
                    onAccept: (letter) => _onLetterSelected(index, letter),
                    onWillAccept: (data) => true,
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: () => _removeLetter(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: candidateData.isNotEmpty
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[200],
                          ),
                          child: Center(
                            child: _selectedLetters[index].isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      letterImages[_selectedLetters[index]]!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: const Color(0xFF38598B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تحقق من الإجابة',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        blastDirection: pi,
        shouldLoop: false,
        colors: const [
          Colors.white,
          Colors.amber,
          Colors.redAccent,
          Colors.green,
        ],
      ),
    );
  }
}
