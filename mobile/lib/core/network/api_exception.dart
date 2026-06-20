import 'package:dio/dio.dart';

/// Normalised API error with a user-friendly [message].
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException('Connection timed out. Please try again.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        'Could not reach the server. Check your internet connection.',
      );
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Something went wrong. Please try again.';

    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        // FastAPI validation error shape
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          message = first['msg'].toString();
        }
      }
    } else if (status == 401) {
      message = 'Session expired. Please log in again.';
    } else if (status == 403) {
      message = 'You do not have permission to do that.';
    }

    return ApiException(message, statusCode: status);
  }

  @override
  String toString() => message;
}
