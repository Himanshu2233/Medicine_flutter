import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => MedicineProvider(context)),
      Provider(create: (context) => NotificationService()),
      ChangeNotifierProvider(create: (context) => HistoryProvider()),
    ],
    child: MedicineReminderApp(),
  ));
}

class MedicineReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ThemeData().colorScheme.copyWith(
              secondary: Colors.orangeAccent,
            ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Medicine Reminder'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list)),
              Tab(icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MedicineList(),
            HistoryList(),
          ],
        ),
      ),
    );
  }
}

class MedicineList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: provider.medicines.length,
          itemBuilder: (context, index) {
            final medicine = provider.medicines[index];
            return MedicineCard(medicine: medicine);
          },
        );
      },
    );
  }
}

class MedicineCard extends StatelessWidget {
  final Medicine medicine;

  MedicineCard({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(
          medicine.name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Time: ${TimeOfDay(hour: medicine.time.hour, minute: medicine.time.minute).format(context)}',
          style: TextStyle(fontSize: 16),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            context.read<MedicineProvider>().deleteMedicine(medicine);
          },
        ),
      ),
    );
  }
}

class AddMedicineButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showAddMedicineDialog(context);
      },
      icon: Icon(Icons.add),
      label: Text('Add Medicine'),
    );
  }

  Future<void> showAddMedicineDialog(BuildContext context) async {
    String medicineName = '';
    TimeOfDay? selectedTime = TimeOfDay.now();
    DateTime? selectedDate;
    RepeatType selectedRepeatType = RepeatType.daily;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) {
                    medicineName = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                  },
                  child: Text('Select Time'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                  },
                  child: Text('Select Date'),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Repeat:'),
                    DropdownButton<RepeatType>(
                      value: selectedRepeatType,
                      onChanged: (value) {
                        if (value != null) {
                          selectedRepeatType = value;
                        }
                      },
                      items: RepeatType.values.map((type) {
                        return DropdownMenuItem<RepeatType>(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (medicineName.isNotEmpty) {
                  context.read<MedicineProvider>().addMedicine(
                        medicineName,
                        selectedTime,
                        date: selectedDate,
                        repeatType: selectedRepeatType,
                      );
                }
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class HistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: provider.history.length,
          itemBuilder: (context, index) {
            final historyItem = provider.history[index];
            return HistoryItemCard(historyItem: historyItem);
          },
        );
      },
    );
  }
}

class HistoryItemCard extends StatelessWidget {
  final HistoryItem historyItem;

  HistoryItemCard({required this.historyItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(
          historyItem.name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Time: ${TimeOfDay(hour: historyItem.time.hour, minute: historyItem.time.minute).format(context)}',
          style: TextStyle(fontSize: 16),
        ),
        trailing: Text(
          'Action: ${historyItem.action}',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

enum RepeatType { daily, weekly, specificDay }

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
}

class HistoryProvider with ChangeNotifier {
  List<HistoryItem> _history = [];

  List<HistoryItem> get history => _history;

  void addHistoryItem(HistoryItem historyItem) {
    _history.add(historyItem);
    notifyListeners();
  }
}

class HistoryItem {
  final String name;
  final TimeOfDay time;
  final String action;

  HistoryItem({required this.name, required this.time, required this.action});
}

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService() {
    _initialize();
  }

  Future<void> _initialize() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        // Handle notification tap
      },
    );
  }

  Future<void> scheduleNotification(Medicine medicine) async {
    final DateTime now = DateTime.now();
    final DateTime scheduledDate = medicine.date ?? now;
    final DateTime scheduledDateTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      medicine.time.hour,
      medicine.time.minute,
    );

    final int id = _generateNotificationId(medicine);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Medicine Reminder',
      'It\'s time to take ${medicine.name}!',
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          'channel_description',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(Medicine medicine) async {
    final int id = _generateNotificationId(medicine);
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  int _generateNotificationId(Medicine medicine) {
    return medicine.hashCode;
  }
}
