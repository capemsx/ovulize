import 'package:ovulize/backend/providers/cyclephasepredictor.dart';
import 'package:ovulize/backend/utils/encryption_helper.dart';
import 'package:sqflite/sqflite.dart';

class DataProvider {
  late Database db;
  Future<void> init() async {
    await EncryptionHelper.init();

    db = await openDatabase(
      'ovulize_data.db',
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE TemperatureData (id INTEGER PRIMARY KEY, timestamp TEXT, temperature_value TEXT, num REAL)',
        );
        print("Database setup!");
      },
      version: 1,
    );
  }

  Future<List<TemperatureDay>> getTemperatureData() async {
    List<Map<String, dynamic>> dbItems =
        await db.query('TemperatureData', orderBy: 'timestamp ASC');
    return dbItems
        .map((e) => TemperatureDay(
              date: EncryptionHelper.decryptDateTime(e['timestamp'])!,
              temperature:
                  EncryptionHelper.decryptDouble(e['temperature_value'])!,
            ))
        .toList();
  }

  Future<void> insertTemperatureData(
      DateTime timestamp, double temperatureValue) async {
    String encryptedDateStr = EncryptionHelper.encryptDateTime(timestamp);
    String encryptedTempValue =
        EncryptionHelper.encryptDouble(temperatureValue);

    await db.delete(
      'TemperatureData',
      where: 'timestamp = ?',
      whereArgs: [encryptedDateStr],
    );

    await db.insert(
      'TemperatureData',
      {'timestamp': encryptedDateStr, 'temperature_value': encryptedTempValue},
    );
  }

  Future<void> close() async {
    await db.close();
  }
}
