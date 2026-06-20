import { useState } from "react";
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
  Typography,
} from "@mui/material";
import BlockRoundedIcon from "@mui/icons-material/BlockRounded";
import CheckCircleRoundedIcon from "@mui/icons-material/CheckCircleRounded";
import DeleteRoundedIcon from "@mui/icons-material/DeleteRounded";
import PageHeader from "@/components/PageHeader";
import { EmptyView, ErrorView, Loading } from "@/components/Feedback";
import ConfirmDialog from "@/components/ConfirmDialog";
import { useToast } from "@/components/Toast";
import { useBlockUser, useCustomers, useDeleteUser } from "@/hooks/queries";
import type { AppUser } from "@/api/types";
import { apiErrorMessage } from "@/api/client";
import { fmtDate, initials } from "@/utils/format";

export default function CustomersPage() {
  const { data, isLoading, isError, error, refetch } = useCustomers();
  const block = useBlockUser();
  const del = useDeleteUser();
  const { notify } = useToast();

  const [confirm, setConfirm] = useState<{
    user: AppUser;
    action: "block" | "unblock" | "delete";
  } | null>(null);

  const run = async () => {
    if (!confirm) return;
    const { user, action } = confirm;
    try {
      if (action === "delete") {
        await del.mutateAsync(user.id);
        notify(`${user.name} deleted`, "info");
      } else {
        await block.mutateAsync({ userId: user.id, suspend: action === "block" });
        notify(action === "block" ? `${user.name} blocked` : `${user.name} unblocked`);
      }
      setConfirm(null);
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  const copy = () => {
    if (!confirm) return { title: "", message: "", label: "", color: "primary" as const };
    const n = confirm.user.name;
    if (confirm.action === "delete")
      return {
        title: "Delete customer?",
        message: `This permanently removes ${n} and their bookings. This cannot be undone.`,
        label: "Delete",
        color: "error" as const,
      };
    if (confirm.action === "block")
      return {
        title: "Block customer?",
        message: `${n} will not be able to log in or book services.`,
        label: "Block",
        color: "warning" as const,
      };
    return {
      title: "Unblock customer?",
      message: `${n} will regain access to the app.`,
      label: "Unblock",
      color: "success" as const,
    };
  };

  const c = copy();

  return (
    <>
      <PageHeader title="Customers" subtitle="Manage customer accounts" />

      <Card>
        {isLoading ? (
          <Loading />
        ) : isError ? (
          <Box sx={{ p: 2 }}>
            <ErrorView message={apiErrorMessage(error)} onRetry={() => refetch()} />
          </Box>
        ) : !data || data.length === 0 ? (
          <EmptyView title="No customers yet" />
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Customer</TableCell>
                  <TableCell>Phone</TableCell>
                  <TableCell>Joined</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {data.map((u) => (
                  <TableRow key={u.id} hover>
                    <TableCell>
                      <Stack direction="row" spacing={1.5} alignItems="center">
                        <Avatar sx={{ bgcolor: "#0EA5E9", width: 38, height: 38, fontSize: 14 }}>
                          {initials(u.name)}
                        </Avatar>
                        <Typography fontWeight={600} fontSize={14}>
                          {u.name}
                        </Typography>
                      </Stack>
                    </TableCell>
                    <TableCell>{u.phone ?? "—"}</TableCell>
                    <TableCell>{fmtDate(u.created_at)}</TableCell>
                    <TableCell>
                      {u.is_active ? (
                        <Chip size="small" color="success" variant="outlined" label="Active" />
                      ) : (
                        <Chip size="small" color="error" label="Blocked" />
                      )}
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={1} justifyContent="flex-end">
                        <Button
                          size="small"
                          variant="outlined"
                          color={u.is_active ? "warning" : "success"}
                          startIcon={
                            u.is_active ? <BlockRoundedIcon /> : <CheckCircleRoundedIcon />
                          }
                          onClick={() =>
                            setConfirm({ user: u, action: u.is_active ? "block" : "unblock" })
                          }
                        >
                          {u.is_active ? "Block" : "Unblock"}
                        </Button>
                        <Button
                          size="small"
                          variant="outlined"
                          color="error"
                          startIcon={<DeleteRoundedIcon />}
                          onClick={() => setConfirm({ user: u, action: "delete" })}
                        >
                          Delete
                        </Button>
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
        title={c.title}
        message={c.message}
        confirmLabel={c.label}
        confirmColor={c.color}
        loading={block.isPending || del.isPending}
        onConfirm={run}
        onClose={() => setConfirm(null)}
      />
    </>
  );
}
