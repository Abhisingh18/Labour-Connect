import { useMemo, useState } from "react";
import {
  Box,
  Button,
  Card,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  Typography,
} from "@mui/material";
import CancelRoundedIcon from "@mui/icons-material/CancelRounded";
import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
import PersonAddRoundedIcon from "@mui/icons-material/PersonAddRounded";
import PageHeader from "@/components/PageHeader";
import { EmptyView, ErrorView, Loading } from "@/components/Feedback";
import { BookingStatusChip } from "@/components/StatusChip";
import ConfirmDialog from "@/components/ConfirmDialog";
import { useToast } from "@/components/Toast";
import {
  useApproveJob,
  useAssignWorker,
  useBookings,
  useRejectJob,
  useUpdateBookingStatus,
  useWorkers,
} from "@/hooks/queries";
import type { Booking, BookingStatus } from "@/api/types";
import { apiErrorMessage } from "@/api/client";
import { fmtDate, fmtTime, inr } from "@/utils/format";

type Filter = "all" | BookingStatus;

export default function BookingsPage() {
  const [filter, setFilter] = useState<Filter>("all");
  const { data, isLoading, isError, error, refetch } = useBookings();
  const updateStatus = useUpdateBookingStatus();
  const assign = useAssignWorker();
  const approveJob = useApproveJob();
  const rejectJob = useRejectJob();
  const workers = useWorkers("verified");
  const { notify } = useToast();

  const [cancelTarget, setCancelTarget] = useState<Booking | null>(null);
  const [assignTarget, setAssignTarget] = useState<Booking | null>(null);
  const [selectedWorker, setSelectedWorker] = useState<number | "">("");
  const [approveTarget, setApproveTarget] = useState<Booking | null>(null);
  const [amount, setAmount] = useState<string>("");

  const rows = useMemo(() => {
    const list = data ?? [];
    if (filter === "all") return list;
    return list.filter((b) => b.status === filter);
  }, [data, filter]);

  const doCancel = async () => {
    if (!cancelTarget) return;
    try {
      await updateStatus.mutateAsync({ id: cancelTarget.id, status: "cancelled" });
      notify(`Booking #${cancelTarget.id} cancelled`, "info");
      setCancelTarget(null);
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  const doApprove = async () => {
    if (!approveTarget) return;
    const amt = Number(amount);
    if (Number.isNaN(amt) || amt < 0) {
      notify("Enter a valid amount", "error");
      return;
    }
    try {
      await approveJob.mutateAsync({ id: approveTarget.id, amount: amt });
      notify(`Job #${approveTarget.id} approved — now visible to workers`);
      setApproveTarget(null);
      setAmount("");
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  const doReject = async (b: Booking) => {
    try {
      await rejectJob.mutateAsync(b.id);
      notify(`Job #${b.id} rejected`, "info");
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  const doAssign = async () => {
    if (!assignTarget || selectedWorker === "") return;
    try {
      await assign.mutateAsync({
        bookingId: assignTarget.id,
        workerId: Number(selectedWorker),
      });
      notify(`Worker assigned to booking #${assignTarget.id}`);
      setAssignTarget(null);
      setSelectedWorker("");
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  return (
    <>
      <PageHeader
        title="Bookings & Jobs"
        subtitle="Approve posted jobs (set price), then workers accept them"
      />

      <ToggleButtonGroup
        value={filter}
        exclusive
        size="small"
        onChange={(_, v) => v && setFilter(v)}
        sx={{ mb: 2.5, flexWrap: "wrap" }}
      >
        <ToggleButton value="all">All</ToggleButton>
        <ToggleButton value="pending_approval">Needs approval</ToggleButton>
        <ToggleButton value="open">Open</ToggleButton>
        <ToggleButton value="pending">Pending</ToggleButton>
        <ToggleButton value="accepted">Accepted</ToggleButton>
        <ToggleButton value="completed">Completed</ToggleButton>
        <ToggleButton value="cancelled">Cancelled</ToggleButton>
      </ToggleButtonGroup>

      <Card>
        {isLoading ? (
          <Loading />
        ) : isError ? (
          <Box sx={{ p: 2 }}>
            <ErrorView message={apiErrorMessage(error)} onRetry={() => refetch()} />
          </Box>
        ) : rows.length === 0 ? (
          <EmptyView title="No bookings" subtitle="Try a different filter." />
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>#</TableCell>
                  <TableCell>Customer</TableCell>
                  <TableCell>Worker</TableCell>
                  <TableCell>Service</TableCell>
                  <TableCell>Schedule</TableCell>
                  <TableCell>Amount</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((b) => (
                  <TableRow key={b.id} hover>
                    <TableCell>
                      <Typography fontWeight={700} fontSize={13}>
                        #{b.id}
                      </Typography>
                    </TableCell>
                    <TableCell>{b.customer?.name ?? "—"}</TableCell>
                    <TableCell>{b.worker?.name ?? "Unassigned"}</TableCell>
                    <TableCell>{b.category?.name ?? "—"}</TableCell>
                    <TableCell>
                      <Typography fontSize={13}>{fmtDate(b.booking_date)}</Typography>
                      <Typography variant="caption" color="text.secondary">
                        {fmtTime(b.booking_time)}
                      </Typography>
                    </TableCell>
                    <TableCell>{b.amount > 0 ? inr(b.amount) : "—"}</TableCell>
                    <TableCell>
                      <BookingStatusChip status={b.status} />
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={1} justifyContent="flex-end">
                        {b.status === "pending_approval" && (
                          <>
                            <Button
                              size="small"
                              variant="contained"
                              color="success"
                              startIcon={<CheckRoundedIcon />}
                              onClick={() => {
                                setApproveTarget(b);
                                setAmount("");
                              }}
                            >
                              Approve & set price
                            </Button>
                            <Button
                              size="small"
                              variant="outlined"
                              color="error"
                              onClick={() => doReject(b)}
                            >
                              Reject
                            </Button>
                          </>
                        )}
                        {(b.status === "pending" || b.status === "accepted") && (
                          <>
                            <Button
                              size="small"
                              variant="outlined"
                              startIcon={<PersonAddRoundedIcon />}
                              onClick={() => {
                                setAssignTarget(b);
                                setSelectedWorker(b.worker_id ?? "");
                              }}
                            >
                              Assign
                            </Button>
                            <Button
                              size="small"
                              variant="outlined"
                              color="error"
                              startIcon={<CancelRoundedIcon />}
                              onClick={() => setCancelTarget(b)}
                            >
                              Cancel
                            </Button>
                          </>
                        )}
                      </Stack>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Card>

      {/* Assign worker dialog */}
      <Dialog
        open={Boolean(assignTarget)}
        onClose={() => setAssignTarget(null)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle sx={{ fontFamily: "Plus Jakarta Sans", fontWeight: 700 }}>
          Assign worker
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Reassign booking #{assignTarget?.id} to a verified worker.
          </Typography>
          <TextField
            select
            fullWidth
            label="Worker"
            value={selectedWorker}
            onChange={(e) => setSelectedWorker(Number(e.target.value))}
          >
            {(workers.data ?? [])
              .filter((w) => !w.is_suspended)
              .map((w) => (
                <MenuItem key={w.user_id} value={w.user_id}>
                  {w.name} — {w.category?.name ?? "—"}
                </MenuItem>
              ))}
          </TextField>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button color="inherit" onClick={() => setAssignTarget(null)}>
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={doAssign}
            disabled={selectedWorker === "" || assign.isPending}
          >
            Assign
          </Button>
        </DialogActions>
      </Dialog>

      {/* Approve job dialog */}
      <Dialog
        open={Boolean(approveTarget)}
        onClose={() => setApproveTarget(null)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle sx={{ fontFamily: "Plus Jakarta Sans", fontWeight: 700 }}>
          Approve job #{approveTarget?.id}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            {approveTarget?.category?.name} · {approveTarget?.customer?.name}
            {approveTarget?.customer?.phone ? ` · 📞 ${approveTarget.customer.phone}` : ""}
          </Typography>
          <Typography variant="body2" sx={{ mb: 2 }}>
            Customer ko call karke deal final karo, fir agreed amount daalke approve karo.
            Approve karte hi ye kaam workers ko dikhne lagega.
          </Typography>
          <TextField
            fullWidth
            label="Agreed amount (₹)"
            type="number"
            autoFocus
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button color="inherit" onClick={() => setApproveTarget(null)}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="success"
            onClick={doApprove}
            disabled={amount === "" || approveJob.isPending}
          >
            Approve & publish
          </Button>
        </DialogActions>
      </Dialog>

      <ConfirmDialog
        open={Boolean(cancelTarget)}
        title="Cancel booking?"
        message={`Booking #${cancelTarget?.id} will be marked cancelled.`}
        confirmLabel="Cancel booking"
        confirmColor="error"
        loading={updateStatus.isPending}
        onConfirm={doCancel}
        onClose={() => setCancelTarget(null)}
      />
    </>
  );
}
