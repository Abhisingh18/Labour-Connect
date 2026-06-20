import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/role_select_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/customer/presentation/booking_detail_screen.dart';
import '../../features/customer/presentation/create_booking_screen.dart';
import '../../features/customer/presentation/customer_shell.dart';
import '../../features/customer/presentation/post_job_screen.dart';
import '../../features/customer/presentation/worker_detail_screen.dart';
import '../../features/customer/presentation/workers_list_screen.dart';
import '../../features/shared/models/booking_model.dart';
import '../../features/shared/models/worker_model.dart';
import '../../features/worker/presentation/available_jobs_screen.dart';
import '../../features/worker/presentation/worker_edit_profile_screen.dart';
import '../../features/worker/presentation/worker_kyc_screen.dart';
import '../../features/worker/presentation/worker_shell.dart';
import 'routes.dart';

/// Bridges Riverpod state changes to go_router's refresh mechanism.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) {
        return loc == Routes.splash ? null : Routes.splash;
      }

      final authRoutes = {Routes.splash, Routes.roleSelect, Routes.login, Routes.otp};
      final inAuthFlow = authRoutes.contains(loc);

      if (auth.status == AuthStatus.unauthenticated) {
        return inAuthFlow && loc != Routes.splash ? null : Routes.roleSelect;
      }

      // Authenticated: keep users inside their role's section.
      final isWorker = auth.role == 'worker';
      if (inAuthFlow) {
        return isWorker ? Routes.workerHome : Routes.customerHome;
      }
      if (isWorker && loc.startsWith('/customer')) return Routes.workerHome;
      if (!isWorker && loc.startsWith('/worker')) return Routes.customerHome;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.roleSelect, builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, state) => LoginScreen(
          role: state.uri.queryParameters['role'] ?? 'customer',
        ),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            phone: extra['phone'] as String? ?? '',
            role: extra['role'] as String? ?? 'customer',
            devOtp: extra['devOtp'] as String?,
          );
        },
      ),

      // ---- Customer ----
      GoRoute(path: Routes.customerHome, builder: (_, __) => const CustomerShell()),
      GoRoute(
        path: Routes.customerBookings,
        builder: (_, __) => const CustomerShell(initialIndex: 1),
      ),
      GoRoute(
        path: Routes.customerProfile,
        builder: (_, __) => const CustomerShell(initialIndex: 2),
      ),
      GoRoute(
        path: Routes.postJob,
        builder: (_, state) => PostJobScreen(
          initialCategoryId:
              int.tryParse(state.uri.queryParameters['categoryId'] ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.categoryWorkers,
        builder: (_, state) => WorkersListScreen(
          categoryId: int.tryParse(state.uri.queryParameters['categoryId'] ?? ''),
          title: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        path: '${Routes.workerDetail}/:id',
        builder: (_, state) =>
            WorkerDetailScreen(workerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '${Routes.createBooking}/:workerId',
        builder: (_, state) =>
            CreateBookingScreen(worker: state.extra as Worker),
      ),
      GoRoute(
        path: '${Routes.bookingDetail}/:id',
        builder: (_, state) =>
            CustomerBookingDetailScreen(booking: state.extra as Booking),
      ),

      // ---- Worker ----
      GoRoute(path: Routes.workerHome, builder: (_, __) => const WorkerShell()),
      GoRoute(
        path: Routes.workerRequests,
        builder: (_, __) => const WorkerShell(initialIndex: 1),
      ),
      GoRoute(
        path: Routes.workerEarnings,
        builder: (_, __) => const WorkerShell(initialIndex: 2),
      ),
      GoRoute(
        path: Routes.workerProfile,
        builder: (_, __) => const WorkerShell(initialIndex: 3),
      ),
      GoRoute(
        path: Routes.workerAvailableJobs,
        builder: (_, __) => const AvailableJobsScreen(),
      ),
      GoRoute(path: Routes.workerKyc, builder: (_, __) => const WorkerKycScreen()),
      GoRoute(
        path: Routes.workerEditProfile,
        builder: (_, state) =>
            WorkerEditProfileScreen(profile: state.extra as WorkerProfile),
      ),
    ],
  );
});
