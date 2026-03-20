import 'dart:convert';

import 'package:flutter/services.dart';
import '../models/lessons.dart';

// Load lesson json from assets folder
Future<Lesson> loadLesson(String filename) async{
  final String jsonString = await rootBundle.loadString('assets/lessons/$filename');
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
  return Lesson.fromMap(jsonMap);
}