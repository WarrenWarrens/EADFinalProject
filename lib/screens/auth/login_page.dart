import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/local_storage_service.dart';
import '../../models/user_profile.dart';
import '../setup/profile_setup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = LocalStorageService();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // ── Replace with your auth call ──────────────────────────────────────
      // e.g. await FirebaseAuth.instance.signInWithEmailAndPassword(
      //        email: _emailController.text.trim(),
      //        password: _passwordController.text);
      //
      // For now we load the locally saved profile:
      await Future.delayed(const Duration(milliseconds: 600)); // simulate
      final profile = await _storage.loadProfile();

      if (!mounted) return;
      if (profile != null) {
        final onboarded = await _storage.isOnboardingComplete();
        if (!mounted) return;
        if (onboarded) {
          // TODO: Navigate to HomeScreen
          Navigator.of(context).popUntil((r) => r.isFirst);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
          );
        }
      } else {
        setState(() => _errorMessage = 'No account found. Please sign up.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // ── Replace with Google Sign-In flow ─────────────────────────────────
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // final GoogleSignInAuthentication? googleAuth =
      //     await googleUser?.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth?.accessToken,
      //   idToken: googleAuth?.idToken,
      // );
      // final userCredential =
      //     await FirebaseAuth.instance.signInWithCredential(credential);
      //
      // final profile = UserProfile(
      //   uid: userCredential.user?.uid,
      //   name: userCredential.user?.displayName,
      //   email: userCredential.user?.email,
      //   emailVerified: true,
      //   createdAt: DateTime.now(),
      // );
      // await _storage.saveProfile(profile);

      await Future.delayed(const Duration(milliseconds: 600)); // simulate
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppHeader(),

                // Email field
                AppTextField(
                  hint: 'email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),

                // Password field
                AppTextField(
                  hint: 'password',
                  controller: _passwordController,
                  obscure: true,
                  showClearButton: false,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Password too short' : null,
                ),
                const SizedBox(height: 8),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),

                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Login',
                  onTap: _login,
                  isLoading: _loading,
                ),

                const SizedBox(height: 20),
                const OrDivider(),
                const SizedBox(height: 20),

                GoogleSignInButton(onTap: _loginWithGoogle),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
