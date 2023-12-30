import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';

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
    TimeOfDay? selectedTime;
    selectedTime = TimeOfDay.now();
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
                        selectedTime!,
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
