import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// LocalStorageService — wraps SharedPreferences for UserProfile persistence.
///
/// All data is saved locally immediately. When you add a database (e.g. Firebase),
/// call [syncToDatabase] after any save to push changes upstream.
class LocalStorageService {
  static const String _profileKey = 'user_profile';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _setupStepKey = 'setup_step'; // resume partial setup

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    // TODO: syncToDatabase(profile);
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, complete);
  }

  Future<void> saveSetupStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_setupStepKey, step);
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<int> getSavedSetupStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_setupStepKey) ?? 0;
  }

  // ── Get user ──────────────────────────────────────────────────────────────
  Future<UserProfile?> getCurrentUser() async {
    return await loadProfile();
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Database sync stub ────────────────────────────────────────────────────
  // Replace this with your actual database logic (Firebase, Supabase, etc.)

  // ignore: unused_element
  Future<void> _syncToDatabase(UserProfile profile) async {
    // Example (Firebase Firestore):
    // if (profile.uid != null) {
    //   await FirebaseFirestore.instance
    //       .collection('users')
    //       .doc(profile.uid)
    //       .set(profile.toJson(), SetOptions(merge: true));
    // }
  }


}
