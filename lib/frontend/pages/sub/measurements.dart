import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ovulize/backend/providers/cyclephasepredictor.dart';
import 'package:ovulize/backend/providers/dataprovider.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/globals.dart';

class MeasurementsPage extends StatefulWidget {
  const MeasurementsPage({super.key});

  @override
  State<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends State<MeasurementsPage> {
  List<TemperatureDay> temperatureData = [];

  @override
  void initState() {
    super.initState();
    loadTemperatureData();
  }

  Future<void> loadTemperatureData() async {
    final data = await dataProvider.getTemperatureData();
    setState(() {
      temperatureData = data.reversed.toList();
    });
  }

  Future<void> deleteTemperatureData(DateTime date) async {
    await dataProvider.db.delete('TemperatureData',
        where: 'timestamp = ?', whereArgs: [date.toIso8601String()]);
    loadTemperatureData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurements'),
      ),
      body: temperatureData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: temperatureData.length,
              itemBuilder: (context, index) {
                final item = temperatureData[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: backgroundOverlayColor,
                    subtitle:
                        Text(DateFormat("dd.MM.yyyy, hh:mm").format(item.date)),
                    title: Text(
                      "${item.temperature.toStringAsFixed(2)}°C",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VerticalDivider(
                          indent: 5,
                          endIndent: 5,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline),
                          onPressed: () => deleteTemperatureData(item.date),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
