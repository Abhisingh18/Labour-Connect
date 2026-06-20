export type UserRole = "customer" | "worker" | "admin";
export type BookingStatus =
  | "pending_approval"
  | "open"
  | "pending"
  | "accepted"
  | "rejected"
  | "completed"
  | "cancelled";
export type KycStatus = "not_submitted" | "pending" | "verified" | "rejected";

export interface Token {
  access_token: string;
  refresh_token: string;
  token_type: string;
  role: UserRole;
  user_id: number;
}

export interface AccessToken {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

export interface AppUser {
  id: number;
  name: string;
  phone?: string | null;
  email?: string | null;
  role: UserRole;
  profile_image?: string | null;
  is_active: boolean;
  created_at: string;
}

export interface Category {
  id: number;
  name: string;
  icon?: string | null;
  is_active: boolean;
}

export interface DashboardStats {
  total_customers: number;
  total_workers: number;
  verified_workers: number;
  pending_kyc: number;
  total_bookings: number;
  completed_bookings: number;
  pending_bookings: number;
  total_revenue: number;
}

export interface AdminWorker {
  id: number;
  user_id: number;
  category_id?: number | null;
  experience: number;
  bio?: string | null;
  service_area?: string | null;
  kyc_status: KycStatus;
  is_verified: boolean;
  is_available: boolean;
  is_suspended: boolean;
  rating: number;
  rating_count: number;
  category?: Category | null;
  name?: string | null;
  phone?: string | null;
  is_active?: boolean | null;
}

export interface BookingParty {
  id: number;
  name: string;
  phone?: string | null;
  profile_image?: string | null;
}

export interface ReviewLite {
  id: number;
  booking_id: number;
  rating: number;
  comment?: string | null;
  is_hidden: boolean;
  created_at: string;
}

export interface Booking {
  id: number;
  customer_id: number;
  worker_id?: number | null;
  category_id?: number | null;
  booking_date: string;
  booking_time?: string | null;
  address: string;
  notes?: string | null;
  status: BookingStatus;
  amount: number;
  is_open_request: boolean;
  created_at: string;
  customer?: BookingParty | null;
  worker?: BookingParty | null;
  category?: Category | null;
  review?: ReviewLite | null;
}
