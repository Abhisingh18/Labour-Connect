import { Alert, Box, Button, CircularProgress, Stack, Typography } from "@mui/material";
import InboxRoundedIcon from "@mui/icons-material/InboxRounded";
import type { ReactNode } from "react";

export function Loading({ height = 240 }: { height?: number }) {
  return (
    <Box sx={{ height, display: "grid", placeItems: "center" }}>
      <CircularProgress />
    </Box>
  );
}

export function ErrorView({
  message,
  onRetry,
}: {
  message: string;
  onRetry?: () => void;
}) {
  return (
    <Alert
      severity="error"
      action={
        onRetry ? (
          <Button color="inherit" size="small" onClick={onRetry}>
            Retry
          </Button>
        ) : undefined
      }
    >
      {message}
    </Alert>
  );
}

export function EmptyView({
  title,
  subtitle,
  icon,
}: {
  title: string;
  subtitle?: string;
  icon?: ReactNode;
}) {
  return (
    <Stack alignItems="center" justifyContent="center" spacing={1} sx={{ py: 8 }}>
      <Box sx={{ color: "text.disabled" }}>
        {icon ?? <InboxRoundedIcon sx={{ fontSize: 56 }} />}
      </Box>
      <Typography variant="h6">{title}</Typography>
      {subtitle && (
        <Typography variant="body2" color="text.secondary">
          {subtitle}
        </Typography>
      )}
    </Stack>
  );
}
