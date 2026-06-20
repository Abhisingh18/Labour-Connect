import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dioProvider)),
);

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  /// Returns the dev OTP code when the backend is in mock mode (else null).
  Future<String?> sendOtp(String phone) async {
    try {
      final res = await _dio.post('/auth/send-otp', data: {'phone': phone});
      return res.data['dev_otp'] as String?;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
    required String role,
    String? name,
  }) async {
    try {
      final res = await _dio.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
        'role': role,
        if (name != null) 'name': name,
      });
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Best-effort server-side revoke of the refresh token.
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
    } on DioException {
      // ignore — local session is cleared regardless
    }
  }

  Future<AppUser> me() async {
    try {
      final res = await _dio.get('/auth/me');
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser> updateProfile({String? name, String? profileImage}) async {
    try {
      final res = await _dio.put('/profile', data: {
        if (name != null) 'name': name,
        if (profileImage != null) 'profile_image': profileImage,
      });
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
