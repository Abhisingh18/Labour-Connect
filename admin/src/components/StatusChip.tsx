import { Chip } from "@mui/material";
import type { BookingStatus, KycStatus } from "@/api/types";

const BOOKING: Record<
  BookingStatus,
  { label: string; color: "default" | "warning" | "info" | "success" | "error" }
> = {
  pending_approval: { label: "Needs approval", color: "warning" },
  open: { label: "Open (finding worker)", color: "info" },
  pending: { label: "Pending", color: "warning" },
  accepted: { label: "Accepted", color: "info" },
  completed: { label: "Completed", color: "success" },
  rejected: { label: "Rejected", color: "error" },
  cancelled: { label: "Cancelled", color: "default" },
};

const KYC: Record<
  KycStatus,
  { label: string; color: "default" | "warning" | "success" | "error" }
> = {
  not_submitted: { label: "Not submitted", color: "default" },
  pending: { label: "Under review", color: "warning" },
  verified: { label: "Verified", color: "success" },
  rejected: { label: "Rejected", color: "error" },
};

export function BookingStatusChip({ status }: { status: BookingStatus }) {
  const s = BOOKING[status];
  return <Chip size="small" variant="outlined" label={s.label} color={s.color} />;
}

export function KycStatusChip({ status }: { status: KycStatus }) {
  const s = KYC[status];
  return <Chip size="small" variant="outlined" label={s.label} color={s.color} />;
}
