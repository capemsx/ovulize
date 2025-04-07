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

Future<int> deleteTemperatureDataByDay(DateTime date) async {
  // Alle Datensätze laden
  List<Map<String, dynamic>> allRecords = await db.query('TemperatureData');
  List<int> recordsToDelete = [];
  
  // Alle Datumseinträge durchgehen und Übereinstimmungen finden
  for (var record in allRecords) {
    DateTime? recordDate = EncryptionHelper.decryptDateTime(record['timestamp']);
    
    if (recordDate != null) {
      // Vergleich nur Datum (ohne Uhrzeit)
      bool sameDay = recordDate.year == date.year && 
                    recordDate.month == date.month && 
                    recordDate.day == date.day;
                    
      if (sameDay) {
        recordsToDelete.add(record['id'] as int);
      }
    }
  }
  
  // Gefundene Einträge löschen
  int count = 0;
  for (var id in recordsToDelete) {
    count += await db.delete(
      'TemperatureData',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  return count;
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
