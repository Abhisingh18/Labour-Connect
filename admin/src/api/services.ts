import api from "./client";
import type {
  AdminWorker,
  AppUser,
  Booking,
  BookingStatus,
  Category,
  DashboardStats,
  KycStatus,
  ReviewLite,
  Token,
} from "./types";

// ---- Auth ----
export const login = (email: string, password: string) =>
  api.post<Token>("/auth/admin/login", { email, password }).then((r) => r.data);

export const fetchMe = () => api.get<AppUser>("/auth/me").then((r) => r.data);

export const logoutRequest = (refreshToken: string) =>
  api.post("/auth/logout", { refresh_token: refreshToken }).then((r) => r.data);

// ---- Dashboard ----
export const fetchDashboard = () =>
  api.get<DashboardStats>("/admin/dashboard").then((r) => r.data);

// ---- Workers ----
export const fetchWorkers = (kycStatus?: KycStatus) =>
  api
    .get<AdminWorker[]>("/admin/workers", {
      params: kycStatus ? { kyc_status: kycStatus } : {},
    })
    .then((r) => r.data);

export const verifyWorker = (userId: number, approve: boolean) =>
  api.post(`/admin/workers/${userId}/verify`, { approve }).then((r) => r.data);

export const suspendWorker = (userId: number, suspend: boolean) =>
  api.post(`/admin/workers/${userId}/suspend`, { suspend }).then((r) => r.data);

// ---- Customers ----
export const fetchCustomers = () =>
  api.get<AppUser[]>("/admin/customers").then((r) => r.data);

export const blockUser = (userId: number, suspend: boolean) =>
  api.post(`/admin/users/${userId}/block`, { suspend }).then((r) => r.data);

export const deleteUser = (userId: number) =>
  api.delete(`/admin/users/${userId}`).then((r) => r.data);

// ---- Categories ----
export const fetchCategories = () =>
  api.get<Category[]>("/admin/categories").then((r) => r.data);

export const createCategory = (data: { name: string; icon?: string; is_active?: boolean }) =>
  api.post<Category>("/admin/categories", data).then((r) => r.data);

export const updateCategory = (
  id: number,
  data: { name?: string; icon?: string; is_active?: boolean },
) => api.put<Category>(`/admin/categories/${id}`, data).then((r) => r.data);

export const deleteCategory = (id: number) =>
  api.delete(`/admin/categories/${id}`).then((r) => r.data);

// ---- Bookings ----
export const fetchBookings = (status?: BookingStatus) =>
  api
    .get<Booking[]>("/admin/bookings", { params: status ? { status } : {} })
    .then((r) => r.data);

export const updateBookingStatus = (
  id: number,
  status: BookingStatus,
  amount?: number,
) =>
  api
    .put<Booking>(`/admin/bookings/${id}/status`, { status, amount })
    .then((r) => r.data);

export const approveJob = (bookingId: number, amount: number) =>
  api.post<Booking>(`/admin/jobs/${bookingId}/approve`, { amount }).then((r) => r.data);

export const rejectJob = (bookingId: number) =>
  api.post<Booking>(`/admin/jobs/${bookingId}/reject`).then((r) => r.data);

export const assignWorker = (bookingId: number, workerId: number) =>
  api
    .post<Booking>(`/admin/bookings/${bookingId}/assign`, null, {
      params: { worker_id: workerId },
    })
    .then((r) => r.data);

// ---- Reviews ----
export const fetchReviews = () =>
  api.get<ReviewLite[]>("/admin/reviews").then((r) => r.data);

export const hideReview = (id: number, suspend: boolean) =>
  api.post<ReviewLite>(`/admin/reviews/${id}/hide`, { suspend }).then((r) => r.data);
