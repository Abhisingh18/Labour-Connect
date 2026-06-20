import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';

/// Configured Dio instance with auth-token injection and automatic
/// access-token refresh on 401 (rotating refresh tokens).
class DioClient {
  final Dio dio;
  final TokenStorage _tokenStorage;

  // Bare client used only for the refresh call (no interceptors → no recursion).
  final Dio _refreshDio;

  /// Called when the session can no longer be refreshed.
  void Function()? onUnauthorized;

  Future<bool>? _refreshing;

  DioClient(this._tokenStorage)
      : dio = Dio(_baseOptions()),
        _refreshDio = Dio(_baseOptions()) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final isAuthCall = e.requestOptions.path.contains('/auth/');
          final alreadyRetried = e.requestOptions.extra['__retried'] == true;

          if (e.response?.statusCode == 401 && !isAuthCall && !alreadyRetried) {
            final ok = await _ensureRefreshed();
            if (ok) {
              try {
                final retried = await _retry(e.requestOptions);
                return handler.resolve(retried);
              } catch (_) {
                // fall through to logout
              }
            }
            await _tokenStorage.clear();
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );
  }

  static BaseOptions _baseOptions() => BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
      );

  /// Single-flight refresh: concurrent 401s share one refresh attempt.
  Future<bool> _ensureRefreshed() {
    return _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _performRefresh() async {
    final refresh = await _tokenStorage.readRefresh();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _refreshDio.post('/auth/refresh', data: {'refresh_token': refresh});
      final access = res.data['access_token'] as String?;
      final newRefresh = res.data['refresh_token'] as String?;
      if (access == null || newRefresh == null) return false;
      await _tokenStorage.updateTokens(token: access, refreshToken: newRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions req) async {
    final token = await _tokenStorage.readToken();
    final options = Options(
      method: req.method,
      headers: {...req.headers, 'Authorization': 'Bearer $token'},
      extra: {...req.extra, '__retried': true},
    );
    return dio.request(
      req.path,
      data: req.data,
      queryParameters: req.queryParameters,
      options: options,
    );
  }
}
