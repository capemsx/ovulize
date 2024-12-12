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

  Future<List<Map<String, dynamic>>> getTemperatureData() async {
    return await db.query('TemperatureData', orderBy: 'timestamp ASC');
  }
  Future<void> insertTemperatureData(
      DateTime timestamp, double temperatureValue) async {
    await db.insert(
      'TemperatureData',
      {'timestamp': timestamp.toIso8601String(), 'temperature_value': temperatureValue},
    );
  }

  Future<void> close() async {
    await db.close();
  }
}
