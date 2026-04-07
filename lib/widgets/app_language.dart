import 'package:flutter/material.dart';


enum AppLanguage { navi, klingon, highValyrian }

extension AppLanguageExt on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.navi:
        return "Na'vi";
      case AppLanguage.klingon:
        return 'Klingon';
      case AppLanguage.highValyrian:
        return 'High Valyrian';
    }
  }

  Color get accentColor {
    switch (this) {
      case AppLanguage.navi:
        return const Color(0xFF80D8FF);
      case AppLanguage.klingon:
        return const Color(0xFF9B1C1C);
      case AppLanguage.highValyrian:
        return const Color(0xFFB8860B);
    }
  }

  Color get accentLight {
    switch (this) {
      case AppLanguage.navi:
        return const Color(0xFF00B0FF).withOpacity(0.22);
      case AppLanguage.klingon:
        return const Color(0xFF9B1C1C).withOpacity(0.22);
      case AppLanguage.highValyrian:
        return const Color(0xFFB8860B).withOpacity(0.22);
    }
  }

  List<AppLanguage> get others {
    return AppLanguage.values.where((l) => l != this).toList();
  }
}