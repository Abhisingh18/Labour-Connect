import {
  Box,
  Card,
  CardContent,
  Grid,
  Stack,
  Typography,
} from "@mui/material";
import PeopleRoundedIcon from "@mui/icons-material/PeopleRounded";
import EngineeringRoundedIcon from "@mui/icons-material/EngineeringRounded";
import EventNoteRoundedIcon from "@mui/icons-material/EventNoteRounded";
import PaymentsRoundedIcon from "@mui/icons-material/PaymentsRounded";
import VerifiedRoundedIcon from "@mui/icons-material/VerifiedRounded";
import HourglassTopRoundedIcon from "@mui/icons-material/HourglassTopRounded";
import {
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  Bar,
  BarChart,
  CartesianGrid,
  XAxis,
  YAxis,
} from "recharts";
import PageHeader from "@/components/PageHeader";
import StatCard from "@/components/StatCard";
import { ErrorView, Loading } from "@/components/Feedback";
import { useDashboard } from "@/hooks/queries";
import { apiErrorMessage } from "@/api/client";
import { inr } from "@/utils/format";

export default function DashboardPage() {
  const { data, isLoading, isError, error, refetch } = useDashboard();

  if (isLoading) return <Loading height={400} />;
  if (isError || !data)
    return <ErrorView message={apiErrorMessage(error)} onRetry={() => refetch()} />;

  const bookingData = [
    { name: "Pending", value: data.pending_bookings, color: "#F59E0B" },
    { name: "Completed", value: data.completed_bookings, color: "#16A34A" },
    {
      name: "Other",
      value: Math.max(
        data.total_bookings - data.pending_bookings - data.completed_bookings,
        0,
      ),
      color: "#94A3B8",
    },
  ].filter((d) => d.value > 0);

  const userData = [
    { name: "Customers", count: data.total_customers },
    { name: "Workers", count: data.total_workers },
    { name: "Verified", count: data.verified_workers },
    { name: "Pending KYC", count: data.pending_kyc },
  ];

  return (
    <>
      <PageHeader
        title="Dashboard"
        subtitle="Overview of users, workers, bookings and revenue"
      />

      <Grid container spacing={2.5}>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Total customers"
            value={data.total_customers}
            icon={<PeopleRoundedIcon />}
            color="#4F46E5"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Total workers"
            value={data.total_workers}
            icon={<EngineeringRoundedIcon />}
            color="#0EA5E9"
            hint={`${data.verified_workers} verified`}
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Total bookings"
            value={data.total_bookings}
            icon={<EventNoteRoundedIcon />}
            color="#F59E0B"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Revenue"
            value={inr(data.total_revenue)}
            icon={<PaymentsRoundedIcon />}
            color="#16A34A"
            hint="From completed jobs"
          />
        </Grid>

        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Verified workers"
            value={data.verified_workers}
            icon={<VerifiedRoundedIcon />}
            color="#16A34A"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Pending KYC"
            value={data.pending_kyc}
            icon={<HourglassTopRoundedIcon />}
            color="#DC2626"
            hint="Awaiting review"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Pending bookings"
            value={data.pending_bookings}
            icon={<HourglassTopRoundedIcon />}
            color="#F59E0B"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            label="Completed bookings"
            value={data.completed_bookings}
            icon={<EventNoteRoundedIcon />}
            color="#16A34A"
          />
        </Grid>
      </Grid>

      <Grid container spacing={2.5} sx={{ mt: 0.5 }}>
        <Grid item xs={12} md={7}>
          <Card sx={{ height: "100%" }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Users & workers
              </Typography>
              <Box sx={{ height: 320 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={userData} margin={{ top: 16, right: 8, bottom: 0, left: -16 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                    <XAxis dataKey="name" tick={{ fontSize: 12, fill: "#64748B" }} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 12, fill: "#64748B" }} />
                    <Tooltip />
                    <Bar dataKey="count" fill="#4F46E5" radius={[6, 6, 0, 0]} barSize={48} />
                  </BarChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={5}>
          <Card sx={{ height: "100%" }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Bookings breakdown
              </Typography>
              {bookingData.length === 0 ? (
                <Stack sx={{ height: 320 }} alignItems="center" justifyContent="center">
                  <Typography color="text.secondary">No bookings yet</Typography>
                </Stack>
              ) : (
                <Box sx={{ height: 320 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={bookingData}
                        dataKey="value"
                        nameKey="name"
                        innerRadius={70}
                        outerRadius={110}
                        paddingAngle={3}
                      >
                        {bookingData.map((d) => (
                          <Cell key={d.name} fill={d.color} />
                        ))}
                      </Pie>
                      <Tooltip />
                      <Legend />
                    </PieChart>
                  </ResponsiveContainer>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </>
  );
}
