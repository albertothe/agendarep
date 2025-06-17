import { Box, Container } from "@mui/material";
import Sidebar from "../components/Sidebar";
import type { ReactNode } from "react";

interface LayoutProps {
    children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
    return (
        <Box display="flex" minHeight="100vh">
            <Sidebar />
            <Box component="main" flexGrow={1} p={3} bgcolor="#f5f6fa">
                <Container maxWidth="lg">{children}</Container>
            </Box>
        </Box>
    );
}