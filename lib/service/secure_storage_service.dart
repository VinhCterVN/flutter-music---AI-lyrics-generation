import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._internal();
  factory SecureStorageService() => instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);
}
