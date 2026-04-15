import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';

import '../models/lessons.dart';

// Method to get the daily quiz selection
// int getTodayQuizIndex(int totalQuizzes){
//   final now = DateTime.now();
//   final start = DateTime(2024,1,1);
//   final days = now.difference(start).inDays;
//
//   return days % totalQuizzes;
// }

class DailyQuizService{

  // Get current date
  final DateTime currentDate = DateTime.now();

  // Get the current user
  UserProfile? _user;

  Future<void> loadUser() async {
    _user = await LocalStorageService().getCurrentUser();
  }

  Future<Quiz> loadQuiz(String filename) async{
    final String jsonString = await rootBundle.loadString('assets/quizzes/$filename.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return Quiz.fromMap(jsonMap);
  }

  // Helper to normalize date
  DateTime _toDateOnly(DateTime date){
    return DateTime(date.year, date.month, date.day);
  }

  // Check if quiz has already been taken
  bool canTakeQuizToday()  {
    // Load user
    // await loadUser();

    // If there is no last completed date (ex. new user)
    if (_user?.lastCompletedQuizDate == null){
      return true;
    }

    // If the last completed date is the current date, they have already taken the quiz
    final today = _toDateOnly(currentDate);
    final lastCompletedDate = _toDateOnly(_user!.lastCompletedQuizDate!);

    if (today != lastCompletedDate){
      return true;
    }
    else{
      return false;
    }


  }

  // Update streak
  Future<UserProfile?> updateStreak() async {
    await loadUser();
    print(_user?.streak);

    if (_user == null) {
      // handle new user
      print('null');
      return null;
    }
    print('good');

    final today = _toDateOnly(currentDate);

    final lastDate = _user?.lastCompletedQuizDate != null ? _toDateOnly(_user!.lastCompletedQuizDate!) : null;

    int streak = _user?.streak ?? 0;

    if (lastDate == null) {
      streak = 1;
    } else {
      final diff = today.difference(lastDate).inDays;

      if (diff == 0) {
        return _user;
      } else if (diff == 1) {
        streak++;
      } else {
        streak = 1;
      }
    }

    final updated = _user?.copyWith(
        streak: streak,
        lastCompletedQuizDate: today
    );

    // Save to storage
    await LocalStorageService().saveProfile(updated!);

    return updated;
  }

}
