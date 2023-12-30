import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'notifications.dart';

class MedicineProvider with ChangeNotifier {
  final BuildContext context;
  List<Medicine> _medicines = [];

  List<Medicine> get medicines => _medicines;

  MedicineProvider(this.context);

  void addMedicine(
    String name,
    TimeOfDay time, {
    DateTime? date,
    RepeatType repeatType = RepeatType.daily,
  }) {
    final medicine =
        Medicine(name: name, time: time, date: date, repeatType: repeatType);
    _medicines.add(medicine);
    _scheduleNotification(medicine);
    _saveMedicines(context);
    notifyListeners();
  }

  void deleteMedicine(Medicine medicine) {
    _medicines.remove(medicine);
    _cancelNotification(medicine);
    _saveMedicines(context);
    notifyListeners();
  }

  Future<void> _saveMedicines(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/medicines.json');
      final encoded = jsonEncode(_medicines);
      await file.writeAsString(encoded);
    } catch (e) {
      print('Error saving medicines: $e');
    }
  }

  Future<void> _scheduleNotification(Medicine medicine) async {
    final notificationService = NotificationService();
    await notificationService.scheduleNotification(medicine);
    context.read<HistoryProvider>().addHistoryItem(HistoryItem(
          name: medicine.name,
          time: medicine.time,
          action: 'Added',
        ));
  }

  Future<void> _cancelNotification(Medicine medicine) async {
    final notificationService = NotificationService();
    await notificationService.cancelNotification(medicine);
    context.read<HistoryProvider>().addHistoryItem(HistoryItem(
          name: medicine.name,
          time: medicine.time,
          action: 'Removed',
        ));
  }

  getApplicationDocumentsDirectory() {}
}

class HistoryProvider with ChangeNotifier {
  List<HistoryItem> _history = [];

  List<HistoryItem> get history => _history;

  void addHistoryItem(HistoryItem historyItem) {
    _history.add(historyItem);
    notifyListeners();
  }
}
