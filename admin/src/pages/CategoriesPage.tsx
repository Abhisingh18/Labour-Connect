import { useState } from "react";
import {
  Box,
  Button,
  Card,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Grid,
  IconButton,
  Stack,
  Switch,
  TextField,
  Typography,
} from "@mui/material";
import AddRoundedIcon from "@mui/icons-material/AddRounded";
import EditRoundedIcon from "@mui/icons-material/EditRounded";
import DeleteRoundedIcon from "@mui/icons-material/DeleteRounded";
import HomeRepairServiceRoundedIcon from "@mui/icons-material/HomeRepairServiceRounded";
import PageHeader from "@/components/PageHeader";
import { EmptyView, ErrorView, Loading } from "@/components/Feedback";
import ConfirmDialog from "@/components/ConfirmDialog";
import { useToast } from "@/components/Toast";
import {
  useCategories,
  useCreateCategory,
  useDeleteCategory,
  useUpdateCategory,
} from "@/hooks/queries";
import type { Category } from "@/api/types";
import { apiErrorMessage } from "@/api/client";

const ICON_OPTIONS = [
  "plumbing",
  "electrical",
  "carpenter",
  "painter",
  "mason",
  "labour",
  "ac",
  "appliance",
  "cleaning",
  "driver",
  "movers",
];

export default function CategoriesPage() {
  const { data, isLoading, isError, error, refetch } = useCategories();
  const create = useCreateCategory();
  const update = useUpdateCategory();
  const del = useDeleteCategory();
  const { notify } = useToast();

  const [editing, setEditing] = useState<Category | null>(null);
  const [creating, setCreating] = useState(false);
  const [toDelete, setToDelete] = useState<Category | null>(null);

  // form state
  const [name, setName] = useState("");
  const [icon, setIcon] = useState("");
  const [active, setActive] = useState(true);

  const openCreate = () => {
    setName("");
    setIcon("");
    setActive(true);
    setCreating(true);
  };

  const openEdit = (c: Category) => {
    setName(c.name);
    setIcon(c.icon ?? "");
    setActive(c.is_active);
    setEditing(c);
  };

  const closeForm = () => {
    setCreating(false);
    setEditing(null);
  };

  const save = async () => {
    if (!name.trim()) {
      notify("Name is required", "error");
      return;
    }
    try {
      if (editing) {
        await update.mutateAsync({
          id: editing.id,
          data: { name: name.trim(), icon: icon.trim(), is_active: active },
        });
        notify("Category updated");
      } else {
        await create.mutateAsync({ name: name.trim(), icon: icon.trim(), is_active: active });
        notify("Category added");
      }
      closeForm();
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  const remove = async () => {
    if (!toDelete) return;
    try {
      await del.mutateAsync(toDelete.id);
      notify("Category deleted", "info");
      setToDelete(null);
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  return (
    <>
      <PageHeader
        title="Categories"
        subtitle="Manage the service categories shown in the app"
        action={
          <Button variant="contained" startIcon={<AddRoundedIcon />} onClick={openCreate}>
            Add category
          </Button>
        }
      />

      {isLoading ? (
        <Loading />
      ) : isError ? (
        <ErrorView message={apiErrorMessage(error)} onRetry={() => refetch()} />
      ) : !data || data.length === 0 ? (
        <Card>
          <EmptyView title="No categories" subtitle="Add your first service category." />
        </Card>
      ) : (
        <Grid container spacing={2}>
          {data.map((c) => (
            <Grid item xs={12} sm={6} md={4} lg={3} key={c.id}>
              <Card sx={{ p: 2 }}>
                <Stack direction="row" justifyContent="space-between" alignItems="flex-start">
                  <Box
                    sx={{
                      width: 48,
                      height: 48,
                      borderRadius: 2.5,
                      bgcolor: "primary.light",
                      color: "primary.main",
                      display: "grid",
                      placeItems: "center",
                    }}
                  >
                    <HomeRepairServiceRoundedIcon />
                  </Box>
                  <Stack direction="row">
                    <IconButton size="small" onClick={() => openEdit(c)}>
                      <EditRoundedIcon fontSize="small" />
                    </IconButton>
                    <IconButton size="small" color="error" onClick={() => setToDelete(c)}>
                      <DeleteRoundedIcon fontSize="small" />
                    </IconButton>
                  </Stack>
                </Stack>
                <Typography variant="h6" sx={{ mt: 1.5 }}>
                  {c.name}
                </Typography>
                <Stack direction="row" spacing={1} alignItems="center" sx={{ mt: 0.5 }}>
                  <Typography variant="caption" color="text.secondary">
                    {c.icon || "no icon"}
                  </Typography>
                  <Chip
                    size="small"
                    label={c.is_active ? "Active" : "Hidden"}
                    color={c.is_active ? "success" : "default"}
                    variant="outlined"
                  />
                </Stack>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      <Dialog open={creating || Boolean(editing)} onClose={closeForm} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontFamily: "Plus Jakarta Sans", fontWeight: 700 }}>
          {editing ? "Edit category" : "Add category"}
        </DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Name"
              fullWidth
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoFocus
            />
            <TextField
              label="Icon key"
              fullWidth
              select
              SelectProps={{ native: true }}
              value={icon}
              onChange={(e) => setIcon(e.target.value)}
              helperText="Matches an icon in the mobile app"
            >
              <option value="">(none)</option>
              {ICON_OPTIONS.map((o) => (
                <option key={o} value={o}>
                  {o}
                </option>
              ))}
            </TextField>
            <FormControlLabel
              control={
                <Switch checked={active} onChange={(e) => setActive(e.target.checked)} />
              }
              label="Active (visible to customers)"
            />
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={closeForm} color="inherit">
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={save}
            disabled={create.isPending || update.isPending}
          >
            {editing ? "Save" : "Add"}
          </Button>
        </DialogActions>
      </Dialog>

      <ConfirmDialog
        open={Boolean(toDelete)}
        title="Delete category?"
        message={`"${toDelete?.name}" will be removed. Workers in this category will be uncategorised.`}
        confirmLabel="Delete"
        confirmColor="error"
        loading={del.isPending}
        onConfirm={remove}
        onClose={() => setToDelete(null)}
      />
    </>
  );
}
