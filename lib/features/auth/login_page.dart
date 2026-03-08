import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onLoggedIn, this.onTapSignUp});

  final VoidCallback? onLoggedIn;
  final VoidCallback? onTapSignUp;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    forceCodeForRefreshToken: true,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  // ✅ Sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);
    ScaffoldMessenger.of(context).clearSnackBars();

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

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted && userCredential.user != null) {
        widget.onLoggedIn?.call();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'account-exists-with-different-credential' =>
            'Account exists with different provider',
          'invalid-credential' => 'Invalid credential',
          'operation-not-allowed' => 'Google Sign-In not enabled',
          'user-disabled' => 'User account has been disabled',
          'user-not-found' => 'User not found',
          _ => 'Firebase error: ${e.code}',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ✅ Sign in with Apple
  Future<void> _signInWithApple() async {
    setState(() => loading = true);
    ScaffoldMessenger.of(context).clearSnackBars();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (mounted && userCredential.user != null) {
        widget.onLoggedIn?.call();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'account-exists-with-different-credential' =>
            'Account exists with different provider',
          'invalid-credential' => 'Invalid credential',
          'operation-not-allowed' => 'Apple Sign-In not enabled',
          'user-disabled' => 'User account has been disabled',
          _ => 'Firebase error: ${e.code}',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ChatGPT_Image_1.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Welcome Back 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Focus Planner',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ✅ Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4285F4),
                                  ),
                                ),
                              )
                            : Row(
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
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Apple Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loading ? null : _signInWithApple,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.apple,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Apple',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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
}