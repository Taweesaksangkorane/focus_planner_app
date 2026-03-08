import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:email_validator/email_validator.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.onRegistered});
  final VoidCallback? onRegistered;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtl = TextEditingController();
  final gmailUsernameCtl = TextEditingController();
  final passCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool loading = false;
  bool obscure1 = true, obscure2 = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    forceCodeForRefreshToken: true,
  );

  @override
  void dispose() {
    emailCtl.dispose();
    gmailUsernameCtl.dispose();
    passCtl.dispose();
    confirmCtl.dispose();
    super.dispose();
  }

  // ✅ ตรวจสอบ Gmail Username (ไม่รวม @gmail.com)
  String? _validateGmailUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอก Gmail Username';
    
    // ✅ ตรวจสอบว่า username ไม่มี @
    if (v.trim().contains('@')) {
      return 'ใส่เฉพาะ username ไม่ต้องใส่ @gmail.com';
    }

    // ✅ ตรวจสอบ Gmail username format (อักษร, ตัวเลข, จุด, ขีด)
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._-]{6,}$');
    if (!gmailRegex.hasMatch(v.trim())) {
      return 'Gmail username ต้องมี 6 ตัวอักษร��ึ้นไป (ตัวอักษร, ตัวเลข, จุด, ขีด)';
    }

    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
    return null;
  }

  String? _validateConfirm(String? v) =>
      v == passCtl.text ? null : 'รหัสผ่านไม่ตรงกัน';

  Future<void> _register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);
    
    // ✅ สร้าง full email จาก username + @gmail.com
    final fullEmail = '${gmailUsernameCtl.text.trim()}@gmail.com';
    
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: fullEmail,
        password: passCtl.text,
      );

      try {
        await cred.user?.sendEmailVerification();
      } catch (_) {}

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบด้วยบัญชีที่สมัครไว้'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
      widget.onRegistered?.call();
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Gmail นี้ถูกใช้แล้ว',
        'invalid-email' => 'อีเมลไม่ถูกต้อง',
        'weak-password' => 'รหัสผ่านอ่อนเกินไป',
        _ => 'สมัครสมาชิกไม่สำเร็จ: ${e.message ?? e.code}',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ✅ Sign up with Google
  Future<void> _signUpWithGoogle() async {
    setState(() => loading = true);
    try {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Sign out error: $e');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => loading = false);
        return;
      }

      final GoogleSignInAuthentication? googleAuth =
          await googleUser.authentication;

      if (googleAuth == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get Google authentication'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => loading = false);
        return;
      }

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get access token'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => loading = false);
        return;
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      ) as OAuthCredential;

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกผ่าน Google สำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
      widget.onRegistered?.call();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'account-exists-with-different-credential' =>
            'Account exists with different provider',
          'invalid-credential' => 'Invalid credential',
          'operation-not-allowed' => 'Google Sign-In not enabled',
          'user-disabled' => 'User account disabled',
          _ => 'Firebase error: ${e.code}',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 3, 1, 59),
              Color.fromARGB(255, 41, 28, 114)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Logo
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('📝', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Create Account 🚀',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join Focus Planner',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ✅ Google Sign-UP Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loading ? null : _signUpWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Image.asset(
                                'assets/images/google.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sign up with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ✅ Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Or',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ✅ Gmail Username, Password & Confirm Password Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            // ✅ Info Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade300,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'ใส่ Gmail username เท่านั้น @gmail.com จะเติมอัตโนมัติ',
                                      style: TextStyle(
                                        color: Colors.blue.shade300,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ✅ Gmail Username Input
                            TextFormField(
                              controller: gmailUsernameCtl,
                              validator: _validateGmailUsername,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Gmail Username',
                                icon: Icons.email_outlined,
                                suffix: Text(
                                  '@gmail.com',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ✅ Password Input
                            TextFormField(
                              controller: passCtl,
                              validator: _validatePassword,
                              obscureText: obscure1,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscure1
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  onPressed: () =>
                                      setState(() => obscure1 = !obscure1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ✅ Confirm Password Input
                            TextFormField(
                              controller: confirmCtl,
                              validator: _validateConfirm,
                              obscureText: obscure2,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Confirm Password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscure2
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    onPressed: () =>
                                        setState(() => obscure2 = !obscure2),
                                  ),
                                ),
                            ),
                            const SizedBox(height: 24),

                            // ✅ Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFA34F),
                                      Color(0xFFFF7A00)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF7A00)
                                          .withOpacity(0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: loading ? null : _register,
                                  child: Text(
                                    loading
                                        ? 'กำลังสมัครสมาชิก...'
                                        : 'Sign Up',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ✅ Back to Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      enabledBorder: _border(Colors.white.withOpacity(0.35)),
      focusedBorder: _border(Colors.white),
      errorBorder: _border(Colors.redAccent),
      focusedErrorBorder: _border(Colors.redAccent),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.2),
      );
}