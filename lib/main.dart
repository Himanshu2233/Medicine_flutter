import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MedicineReminderApp());
}

class MedicineReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Medicine> medicines = [];

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadMedicines();
  }

  Future<void> initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: null, macOS: null);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  Future<void> _showNotification(String medicineName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Medicine Reminder',
      'It\'s time to take $medicineName!',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  Future<void> selectNotification(String? payload) async {
    // Handle notification click event
  }

  Future<void> loadMedicines() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/medicines.json');

      if (file.existsSync()) {
        final content = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(content);

        setState(() {
          medicines = decoded.map((json) => Medicine.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading medicines: $e');
    }
  }

  Future<void> saveMedicines() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/medicines.json');

      final encoded = jsonEncode(medicines);
      await file.writeAsString(encoded);
    } catch (e) {
      print('Error saving medicines: $e');
    }
  }

  void addMedicine(String name, TimeOfDay time) {
    final medicine = Medicine(name: name, time: time);

    setState(() {
      medicines.add(medicine);
    });

    saveMedicines();
    scheduleNotification(medicine);
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

    var tz;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
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
            child: ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final medicine = medicines[index];
                return ListTile(
                  title: Text(medicine.name),
                  subtitle: Text(
                      'Time: ${medicine.time.hour}:${medicine.time.minute}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showAddMedicineDialog(context);
              },
              child: Text('Add Medicine'),
            ),
          ),
        ],
      ),
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
            children: [
              TextField(
                onChanged: (value) {
                  medicineName = value;
                },
                decoration: InputDecoration(labelText: 'Medicine Name'),
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
                  addMedicine(medicineName, selectedTime!);
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
