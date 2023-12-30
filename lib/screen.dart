import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';
import 'widgets.dart';

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
