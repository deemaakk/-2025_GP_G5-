import 'dart:io';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:image_picker/image_picker.dart';
import 'custom_navbar.dart'; // تأكد تضيفه

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  bool isSignToArabic = true;
  File? _imageFile;
  final TextEditingController _textController = TextEditingController();
  bool _showSignImage = false;
  final int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
     
    }
  }


  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة الكاميرا غير متاحة حالياً')),
    );
  }

  void _translateTextToSign() {
    setState(() {
      _showSignImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE9EDF6),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSignToArabic ? "لغة الإشارة" : "العربية",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      setState(() {
                        isSignToArabic = !isSignToArabic;
                        _imageFile = null;
                        _textController.clear();
                        _showSignImage = false;
                      });
                    },
                  ),
                  Text(
                    isSignToArabic ? "العربية" : "لغة الإشارة",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _pickImage,
                            style: _buttonStyle(),
                            child: const Text("التقاط صورة"),
                          ),
                        ],
                      )
                    : Column(
                        children: [
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _translateTextToSign,
                            style: _buttonStyle(),
                            child: const Text("ترجم"),
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
                      ? const Text(
                          "هذا نص الترجمة الظاهر بعد التقاط الإشارة.",
                          style: TextStyle(fontSize: 16),
                        )
                      : (_showSignImage
                          ? Image.asset("assets/sign-language.png", fit: BoxFit.contain)
                          : const Center(child: Text("ستظهر لغة الإشارة هنا"))),
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