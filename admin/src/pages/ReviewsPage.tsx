import {
  Box,
  Button,
  Card,
  Chip,
  Rating,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
} from "@mui/material";
import VisibilityOffRoundedIcon from "@mui/icons-material/VisibilityOffRounded";
import VisibilityRoundedIcon from "@mui/icons-material/VisibilityRounded";
import PageHeader from "@/components/PageHeader";
import { EmptyView, ErrorView, Loading } from "@/components/Feedback";
import { useToast } from "@/components/Toast";
import { useHideReview, useReviews } from "@/hooks/queries";
import { apiErrorMessage } from "@/api/client";
import { fmtDate } from "@/utils/format";

export default function ReviewsPage() {
  const { data, isLoading, isError, error, refetch } = useReviews();
  const hide = useHideReview();
  const { notify } = useToast();

  const toggle = async (id: number, suspend: boolean) => {
    try {
      await hide.mutateAsync({ id, suspend });
      notify(suspend ? "Review hidden" : "Review restored", suspend ? "info" : "success");
    } catch (e) {
      notify(apiErrorMessage(e), "error");
    }
  };

  return (
    <>
      <PageHeader
        title="Reviews"
        subtitle="Moderate reviews — hide inappropriate ones (recomputes worker ratings)"
      />

      <Card>
        {isLoading ? (
          <Loading />
        ) : isError ? (
          <Box sx={{ p: 2 }}>
            <ErrorView message={apiErrorMessage(error)} onRetry={() => refetch()} />
          </Box>
        ) : !data || data.length === 0 ? (
          <EmptyView title="No reviews yet" />
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Booking</TableCell>
                  <TableCell>Rating</TableCell>
                  <TableCell>Comment</TableCell>
                  <TableCell>Date</TableCell>
                  <TableCell>Visibility</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {data.map((r) => (
                  <TableRow key={r.id} hover>
                    <TableCell>
                      <Typography fontWeight={700} fontSize={13}>
                        #{r.booking_id}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Rating value={r.rating} readOnly size="small" />
                    </TableCell>
                    <TableCell sx={{ maxWidth: 360 }}>
                      <Typography fontSize={13} color={r.comment ? "text.primary" : "text.disabled"}>
                        {r.comment || "No comment"}
                      </Typography>
                    </TableCell>
                    <TableCell>{fmtDate(r.created_at)}</TableCell>
                    <TableCell>
                      {r.is_hidden ? (
                        <Chip size="small" color="error" label="Hidden" />
                      ) : (
                        <Chip size="small" color="success" variant="outlined" label="Visible" />
                      )}
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" justifyContent="flex-end">
                        {r.is_hidden ? (
                          <Button
                            size="small"
                            variant="outlined"
                            color="success"
                            startIcon={<VisibilityRoundedIcon />}
                            onClick={() => toggle(r.id, false)}
                          >
                            Restore
                          </Button>
                        ) : (
                          <Button
                            size="small"
                            variant="outlined"
                            color="error"
                            startIcon={<VisibilityOffRoundedIcon />}
                            onClick={() => toggle(r.id, true)}
                          >
                            Hide
                          </Button>
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
    </>
  );
}
