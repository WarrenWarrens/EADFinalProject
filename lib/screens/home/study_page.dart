import 'package:flutter/material.dart';
import '../../widgets/app_nav_bar.dart';
import '../../widgets/app_language.dart';
import 'profile_screen.dart';

class StudyPage extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const StudyPage({
    super.key,
    this.selectedLanguage = AppLanguage.navi,
  });

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    _language = widget.selectedLanguage;
  }

  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            initialLanguage: _language,
            onLanguageChange: (lang) => setState(() => _language = lang),
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _language.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded, size: 56, color: accent.withOpacity(0.5)),
              const SizedBox(height: 20),
              const Text(
                'Study',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 1,
        selectedLanguage: _language,
        onTap: _onNavTap,
        onLanguageSelect: (lang) => setState(() => _language = lang),
      ),
    );
  }
}