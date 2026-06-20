import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT, role and user id.
///
/// On mobile uses encrypted secure storage. On **web** `flutter_secure_storage`
/// relies on `crypto.subtle`, which only exists in a secure context (HTTPS or
/// localhost) — so over plain-HTTP LAN testing we fall back to localStorage
/// (`shared_preferences`). Same public API for both.
class TokenStorage {
  static const _kToken = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'role';
  static const _kUserId = 'user_id';

  final FlutterSecureStorage? _secure;

  TokenStorage([FlutterSecureStorage? storage])
      : _secure = kIsWeb
            ? null
            : (storage ??
                const FlutterSecureStorage(
                  aOptions: AndroidOptions(encryptedSharedPreferences: true),
                ));

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secure!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return _secure!.read(key: key);
  }

  Future<void> save({
    required String token,
    required String refreshToken,
    required String role,
    required int userId,
  }) async {
    await _write(_kToken, token);
    await _write(_kRefresh, refreshToken);
    await _write(_kRole, role);
    await _write(_kUserId, userId.toString());
  }

  /// Update just the token pair after a refresh.
  Future<void> updateTokens({required String token, required String refreshToken}) async {
    await _write(_kToken, token);
    await _write(_kRefresh, refreshToken);
  }

  Future<String?> readToken() => _read(_kToken);
  Future<String?> readRefresh() => _read(_kRefresh);
  Future<String?> readRole() => _read(_kRole);

  Future<int?> readUserId() async {
    final v = await _read(_kUserId);
    return v == null ? null : int.tryParse(v);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_kToken),
        prefs.remove(_kRefresh),
        prefs.remove(_kRole),
        prefs.remove(_kUserId),
      ]);
    } else {
      await _secure!.deleteAll();
    }
  }
}
