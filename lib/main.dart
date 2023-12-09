import 'package:flutter/material.dart';

void main() => runApp(MedicineReminderApp());

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

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Reminder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Today\'s Medicines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            MedicineCard(
              medicineName: 'Aspirin',
              dosage: '1 tablet',
              time: '8:00 AM',
              isTaken: false,
            ),
            MedicineCard(
              medicineName: 'Ibuprofen',
              dosage: '2 tablets',
              time: '12:00 PM',
              isTaken: true,
            ),
            // Add more MedicineCard widgets for other medicines
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the add medicine screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMedicineScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class MedicineCard extends StatelessWidget {
  final String medicineName;
  final String dosage;
  final String time;
  final bool isTaken;

  MedicineCard({
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(15),
      child: ListTile(
        title: Text(
          medicineName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: $dosage'),
            Text('Time: $time'),
          ],
        ),
        trailing: Checkbox(
          value: isTaken,
          onChanged: (bool? value) {
            // Handle checkbox state change
          },
        ),
      ),
    );
  }
}

class AddMedicineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Medicine'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add form fields and buttons for adding a new medicine
            Text(
              'Add Medicine Screen',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
