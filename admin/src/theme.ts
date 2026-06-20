import { createTheme } from "@mui/material/styles";

const theme = createTheme({
  palette: {
    mode: "light",
    primary: { main: "#4F46E5", dark: "#4338CA", light: "#EEF2FF" },
    secondary: { main: "#F59E0B" },
    success: { main: "#16A34A" },
    warning: { main: "#F59E0B" },
    error: { main: "#DC2626" },
    info: { main: "#2563EB" },
    background: { default: "#F6F7FB", paper: "#FFFFFF" },
    text: { primary: "#1E293B", secondary: "#64748B" },
    divider: "#E2E8F0",
  },
  typography: {
    fontFamily: "Inter, system-ui, sans-serif",
    h1: { fontFamily: "Plus Jakarta Sans", fontWeight: 800 },
    h2: { fontFamily: "Plus Jakarta Sans", fontWeight: 700 },
    h3: { fontFamily: "Plus Jakarta Sans", fontWeight: 700 },
    h4: { fontFamily: "Plus Jakarta Sans", fontWeight: 700, fontSize: "1.5rem" },
    h5: { fontFamily: "Plus Jakarta Sans", fontWeight: 700, fontSize: "1.2rem" },
    h6: { fontFamily: "Plus Jakarta Sans", fontWeight: 700, fontSize: "1.05rem" },
    button: { textTransform: "none", fontWeight: 600 },
  },
  shape: { borderRadius: 14 },
  components: {
    MuiCard: {
      defaultProps: { elevation: 0 },
      styleOverrides: {
        root: { border: "1px solid #E2E8F0", borderRadius: 18 },
      },
    },
    MuiPaper: {
      styleOverrides: { rounded: { borderRadius: 18 } },
    },
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: { root: { borderRadius: 12, paddingInline: 18 } },
    },
    MuiTextField: { defaultProps: { size: "small" } },
    MuiChip: { styleOverrides: { root: { fontWeight: 600 } } },
    MuiTableCell: {
      styleOverrides: {
        head: { fontWeight: 700, color: "#64748B", background: "#F8FAFC" },
      },
    },
  },
});

export default theme;
