import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

/// A service for securely storing sensitive data with encryption
class SecureStorage {
  // Singleton pattern
  SecureStorage._privateConstructor();
  static final SecureStorage instance = SecureStorage._privateConstructor();
  
  // Create secure storage instance with platform-specific options
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );
  
  // Encryption key storage key
  static const String _encryptionKeyKey = 'encryption_key';
  
  // Get or generate encryption key
  Future<String> _getEncryptionKey() async {
    String? encryptionKey = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (encryptionKey == null) {
      // Generate a new encryption key if none exists
      encryptionKey = base64Url.encode(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
      await _secureStorage.write(key: _encryptionKeyKey, value: encryptionKey);
    }
    
    return encryptionKey;
  }
  
  /// Encrypt data before storing
  Future<String> _encryptData(String data) async {
    final encryptionKey = await _getEncryptionKey();
    final key = encrypt.Key.fromBase64(encryptionKey);
    final iv = encrypt.IV.fromSecureRandom(16); // 128 bits
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);
    
    // Combine IV and encrypted data for storage
    final combined = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };
    
    return jsonEncode(combined);
  }
  
  /// Decrypt data after retrieving
  Future<String?> _decryptData(String? encryptedData) async {
    if (encryptedData == null) {
      return null;
    }
    
    try {
      final encryptionKey = await _getEncryptionKey();
      final key = encrypt.Key.fromBase64(encryptionKey);
      
      final combined = jsonDecode(encryptedData) as Map<String, dynamic>;
      final iv = encrypt.IV.fromBase64(combined['iv'] as String);
      final data = encrypt.Encrypted.fromBase64(combined['data'] as String);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt(data, iv: iv);
    } catch (e) {
      // If decryption fails, return null
      return null;
    }
  }
  
  /// Store data securely with encryption
  Future<void> write({required String key, required String value}) async {
    final encryptedValue = await _encryptData(value);
    await _secureStorage.write(key: _hashKey(key), value: encryptedValue);
  }
  
  /// Retrieve and decrypt data
  Future<String?> read({required String key}) async {
    final encryptedValue = await _secureStorage.read(key: _hashKey(key));
    return _decryptData(encryptedValue);
  }
  
  /// Delete data
  Future<void> delete({required String key}) async {
    await _secureStorage.delete(key: _hashKey(key));
  }
  
  /// Delete all data
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }
  
  /// Check if a key exists
  Future<bool> containsKey({required String key}) async {
    return await _secureStorage.containsKey(key: _hashKey(key));
  }
  
  /// Hash the key to prevent information leakage via key names
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Store a token securely
  Future<void> storeAuthToken(String token) async {
    await write(key: 'auth_token', value: token);
  }
  
  /// Retrieve auth token
  Future<String?> getAuthToken() async {
    return read(key: 'auth_token');
  }
  
  /// Delete auth token
  Future<void> deleteAuthToken() async {
    await delete(key: 'auth_token');
  }
  
  /// Store credit card info securely
  Future<void> storePaymentMethod({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
  }) async {
    // Only store the last 4 digits of the card number
    final last4 = cardNumber.length > 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber;
    
    // Create a payment method object
    final paymentMethod = {
      'last4': last4,
      'expiryDate': expiryDate,
      'cardHolderName': cardHolderName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Store the payment method
    await write(key: 'payment_method', value: jsonEncode(paymentMethod));
  }
  
  /// Retrieve stored payment method
  Future<Map<String, dynamic>?> getPaymentMethod() async {
    final paymentMethodJson = await read(key: 'payment_method');
    if (paymentMethodJson == null) {
      return null;
    }
    
    try {
      return jsonDecode(paymentMethodJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
} 