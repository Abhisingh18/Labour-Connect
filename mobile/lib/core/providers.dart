import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/dio_client.dart';
import 'storage/token_storage.dart';

/// Secure token storage singleton.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Configured Dio client. Wired to clear auth on 401 (see auth controller).
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.read(tokenStorageProvider));
});

/// Raw Dio for repositories.
final dioProvider = Provider<Dio>((ref) => ref.read(dioClientProvider).dio);
