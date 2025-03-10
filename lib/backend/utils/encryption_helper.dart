import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static const keyName = 'encryption_key';
  static late encrypt.Key key;
  static late encrypt.IV iv;
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
    iv = encrypt.IV.fromLength(16);
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  static String encryptData(String data) {
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  static String decryptData(String encryptedData) {
    final encrypted = encrypt.Encrypted(base64Decode(encryptedData));
    return encrypter.decrypt(encrypted, iv: iv);
  }
  
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
