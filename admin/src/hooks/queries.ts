import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import * as api from "@/api/services";
import type { BookingStatus, KycStatus } from "@/api/types";

const keys = {
  dashboard: ["dashboard"] as const,
  workers: (kyc?: KycStatus) => ["workers", kyc ?? "all"] as const,
  customers: ["customers"] as const,
  categories: ["categories"] as const,
  bookings: (status?: BookingStatus) => ["bookings", status ?? "all"] as const,
  reviews: ["reviews"] as const,
};

// ---- Dashboard ----
export const useDashboard = () =>
  useQuery({ queryKey: keys.dashboard, queryFn: api.fetchDashboard });

// ---- Workers ----
export const useWorkers = (kyc?: KycStatus) =>
  useQuery({ queryKey: keys.workers(kyc), queryFn: () => api.fetchWorkers(kyc) });

export function useVerifyWorker() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, approve }: { userId: number; approve: boolean }) =>
      api.verifyWorker(userId, approve),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["workers"] });
      qc.invalidateQueries({ queryKey: keys.dashboard });
    },
  });
}

export function useSuspendWorker() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, suspend }: { userId: number; suspend: boolean }) =>
      api.suspendWorker(userId, suspend),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["workers"] }),
  });
}

// ---- Customers ----
export const useCustomers = () =>
  useQuery({ queryKey: keys.customers, queryFn: api.fetchCustomers });

export function useBlockUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, suspend }: { userId: number; suspend: boolean }) =>
      api.blockUser(userId, suspend),
    onSuccess: () => qc.invalidateQueries({ queryKey: keys.customers }),
  });
}

export function useDeleteUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (userId: number) => api.deleteUser(userId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: keys.customers });
      qc.invalidateQueries({ queryKey: keys.dashboard });
    },
  });
}

// ---- Categories ----
export const useCategories = () =>
  useQuery({ queryKey: keys.categories, queryFn: api.fetchCategories });

export function useCreateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: api.createCategory,
    onSuccess: () => qc.invalidateQueries({ queryKey: keys.categories }),
  });
}

export function useUpdateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: number;
      data: { name?: string; icon?: string; is_active?: boolean };
    }) => api.updateCategory(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: keys.categories }),
  });
}

export function useDeleteCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => api.deleteCategory(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: keys.categories }),
  });
}

// ---- Bookings ----
export const useBookings = (status?: BookingStatus) =>
  useQuery({ queryKey: keys.bookings(status), queryFn: () => api.fetchBookings(status) });

export function useUpdateBookingStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      status,
      amount,
    }: {
      id: number;
      status: BookingStatus;
      amount?: number;
    }) => api.updateBookingStatus(id, status, amount),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["bookings"] });
      qc.invalidateQueries({ queryKey: keys.dashboard });
    },
  });
}

export function useApproveJob() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, amount }: { id: number; amount: number }) =>
      api.approveJob(id, amount),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["bookings"] });
      qc.invalidateQueries({ queryKey: keys.dashboard });
    },
  });
}

export function useRejectJob() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => api.rejectJob(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["bookings"] }),
  });
}

export function useAssignWorker() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ bookingId, workerId }: { bookingId: number; workerId: number }) =>
      api.assignWorker(bookingId, workerId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["bookings"] }),
  });
}

// ---- Reviews ----
export const useReviews = () =>
  useQuery({ queryKey: keys.reviews, queryFn: api.fetchReviews });

export function useHideReview() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, suspend }: { id: number; suspend: boolean }) =>
      api.hideReview(id, suspend),
    onSuccess: () => qc.invalidateQueries({ queryKey: keys.reviews }),
  });
}
