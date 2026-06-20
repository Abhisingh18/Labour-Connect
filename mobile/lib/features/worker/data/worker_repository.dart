import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/worker_model.dart';

final workerRepositoryProvider = Provider<WorkerRepository>(
  (ref) => WorkerRepository(ref.read(dioProvider)),
);

class WorkerRepository {
  final Dio _dio;
  WorkerRepository(this._dio);

  Future<WorkerProfile> profile() async {
    try {
      final res = await _dio.get('/worker/profile');
      return WorkerProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<WorkerProfile> updateProfile({
    int? categoryId,
    int? experience,
    String? bio,
    String? serviceArea,
  }) async {
    try {
      final res = await _dio.put('/worker/profile', data: {
        if (categoryId != null) 'category_id': categoryId,
        if (experience != null) 'experience': experience,
        if (bio != null) 'bio': bio,
        if (serviceArea != null) 'service_area': serviceArea,
      });
      return WorkerProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Upload a single KYC document (validated server-side); returns its stored URL.
  Future<String> uploadKycFile(String filePath) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post('/uploads/kyc', data: form);
      return res.data['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<WorkerProfile> submitKyc({
    String? aadhaarUrl,
    String? panUrl,
    String? selfieUrl,
  }) async {
    try {
      final res = await _dio.post('/worker/kyc', data: {
        if (aadhaarUrl != null) 'aadhaar_url': aadhaarUrl,
        if (panUrl != null) 'pan_url': panUrl,
        if (selfieUrl != null) 'selfie_url': selfieUrl,
      });
      return WorkerProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<WorkerProfile> setAvailability(bool available) async {
    try {
      final res = await _dio.put('/worker/availability',
          data: {'is_available': available});
      return WorkerProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Admin-approved open jobs in this worker's category (the pool).
  Future<List<Booking>> openJobs() async {
    try {
      final res = await _dio.get('/worker/jobs/open');
      return (res.data as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Claim an open job (first-come). Throws if already taken.
  Future<void> claimJob(int id) async {
    try {
      await _dio.post('/worker/jobs/$id/claim');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Booking>> bookings({String? status}) async {
    try {
      final res = await _dio.get('/worker/bookings', queryParameters: {
        if (status != null) 'status': status,
      });
      return (res.data as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> accept(int id) => _action('$id/accept');
  Future<void> reject(int id) => _action('$id/reject');

  Future<void> complete(int id, double amount) async {
    try {
      await _dio.post('/worker/bookings/$id/complete',
          queryParameters: {'amount': amount});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> _action(String path) async {
    try {
      await _dio.post('/worker/bookings/$path');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Earnings> earnings() async {
    try {
      final res = await _dio.get('/worker/earnings');
      return Earnings.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
