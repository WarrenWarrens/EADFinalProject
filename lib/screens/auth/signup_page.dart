import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/local_storage_service.dart';
import '../../models/user_profile.dart';
import 'verify_email_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = LocalStorageService();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // ── Replace with your auth registration call ──────────────────────────
      // final credential = await FirebaseAuth.instance
      //     .createUserWithEmailAndPassword(
      //       email: _emailController.text.trim(),
      //       password: _passwordController.text,
      //     );
      // await credential.user?.sendEmailVerification();
      //
      // final profile = UserProfile(
      //   uid: credential.user?.uid,
      //   name: _nameController.text.trim(),
      //   email: _emailController.text.trim(),
      //   emailVerified: false,
      //   createdAt: DateTime.now(),
      // );

      await Future.delayed(const Duration(milliseconds: 600)); // simulate

      final profile = UserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        emailVerified: false,
        createdAt: DateTime.now(),
      );

      // Save locally immediately — data persists even before email is verified
      await _storage.saveProfile(profile);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(email: profile.email ?? ''),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Sign up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // ── Replace with Google Sign-In flow ─────────────────────────────────
      // (Same pattern as login_page.dart — Google handles email verification)
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      // Google accounts are already verified, skip verify page
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/setup', (route) => false);
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-up failed.');
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
          padding: EdgeInsets.only(
            left: 32,
            right: 32,
            top: 8,
            // Grow with the keyboard so focused fields at the
            // bottom of the form can always scroll into view.
            bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppHeader(),

                // Name field
                AppTextField(
                  hint: 'name',
                  controller: _nameController,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),

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
                  (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 8),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),

                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Sign Up',
                  onTap: _signUp,
                  isLoading: _loading,
                ),

                const SizedBox(height: 20),
                const OrDivider(),
                const SizedBox(height: 20),

                GoogleSignInButton(
                  label: 'Sign up with Google',
                  onTap: _signUpWithGoogle,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}