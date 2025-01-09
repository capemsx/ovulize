import 'package:ovulize/backend/providers/cyclephasepredictor.dart';
import 'package:sqflite/sqflite.dart';

class DataProvider {
  late Database db;
  Future<void> init() async {
    db = await openDatabase(
      'ovulize_data.db',
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE TemperatureData (id INTEGER PRIMARY KEY, timestamp DATETIME, temperature_value DOUBLE, num REAL)',
        );
        print("Database setup!");
      },
      version: 1,
    );
  }

  Future<List<TemperatureDay>> getTemperatureData() async {
    List<Map<String, dynamic>> dbItems =  await db.query('TemperatureData', orderBy: 'timestamp ASC');
    return dbItems.map((e) => TemperatureDay(
      date: DateTime.parse(e['timestamp']),
      temperature: e['temperature_value'],
    )).toList();
  }
  Future<void> insertTemperatureData(
      DateTime timestamp, double temperatureValue) async {
        await db.delete(
          'TemperatureData',
          where: 'DATE(timestamp) = DATE(?)',
          whereArgs: [timestamp.toIso8601String()],
        );
    await db.insert(
      'TemperatureData',
      {'timestamp': timestamp.toIso8601String(), 'temperature_value': temperatureValue},
    );
  }

  Future<void> close() async {
    await db.close();
  }
}
