import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/worker_model.dart';

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.read(dioProvider)),
);

class CustomerRepository {
  final Dio _dio;
  CustomerRepository(this._dio);

  Future<List<Category>> categories() async {
    try {
      final res = await _dio.get('/categories');
      return (res.data as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Worker>> searchWorkers({
    int? categoryId,
    String? query,
    bool availableOnly = true,
  }) async {
    try {
      final res = await _dio.get('/customer/workers', queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (query != null && query.isNotEmpty) 'q': query,
        'available_only': availableOnly,
      });
      return (res.data as List)
          .map((e) => Worker.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Worker> workerDetail(int userId) async {
    try {
      final res = await _dio.get('/customer/workers/$userId');
      return Worker.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Booking> createBooking({
    required int workerId,
    int? categoryId,
    required DateTime date,
    String? time,
    required String address,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/customer/bookings', data: {
        'worker_id': workerId,
        if (categoryId != null) 'category_id': categoryId,
        'booking_date': date.toIso8601String().split('T').first,
        if (time != null) 'booking_time': time,
        'address': address,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return Booking.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Post an open job (no specific worker). Admin approves it.
  Future<Booking> postJob({
    required int categoryId,
    required DateTime date,
    String? time,
    required String address,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/customer/jobs', data: {
        'category_id': categoryId,
        'booking_date': date.toIso8601String().split('T').first,
        if (time != null) 'booking_time': time,
        'address': address,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return Booking.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Booking>> myBookings({String? status}) async {
    try {
      final res = await _dio.get('/customer/bookings', queryParameters: {
        if (status != null) 'status': status,
      });
      return (res.data as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cancelBooking(int id) async {
    try {
      await _dio.post('/customer/bookings/$id/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post('/customer/bookings/$bookingId/review', data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
