import 'package:flutter/material.dart';

enum RepeatType { daily, weekly, specificDay }

class Medicine {
  final String name;
  final TimeOfDay time;
  final DateTime? date;
  final RepeatType repeatType;

  Medicine(
      {required this.name,
      required this.time,
      this.date,
      required this.repeatType});
}

class HistoryItem {
  final String name;
  final TimeOfDay time;
  final String action;

  HistoryItem({required this.name, required this.time, required this.action});
}
