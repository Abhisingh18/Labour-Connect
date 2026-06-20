import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/booking_model.dart';
import '../../shared/models/worker_model.dart';
import '../data/worker_repository.dart';

final workerProfileProvider = FutureProvider<WorkerProfile>((ref) {
  return ref.read(workerRepositoryProvider).profile();
});

final workerBookingsProvider =
    FutureProvider.family<List<Booking>, String?>((ref, status) {
  return ref.read(workerRepositoryProvider).bookings(status: status);
});

final workerEarningsProvider = FutureProvider<Earnings>((ref) {
  return ref.read(workerRepositoryProvider).earnings();
});

/// Open jobs available to claim (admin-approved, worker's category).
final openJobsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.read(workerRepositoryProvider).openJobs();
});
