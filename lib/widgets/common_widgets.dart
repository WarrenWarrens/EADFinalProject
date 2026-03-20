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
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
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
      child:               // ── Logo ──────────────────────────────────────────────
      Image.asset(
        'assets/Logo/Lingualogo.png',
        width: 320,
        fit: BoxFit.contain,
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
        padding: const EdgeInsets.all(22),
        minimumSize: Size.zero,
        backgroundColor: AppColors.primary,
      ),
      onPressed: onTap,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Fantasy-themed buttons
// ═══════════════════════════════════════════════════════════════════════════════

/// 🟣 Magic CTA — deep purple→indigo gradient, gold trim, soft glow.
///
/// Use for primary calls to action: "Begin Your Journey", "Start Lesson", etc.
class MagicButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;

  const MagicButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          // Gold trim — sits behind the button as a border
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 1.5,
          ),
          // Soft outer glow
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: isLoading ? null : onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7B5EFF), // bright purple
                    Color(0xFF5A3FD4), // mid purple
                    Color(0xFF3A28A0), // deep indigo
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Color(0x60000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 📜 Parchment Button — warm beige fill, dark brown text, decorative border.
///
/// Use for secondary actions: "Resume Your Adventure", "I have an account", etc.
class ParchmentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;

  const ParchmentButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          // Double-border effect: outer gold, inner via the button itself
          border: Border.all(
            color: AppColors.parchmentAccent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldDark.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: isLoading ? null : onTap,
            splashColor: AppColors.parchmentAccent.withOpacity(0.2),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFAF6ED), // parchment light
                    Color(0xFFF0E8D4), // slightly darker parchment
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                // Inner decorative border line
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.parchmentAccent.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.goldDark,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🧩 Mystic Text Button — no background, subtly glowing text.
///
/// Use for tertiary/low-priority actions: "Continue as Guest", "Skip", etc.
class MysticTextButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  const MysticTextButton({
    super.key,
    required this.label,
    this.onTap,
    this.fontSize = 15,
  });

  @override
  State<MysticTextButton> createState() => _MysticTextButtonState();
}

class _MysticTextButtonState extends State<MysticTextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.4, end: 0.9).animate(
          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (_, child) {
          final glowOpacity = _glowAnimation.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.goldMid,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withOpacity(glowOpacity * 0.5),
                    blurRadius: 12,
                  ),
                  Shadow(
                    color: const Color(0xFFD4AF37).withOpacity(glowOpacity * 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}