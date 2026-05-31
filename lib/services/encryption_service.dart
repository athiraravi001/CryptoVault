import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  // Derive a 32-byte key from password using PBKDF2
  static Uint8List deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, 10000, 32));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  // Generate random salt
  static Uint8List generateSalt() {
    final secureRandom = FortunaRandom();
    final seedSource = DateTime.now().millisecondsSinceEpoch;
    secureRandom.seed(
      KeyParameter(
        Uint8List.fromList(
          utf8.encode(seedSource.toString().padRight(32, '0')),
        ),
      ),
    );
    return secureRandom.nextBytes(16);
  }

  // Encrypt text — returns base64 string (salt + iv + ciphertext)
  static String encryptText(String plainText, String password) {
    final salt = generateSalt();
    final key = deriveKey(password, salt);

    final encKey = enc.Key(key);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine: salt (16) + iv (16) + ciphertext
    final combined = Uint8List(16 + 16 + encrypted.bytes.length);
    combined.setRange(0, 16, salt);
    combined.setRange(16, 32, iv.bytes);
    combined.setRange(32, combined.length, encrypted.bytes);

    return base64.encode(combined);
  }

  // Decrypt text — takes base64 string + password
  static String decryptText(String encryptedBase64, String password) {
    final combined = base64.decode(encryptedBase64);

    final salt = Uint8List.fromList(combined.sublist(0, 16));
    final iv = enc.IV(Uint8List.fromList(combined.sublist(16, 32)));
    final cipherBytes = combined.sublist(32);

    final key = deriveKey(password, salt);
    final encKey = enc.Key(key);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));

    return encrypter.decrypt(enc.Encrypted(cipherBytes), iv: iv);
  }

  // Generate SHA-256 hash of any bytes (for integrity check)
  static String generateHash(Uint8List data) {
    return sha256.convert(data).toString();
  }

  // Encrypt raw bytes — for file encryption
  static Uint8List encryptBytes(Uint8List data, String password) {
    final salt = generateSalt();
    final key = deriveKey(password, salt);
    final encKey = enc.Key(key);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    final combined = Uint8List(16 + 16 + encrypted.bytes.length);
    combined.setRange(0, 16, salt);
    combined.setRange(16, 32, iv.bytes);
    combined.setRange(32, combined.length, encrypted.bytes);
    return combined;
  }

  // Decrypt raw bytes — for file decryption
  static Uint8List decryptBytes(Uint8List data, String password) {
    final salt = Uint8List.fromList(data.sublist(0, 16));
    final iv = enc.IV(Uint8List.fromList(data.sublist(16, 32)));
    final cipherBytes = data.sublist(32);
    final key = deriveKey(password, salt);
    final encKey = enc.Key(key);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
    return Uint8List.fromList(
      encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv),
    );
  }
}
