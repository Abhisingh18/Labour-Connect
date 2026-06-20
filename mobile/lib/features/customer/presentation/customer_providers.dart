import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/booking_model.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/worker_model.dart';
import '../data/customer_repository.dart';

/// Active service categories (home screen grid).
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(customerRepositoryProvider).categories();
});

/// Search filter for worker listings.
class WorkerQuery {
  final int? categoryId;
  final String query;
  final bool availableOnly;

  const WorkerQuery({this.categoryId, this.query = '', this.availableOnly = true});

  WorkerQuery copyWith({int? categoryId, String? query, bool? availableOnly, bool clearCategory = false}) {
    return WorkerQuery(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      query: query ?? this.query,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }
}

final workerListProvider =
    FutureProvider.family<List<Worker>, WorkerQuery>((ref, q) {
  return ref.read(customerRepositoryProvider).searchWorkers(
        categoryId: q.categoryId,
        query: q.query,
        availableOnly: q.availableOnly,
      );
});

/// Featured workers for the home screen (top-rated, available).
final featuredWorkersProvider = FutureProvider<List<Worker>>((ref) {
  return ref.read(customerRepositoryProvider).searchWorkers(availableOnly: true);
});

final workerDetailProvider =
    FutureProvider.family<Worker, int>((ref, userId) {
  return ref.read(customerRepositoryProvider).workerDetail(userId);
});

/// Customer bookings, optionally filtered by a status group.
final customerBookingsProvider =
    FutureProvider.family<List<Booking>, String?>((ref, status) {
  return ref.read(customerRepositoryProvider).myBookings(status: status);
});
