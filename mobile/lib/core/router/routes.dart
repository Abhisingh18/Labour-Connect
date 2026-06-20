/// Centralised route paths.
class Routes {
  Routes._();

  static const splash = '/';
  static const roleSelect = '/role';
  static const login = '/login'; // ?role=customer|worker
  static const otp = '/otp';

  // Customer shell
  static const customerHome = '/customer';
  static const customerBookings = '/customer/bookings';
  static const customerProfile = '/customer/profile';
  static const postJob = '/customer/post-job'; // ?categoryId=
  static const categoryWorkers = '/customer/workers'; // ?categoryId=&title=
  static const workerDetail = '/customer/worker'; // /:id
  static const createBooking = '/customer/book'; // /:workerId
  static const bookingDetail = '/customer/booking'; // /:id

  // Worker shell
  static const workerHome = '/worker';
  static const workerRequests = '/worker/requests';
  static const workerEarnings = '/worker/earnings';
  static const workerProfile = '/worker/profile';
  static const workerAvailableJobs = '/worker/available-jobs';
  static const workerKyc = '/worker/kyc';
  static const workerEditProfile = '/worker/edit';
  static const workerBookingDetail = '/worker/booking'; // /:id
}
