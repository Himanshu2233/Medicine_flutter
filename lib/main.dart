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
      ChangeNotifierProvider(create: (context) => MedicineProvider()),
      Provider(create: (context) => NotificationService()),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Reminder'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MedicineList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AddMedicineButton(),
          ),
        ],
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

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Medicine'),
          content: Column(
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
            ],
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
                  context
                      .read<MedicineProvider>()
                      .addMedicine(medicineName, selectedTime!);
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

class MedicineProvider with ChangeNotifier {
  List<Medicine> _medicines = [];

  List<Medicine> get medicines => _medicines;

  void addMedicine(String name, TimeOfDay time) {
    final medicine = Medicine(name: name, time: time);
    _medicines.add(medicine);
    _scheduleNotification(medicine);
    _saveMedicines();
    notifyListeners();
  }

  void deleteMedicine(Medicine medicine) {
    _medicines.remove(medicine);
    _cancelNotification(medicine);
    _saveMedicines();
    notifyListeners();
  }

  Future<void> _saveMedicines() async {
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
  }

  Future<void> _cancelNotification(Medicine medicine) async {
    final notificationService = NotificationService();
    await notificationService.cancelNotification(medicine);
  }
}

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: null, macOS: null);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (payload) async {
      // Handle notification click event
    });
  }

  Future<void> scheduleNotification(Medicine medicine) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
        now.year, now.month, now.day, medicine.time.hour, medicine.time.minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime.add(Duration(days: 1));
    }

    final timeDifference = scheduledTime.difference(now);
    final secondsUntilNotification = timeDifference.inSeconds;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      medicine.hashCode,
      'Medicine Reminder',
      'It\'s time to take ${medicine.name}!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
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
    await flutterLocalNotificationsPlugin.cancel(medicine.hashCode);
  }
}

class Medicine {
  final String name;
  final TimeOfDay time;

  Medicine({required this.name, required this.time});

  Medicine.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        time = TimeOfDay(
          hour: json['hour'],
          minute: json['minute'],
        );

  Map<String, dynamic> toJson() => {
        'name': name,
        'hour': time.hour,
        'minute': time.minute,
      };
}
