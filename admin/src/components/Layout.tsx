import { useState } from "react";
import {
  AppBar,
  Avatar,
  Box,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Stack,
  Toolbar,
  Typography,
  useMediaQuery,
} from "@mui/material";
import { useTheme } from "@mui/material/styles";
import MenuRoundedIcon from "@mui/icons-material/MenuRounded";
import DashboardRoundedIcon from "@mui/icons-material/DashboardRounded";
import EngineeringRoundedIcon from "@mui/icons-material/EngineeringRounded";
import PeopleRoundedIcon from "@mui/icons-material/PeopleRounded";
import CategoryRoundedIcon from "@mui/icons-material/CategoryRounded";
import EventNoteRoundedIcon from "@mui/icons-material/EventNoteRounded";
import StarRoundedIcon from "@mui/icons-material/StarRounded";
import LogoutRoundedIcon from "@mui/icons-material/LogoutRounded";
import HandymanRoundedIcon from "@mui/icons-material/HandymanRounded";
import { NavLink, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "@/auth/AuthContext";
import { initials } from "@/utils/format";

const DRAWER_WIDTH = 256;

const NAV = [
  { to: "/", label: "Dashboard", icon: <DashboardRoundedIcon /> },
  { to: "/workers", label: "Workers", icon: <EngineeringRoundedIcon /> },
  { to: "/customers", label: "Customers", icon: <PeopleRoundedIcon /> },
  { to: "/categories", label: "Categories", icon: <CategoryRoundedIcon /> },
  { to: "/bookings", label: "Bookings", icon: <EventNoteRoundedIcon /> },
  { to: "/reviews", label: "Reviews", icon: <StarRoundedIcon /> },
];

export default function Layout() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchor, setAnchor] = useState<null | HTMLElement>(null);
  const { user, logout } = useAuth();
  const location = useLocation();

  const title =
    NAV.find((n) => n.to === location.pathname)?.label ?? "Admin";

  const drawer = (
    <Box sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
      <Stack direction="row" alignItems="center" spacing={1.5} sx={{ px: 3, py: 2.5 }}>
        <Box
          sx={{
            width: 40,
            height: 40,
            borderRadius: 2.5,
            background: "linear-gradient(135deg,#6366F1,#4F46E5)",
            display: "grid",
            placeItems: "center",
          }}
        >
          <HandymanRoundedIcon sx={{ color: "#fff", fontSize: 22 }} />
        </Box>
        <Box>
          <Typography sx={{ fontFamily: "Plus Jakarta Sans", fontWeight: 800, lineHeight: 1.1 }}>
            Labour Connect
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Admin Panel
          </Typography>
        </Box>
      </Stack>
      <Divider />
      <List sx={{ px: 1.5, py: 2, flex: 1 }}>
        {NAV.map((item) => (
          <ListItemButton
            key={item.to}
            component={NavLink}
            to={item.to}
            end={item.to === "/"}
            onClick={() => isMobile && setMobileOpen(false)}
            sx={{
              borderRadius: 2.5,
              mb: 0.5,
              color: "text.secondary",
              "&.active": {
                bgcolor: "primary.light",
                color: "primary.main",
                fontWeight: 700,
                "& .MuiListItemIcon-root": { color: "primary.main" },
              },
            }}
          >
            <ListItemIcon sx={{ minWidth: 40, color: "inherit" }}>
              {item.icon}
            </ListItemIcon>
            <ListItemText
              primary={item.label}
              primaryTypographyProps={{ fontWeight: 600, fontSize: 14 }}
            />
          </ListItemButton>
        ))}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: "flex", minHeight: "100vh", bgcolor: "background.default" }}>
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          width: { md: `calc(100% - ${DRAWER_WIDTH}px)` },
          ml: { md: `${DRAWER_WIDTH}px` },
          bgcolor: "background.paper",
          color: "text.primary",
          borderBottom: "1px solid",
          borderColor: "divider",
        }}
      >
        <Toolbar>
          <IconButton
            edge="start"
            onClick={() => setMobileOpen(true)}
            sx={{ mr: 2, display: { md: "none" } }}
          >
            <MenuRoundedIcon />
          </IconButton>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            {title}
          </Typography>
          <IconButton onClick={(e) => setAnchor(e.currentTarget)}>
            <Avatar sx={{ width: 36, height: 36, bgcolor: "primary.main", fontSize: 15 }}>
              {initials(user?.name)}
            </Avatar>
          </IconButton>
          <Menu
            anchorEl={anchor}
            open={Boolean(anchor)}
            onClose={() => setAnchor(null)}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
            transformOrigin={{ vertical: "top", horizontal: "right" }}
          >
            <Box sx={{ px: 2, py: 1 }}>
              <Typography fontWeight={700}>{user?.name}</Typography>
              <Typography variant="caption" color="text.secondary">
                {user?.email}
              </Typography>
            </Box>
            <Divider />
            <MenuItem onClick={logout}>
              <ListItemIcon>
                <LogoutRoundedIcon fontSize="small" />
              </ListItemIcon>
              Log out
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Box component="nav" sx={{ width: { md: DRAWER_WIDTH }, flexShrink: { md: 0 } }}>
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={() => setMobileOpen(false)}
          ModalProps={{ keepMounted: true }}
          sx={{
            display: { xs: "block", md: "none" },
            "& .MuiDrawer-paper": { width: DRAWER_WIDTH, boxSizing: "border-box" },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          open
          sx={{
            display: { xs: "none", md: "block" },
            "& .MuiDrawer-paper": {
              width: DRAWER_WIDTH,
              boxSizing: "border-box",
              borderRight: "1px solid",
              borderColor: "divider",
            },
          }}
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { md: `calc(100% - ${DRAWER_WIDTH}px)` },
          p: { xs: 2, md: 4 },
        }}
      >
        <Toolbar />
        <Outlet />
      </Box>
    </Box>
  );
}
