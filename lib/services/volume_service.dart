// lib/services/volume_service.dart
//
// Singleton that persists music and voice volume levels (0.0–1.0).
// Defaults: music 0.5, voice 0.75.
//
// Call [load()] once at startup (main.dart) to hydrate from SharedPreferences.
// Consumers read [musicVolume] / [voiceVolume].
// Setters persist immediately and return a Future.

import 'package:shared_preferences/shared_preferences.dart';

class VolumeService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final VolumeService _instance = VolumeService._internal();
  factory VolumeService() => _instance;
  VolumeService._internal();

  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _musicKey = 'vol_music';
  static const _voiceKey = 'vol_voice';

  // ── State ──────────────────────────────────────────────────────────────────
  double _music = 0.5;
  double _voice = 0.75;

  double get musicVolume => _music;
  double get voiceVolume => _voice;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Hydrate from SharedPreferences. Call once at startup before runApp.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _music = prefs.getDouble(_musicKey) ?? 0.5;
    _voice = prefs.getDouble(_voiceKey) ?? 0.75;
  }

  // ── Setters ────────────────────────────────────────────────────────────────

  Future<void> setMusicVolume(double v) async {
    _music = v.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicKey, _music);
  }

  Future<void> setVoiceVolume(double v) async {
    _voice = v.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_voiceKey, _voice);
  }
}