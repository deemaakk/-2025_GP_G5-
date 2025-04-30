import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

import 'login_page.dart';
import 'signup_page.dart';
import 'resetpassword_page.dart';
import 'education_letters.dart';
import 'homepage.dart';
import 'profile.dart';
import 'articles_page.dart';
// ignore: unused_import
import 'welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow; // نعيد الخطأ لو كان غير مكرر
    }
  }

 await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);


  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/reset': (context) => const ResetPasswordPage(),
        '/letters': (context) => const LettersScreen(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const AccountSettingsPage(),
        '/articles': (context) => ArticlesPage(),
      },
    );
  }
}
