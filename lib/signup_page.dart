import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';

class SignUpPage extends StatefulWidget {
  // ignore: use_super_parameters
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ------------------ VALIDATION ------------------

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال اسم المستخدم';
    if (RegExp(r'^\d').hasMatch(value)) return 'الاسم لا يجب أن يبدأ برقم';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }

    final emailRegex =
        RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$'); // صيغة بريد صحيحة

    if (!emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'يجب أن تحتوي على حرف كبير';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'يجب أن تحتوي على حرف صغير';
    if (!RegExp(r'\d').hasMatch(value)) return 'يجب أن تحتوي على رقم';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != passwordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  // ------------------ REGISTER (المعدل) ------------------

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    try {
      // 1) إنشاء المستخدم في Auth
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // نحاول نأخذ الـ user من النتيجة، ولو صارت مشكلة غريبة
      // نرجع لـ currentUser كخطة بديلة
      User? user = userCredential.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is null بعد التسجيل!');
      }

      // 2) تحديث displayName
      await user.updateDisplayName(username);

      // 3) إنشاء الوثيقة في Firestore داخل UserAccount
      await FirebaseFirestore.instance
          .collection('UserAccount')
          .doc(user.uid)
          .set({
        'Name': username,
        'email': email,
        'uid': user.uid,
        'created_time': Timestamp.now(),
        'customAvatar': 'assets/default.png',
      });

      // 4) لو كل شيء تمام → ننتقل للهوم
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      // أخطاء إنشاء المستخدم (الإيميل مستخدم، الباسورد ضعيف، ..)
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      String msg;
      if (e.code == 'email-already-in-use') {
        msg = 'هذا البريد مستخدم مسبقًا، سجلي دخول أو استخدمي بريدًا آخر.';
      } else if (e.code == 'weak-password') {
        msg = 'كلمة المرور ضعيفة، اختاري كلمة أقوى.';
      } else {
        msg = e.message ?? 'حدث خطأ أثناء إنشاء الحساب.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } on FirebaseException catch (e) {
      // أخطاء Firestore أو Firebase عامة (rules, network, appcheck...)
      debugPrint('FirebaseException: ${e.code} - ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في حفظ بيانات المستخدم: ${e.message ?? 'حاولي مرة أخرى.'}',
          ),
        ),
      );
    } catch (e) {
      // هنا نمسك الأخطاء الغريبة مثل PigeonUserDetails
      debugPrint('Unexpected error in signup: $e');

      // خطة بديلة: لو المستخدم انشأ فعلاً في Auth، نضيفه يدويًا في UserAccount
      try {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null) {
          await FirebaseFirestore.instance
              .collection('UserAccount')
              .doc(current.uid)
              .set({
            'Name': usernameController.text.trim(),
            'email': current.email ?? emailController.text.trim(),
            'uid': current.uid,
            'created_time': Timestamp.now(),
            'customAvatar': 'assets/default.png',
          });

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          return; // لا نكمل للسنackbar العامة
        }
      } catch (e2) {
        debugPrint('Fallback Firestore error: $e2');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ غير متوقع أثناء عملية التسجيل'),
        ),
      );
    }
  }

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 100),
                const SizedBox(height: 24),

                const Text(
                  'إنشاء حساب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),

                const SizedBox(height: 32),

                _buildTextField(
                  'اسم المستخدم',
                  controller: usernameController,
                  validator: _validateUsername,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  'البريد الإلكتروني',
                  controller: emailController,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  'كلمة المرور',
                  controller: passwordController,
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  'تأكيد كلمة المرور',
                  controller: confirmPasswordController,
                  isPassword: true,
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2D52),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 64,
                    ),
                  ),
                  child: const Text(
                    'إنشاء حساب',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    'لديك حساب؟ تسجيل الدخول',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    required TextEditingController controller,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    bool isConfirmField = controller == confirmPasswordController;

    return TextFormField(
      controller: controller,
      obscureText: isPassword
          ? (isConfirmField ? _obscureConfirmPassword : _obscurePassword)
          : false,
      validator: validator,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (isConfirmField
                          ? _obscureConfirmPassword
                          : _obscurePassword)
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirmField) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  });
                },
              )
            : null,
      ),
    );
  }
}
