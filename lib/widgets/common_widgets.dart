import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large pill button with soft lavender background (outlined style from mockup)
class SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final double? width;

  const SoftButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: color ?? AppColors.buttonSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard filled purple pill button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : Text(label,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Lesson Buttons
class LessonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final double? width;

  const LessonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      height: 100.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? AppColors.primary,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? AppColors.surface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}



/// Google Sign-In button matching mockup style
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onTap,
    this.label = 'Login with Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: const Icon(Icons.g_mobiledata, size: 22),
        label: Text(label,
            style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// App logo / title header used on every screen
class AppHeader extends StatelessWidget {
  final double topPadding;
  const AppHeader({super.key, this.topPadding = 60});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 40),
      child: const Text(
        'LinguaLore',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Styled text field matching the mockup inputs
class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool showClearButton;

  const AppTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: showClearButton
            ? IconButton(
          icon: const Icon(Icons.cancel_outlined,
              color: AppColors.textSecondary, size: 18),
          onPressed: () => controller.clear(),
        )
            : null,
      ),
    );
  }
}

/// Divider with "or" label
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
      ],
    );
  }
}


class NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const NavButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        minimumSize: Size.zero,
        backgroundColor: AppColors.primary,
      ),
      onPressed: onTap,
      child: Icon(icon, color: Colors.white),
    );
  }
}