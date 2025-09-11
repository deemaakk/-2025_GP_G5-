import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_navbar.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  bool isSignToArabic = true;

  File? _imageFile;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  bool _showSignImage = false;
  final int _selectedIndex = 2;

  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  double _fontSize = 16;
  bool _loadingOcr = false;

  late stt.SpeechToText _speech;
  bool _hasSpeech = false;
  bool _listening = false;

  Map<String, String> _signMap = {};
  bool _loadingMap = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _textController.addListener(_onTextChanged);
    _initSpeechToText();
    _loadSignMap();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ar-SA');
    _tts.setStartHandler(() => setState(() => _speaking = true));
    _tts.setCompletionHandler(() => setState(() => _speaking = false));
    _tts.setCancelHandler(() => setState(() => _speaking = false));
  }

  Future<void> _initSpeechToText() async {
    _speech = stt.SpeechToText();
    _hasSpeech = await _speech.initialize();
    setState(() {});
  }

  Future<void> _loadSignMap() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Education-letters')
          .orderBy('lettrrorder')
          .get();

      final map = <String, String>{};
      for (final d in snap.docs) {
        final data = d.data();
        final raw = (data['letter'] ?? '').toString().trim();
        final url = (data['imgletter'] ?? '').toString().trim();
        if (raw.isEmpty || url.isEmpty) continue;

        // normalize the DB key so variants like (أ / إ / آ) resolve to the same key as (ا)
        final key = _normalizeArabic(raw);
        map[key] = url;

        // optional: also keep the raw key, just in case you ever need it elsewhere
        map.putIfAbsent(raw, () => url);
      }

      setState(() {
        _signMap = map;
        _loadingMap = false;
      });
    } catch (e) {
      setState(() => _loadingMap = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحميل إشارات الحروف')),
      );
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _resultController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  void _onItemTapped(int index) {}

  void _onTextChanged() {
    setState(() {
      _showSignImage = _textController.text.trim().isNotEmpty;
    });
  }

  Future<void> _toggleListen() async {
    if (!_hasSpeech) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الميزة غير متاحة على هذا الجهاز')),
      );
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'ar_SA',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (res) {
        setState(() {
          _textController.text = res.recognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      },
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
      _resultController.clear();
    });
    await _autoOcrOnPickedImage();
  }

  Future<void> _autoOcrOnPickedImage() async {
    if (_imageFile == null) return;
    setState(() => _loadingOcr = true);
    final inputImage = InputImage.fromFile(_imageFile!);
    final textRecognizer = TextRecognizer();
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final extracted = recognizedText.text.trim();
      setState(() {
        _resultController.text =
            extracted.isEmpty ? 'لم يتم العثور على نص.' : extracted;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر استخراج النص من الصورة')),
      );
    } finally {
      await textRecognizer.close();
      setState(() => _loadingOcr = false);
    }
  }

  Future<void> _speak(String text) async {
    final t = text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد نص للنطق')),
      );
      return;
    }
    await _tts.setLanguage('ar-SA');
    await _tts.speak(t);
  }

  Future<void> _stopSpeak() async {
    await _tts.stop();
  }

  String _normalizeArabic(String s) {
    final diacritics = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
    s = s.replaceAll(diacritics, '');
    s = s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
    return s;
  }

  List<Widget> _buildSignFromText(String text) {
    if (_loadingMap) {
      return [const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())];
    }
    final widgets = <Widget>[];
    final norm = _normalizeArabic(text);
    for (int i = 0; i < norm.length; i++) {
      final ch = norm[i];
      if (ch.trim().isEmpty) {
        widgets.add(const SizedBox(width: 16));
        continue;
      }
      final url = _signMap[ch];
      if (url != null && url.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackBox(ch),
            ),
          ),
        ));
      } else {
        widgets.add(_fallbackBox(ch));
      }
    }
    if (widgets.isEmpty) {
      return [const Center(child: Text('ستظهر لغة الإشارة هنا'))];
    }
    return widgets;
  }

  Widget _fallbackBox(String ch) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDD6E4)),
      ),
      child: Text(ch, style: const TextStyle(fontSize: 22, color: Color(0xFF153C64))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE9EDF6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF153C64),
          centerTitle: true,
          title: const SizedBox.shrink(),
          automaticallyImplyLeading: false, // no back button
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isSignToArabic ? "لغة الإشارة" : "العربية",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      setState(() {
                        isSignToArabic = !isSignToArabic;
                        _imageFile = null;
                        _textController.clear();
                        _resultController.clear();
                        _showSignImage = false;
                      });
                    },
                  ),
                  Text(isSignToArabic ? "العربية" : "لغة الإشارة",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: _boxStyle(),
                child: isSignToArabic
                    ? Column(
                        children: [
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _imageFile == null
                                ? const Center(child: Text("لا توجد صورة"))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _pickImage,
                              style: _buttonStyle(),
                              child: const Text("اختيار/التقاط صورة"),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: _toggleListen,
                              icon: Icon(_listening ? Icons.mic_off : Icons.mic),
                              tooltip: _listening ? 'إيقاف الإملاء' : 'إملاء صوتي',
                            ),
                          ),
                          TextField(
                            controller: _textController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "اكتب النص هنا...",
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _boxStyle(),
                  child: isSignToArabic
                      ? (_loadingOcr
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        final t = _resultController.text.trim();
                                        if (t.isNotEmpty) {
                                          Clipboard.setData(ClipboardData(text: t));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('تم نسخ النص')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.copy),
                                      tooltip: 'نسخ',
                                    ),
                                    IconButton(
                                      onPressed: () => _speak(_resultController.text),
                                      icon: const Icon(Icons.volume_up),
                                      tooltip: 'نطق',
                                    ),
                                    IconButton(
                                      onPressed: _speaking ? _stopSpeak : null,
                                      icon: const Icon(Icons.stop),
                                      tooltip: 'إيقاف',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _resultController,
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    style: TextStyle(fontSize: _fontSize),
                                    decoration: InputDecoration(
                                      hintText: "سيظهر النص المستخرج هنا…",
                                      filled: true,
                                      fillColor: const Color(0xFFF7F7F9),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text("حجم الخط"),
                                    Expanded(
                                      child: Slider(
                                        value: _fontSize,
                                        min: 12,
                                        max: 28,
                                        onChanged: (v) => setState(() => _fontSize = v),
                                      ),
                                    ),
                                    Text(_fontSize.toStringAsFixed(0)),
                                  ],
                                ),
                              ],
                            ))
                      : (_loadingMap
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                runSpacing: 6,
                                children: _buildSignFromText(_textController.text),
                              ),
                            )),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  BoxDecoration _boxStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE7E9EB),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
