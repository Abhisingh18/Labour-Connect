import { useMemo, useState } from "react";
import {
  Avatar,
  Box,
  Button,
  Card,
  Chip,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  ToggleButton,
  ToggleButtonGroup,
  Tooltip,
  Typography,
} from "@mui/material";
import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
import CloseRoundedIcon from "@mui/icons-material/CloseRounded";
import BlockRoundedIcon from "@mui/icons-material/BlockRounded";
import StarRoundedIcon from "@mui/icons-material/StarRounded";
import PageHeader from "@/components/PageHeader";
import { EmptyView, ErrorView, Loading } from "@/components/Feedback";
import { KycStatusChip } from "@/components/StatusChip";
import ConfirmDialog from "@/components/ConfirmDialog";
import { useToast } from "@/components/Toast";
import { useSuspendWorker, useVerifyWorker, useWorkers } from "@/hooks/queries";
import type { AdminWorker, KycStatus } from "@/api/types";
import { apiErrorMessage } from "@/api/client";
import { initials } from "@/utils/format";

type Filter = "all" | KycStatus;

export default function WorkersPage() {
  const [filter, setFilter] = useState<Filter>("all");
  const { data, isLoading, isError, error, refetch } = useWorkers();
  const verify = useVerifyWorker();
  const suspend = useSuspendWorker();
  const { notify } = useToast();

  const [confirm, setConfirm] = useState<{
    worker: AdminWorker;
    action: "approve" | "reject" | "suspend" | "unsuspend";
  } | null>(null);

  const rows = useMemo(() => {
    const list = data ?? [];
    if (filter === "all") return list;
    return list.filter((w) => w.kyc_status === filter);
  }, [data, filter]);

  const runConfirm = async () => {
    if (!confirm) return;
    const { worker, action } = confirm;
    try {
      if (action === "approve") {
        await verify.mutateAsync({ userId: worker.user_id, approve: true });
        notify(`${worker.name ?? "Worker"} approved`);
      } else if (action === "reject") {
        await verify.mutateAsync({ userId: worker.user_id, approve: false });
        notify(`${worker.name ?? "Worker"} rejected`, "info");
      } else if (action === "suspend") {
        await suspend.mutateAsync({ userId: worker.user_id, suspend: true });
        notify(`${worker.name ?? "Worker"} suspended`, "warning");
      } else {
        await suspend.mutateAsync({ userId: worker.user_id, suspend: false });
        notify(`${worker.name ?? "Worker"} reinstated`);
      }
      setConfirm(null);
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  const confirmCopy = () => {
    if (!confirm) return { title: "", message: "", label: "", color: "primary" as const };
    const name = confirm.worker.name ?? "this worker";
    switch (confirm.action) {
      case "approve":
        return {
          title: "Approve worker?",
          message: `${name} will be marked verified and can start receiving bookings.`,
          label: "Approve",
          color: "success" as const,
        };
      case "reject":
        return {
          title: "Reject worker?",
          message: `${name}'s KYC will be marked rejected and they cannot go online.`,
          label: "Reject",
          color: "error" as const,
        };
      case "suspend":
        return {
          title: "Suspend worker?",
          message: `${name} will be hidden from customers and taken offline.`,
          label: "Suspend",
          color: "warning" as const,
        };
      default:
        return {
          title: "Reinstate worker?",
          message: `${name} will be visible to customers again.`,
          label: "Reinstate",
          color: "success" as const,
        };
    }
  };

  const copy = confirmCopy();

  return (
    <>
      <PageHeader
        title="Workers"
        subtitle="Verify KYC, approve, reject and suspend service workers"
      />

      <ToggleButtonGroup
        value={filter}
        exclusive
        size="small"
        onChange={(_, v) => v && setFilter(v)}
        sx={{ mb: 2.5, flexWrap: "wrap" }}
      >
        <ToggleButton value="all">All</ToggleButton>
        <ToggleButton value="pending">Pending KYC</ToggleButton>
        <ToggleButton value="verified">Verified</ToggleButton>
        <ToggleButton value="rejected">Rejected</ToggleButton>
        <ToggleButton value="not_submitted">No KYC</ToggleButton>
      </ToggleButtonGroup>

      <Card>
        {isLoading ? (
          <Loading />
        ) : isError ? (
          <Box sx={{ p: 2 }}>
            <ErrorView message={apiErrorMessage(error)} onRetry={() => refetch()} />
          </Box>
        ) : rows.length === 0 ? (
          <EmptyView title="No workers found" subtitle="Try a different filter." />
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Worker</TableCell>
                  <TableCell>Service</TableCell>
                  <TableCell>Experience</TableCell>
                  <TableCell>Rating</TableCell>
                  <TableCell>KYC</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((w) => (
                  <TableRow key={w.id} hover>
                    <TableCell>
                      <Stack direction="row" spacing={1.5} alignItems="center">
                        <Avatar sx={{ bgcolor: "primary.main", width: 38, height: 38, fontSize: 14 }}>
                          {initials(w.name)}
                        </Avatar>
                        <Box>
                          <Typography fontWeight={600} fontSize={14}>
                            {w.name ?? "—"}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {w.phone ?? "—"}
                          </Typography>
                        </Box>
                      </Stack>
                    </TableCell>
                    <TableCell>{w.category?.name ?? "—"}</TableCell>
                    <TableCell>{w.experience} yr</TableCell>
                    <TableCell>
                      <Stack direction="row" spacing={0.5} alignItems="center">
                        <StarRoundedIcon sx={{ fontSize: 16, color: "#F59E0B" }} />
                        <Typography fontSize={14}>
                          {w.rating > 0 ? w.rating.toFixed(1) : "New"}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          ({w.rating_count})
                        </Typography>
                      </Stack>
                    </TableCell>
                    <TableCell>
                      <KycStatusChip status={w.kyc_status} />
                    </TableCell>
                    <TableCell>
                      {w.is_suspended ? (
                        <Chip size="small" color="error" label="Suspended" />
                      ) : w.is_verified ? (
                        <Chip size="small" color="success" variant="outlined" label="Active" />
                      ) : (
                        <Chip size="small" variant="outlined" label="Unverified" />
                      )}
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={1} justifyContent="flex-end">
                        {!w.is_verified && (
                          <Tooltip title="Approve">
                            <Button
                              size="small"
                              variant="contained"
                              color="success"
                              startIcon={<CheckRoundedIcon />}
                              onClick={() => setConfirm({ worker: w, action: "approve" })}
                            >
                              Approve
                            </Button>
                          </Tooltip>
                        )}
                        {w.kyc_status !== "rejected" && !w.is_verified && (
                          <Tooltip title="Reject">
                            <Button
                              size="small"
                              variant="outlined"
                              color="error"
                              startIcon={<CloseRoundedIcon />}
                              onClick={() => setConfirm({ worker: w, action: "reject" })}
                            >
                              Reject
                            </Button>
                          </Tooltip>
                        )}
                        {w.is_verified && (
                          <Tooltip title={w.is_suspended ? "Reinstate" : "Suspend"}>
                            <Button
                              size="small"
                              variant="outlined"
                              color={w.is_suspended ? "success" : "warning"}
                              startIcon={<BlockRoundedIcon />}
                              onClick={() =>
                                setConfirm({
                                  worker: w,
                                  action: w.is_suspended ? "unsuspend" : "suspend",
                                })
                              }
                            >
                              {w.is_suspended ? "Reinstate" : "Suspend"}
                            </Button>
                          </Tooltip>
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

      <ConfirmDialog
        open={Boolean(confirm)}
        title={copy.title}
        message={copy.message}
        confirmLabel={copy.label}
        confirmColor={copy.color}
        loading={verify.isPending || suspend.isPending}
        onConfirm={runConfirm}
        onClose={() => setConfirm(null)}
      />
    </>
  );
}
