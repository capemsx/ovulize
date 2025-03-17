import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static const keyName = 'encryption_key';
  static late encrypt.Key key;
  static late encrypt.Encrypter encrypter;
  static final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  
  static Future<void> init() async {
    String? keyString = await secureStorage.read(key: keyName);
    if (keyString == null) {
      final newKey = encrypt.Key.fromSecureRandom(32);
      await secureStorage.write(key: keyName, value: base64Encode(newKey.bytes));
      keyString = base64Encode(newKey.bytes);
    }
    
    key = encrypt.Key(base64Decode(keyString));
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  static String encryptData(String data) {
    // Generiere für jede Verschlüsselung einen neuen IV
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    
    // Speichere IV zusammen mit verschlüsselten Daten 
    // Format: base64(iv) + ':' + base64(encryptedData)
    return base64Encode(iv.bytes) + ':' + encrypted.base64;
  }

  static String decryptData(String encryptedData) {
    try {
      // Extrahiere IV und verschlüsselte Daten
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw FormatException('Ungültiges Datenformat');
      }
      
      final iv = encrypt.IV(base64Decode(parts[0]));
      final encrypted = encrypt.Encrypted(base64Decode(parts[1]));
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Entschlüsselungsfehler: $e');
    }
  }
  
  // Die restlichen Methoden bleiben unverändert
  static double? decryptDouble(String? encryptedData) {
    if (encryptedData == null) return null;
    final decrypted = decryptData(encryptedData);
    return double.tryParse(decrypted);
  }
  
  static String encryptDouble(double value) {
    return encryptData(value.toString());
  }
  
  static DateTime? decryptDateTime(String? encryptedData) {
    if (encryptedData == null) return null;
    final decrypted = decryptData(encryptedData);
    return DateTime.tryParse(decrypted);
  }
  
  static String encryptDateTime(DateTime dateTime) {
    return encryptData(dateTime.toIso8601String());
  }
}