import { Route, Routes } from "react-router-dom";
import Layout from "@/components/Layout";
import ProtectedRoute from "@/auth/ProtectedRoute";
import LoginPage from "@/pages/LoginPage";
import DashboardPage from "@/pages/DashboardPage";
import WorkersPage from "@/pages/WorkersPage";
import CustomersPage from "@/pages/CustomersPage";
import CategoriesPage from "@/pages/CategoriesPage";
import BookingsPage from "@/pages/BookingsPage";
import ReviewsPage from "@/pages/ReviewsPage";

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<Layout />}>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/workers" element={<WorkersPage />} />
          <Route path="/customers" element={<CustomersPage />} />
          <Route path="/categories" element={<CategoriesPage />} />
          <Route path="/bookings" element={<BookingsPage />} />
          <Route path="/reviews" element={<ReviewsPage />} />
        </Route>
      </Route>
    </Routes>
  );
}
