"use client"

import { Box, Container, useMediaQuery, useTheme, Drawer, IconButton } from "@mui/material"
import { Menu as MenuIcon } from "@mui/icons-material"
import Sidebar from "./Sidebar"
import { type ReactNode, useState } from "react"

interface LayoutProps {
    children: ReactNode
    title?: string
    maxWidth?: "xs" | "sm" | "md" | "lg" | "xl" | false
    disablePadding?: boolean
}

const SIDEBAR_WIDTH = 250

export default function Layout({ children, title, maxWidth = false, disablePadding = false }: LayoutProps) {
    const theme = useTheme()
    const isMobile = useMediaQuery(theme.breakpoints.down("md"))
    const [mobileOpen, setMobileOpen] = useState(false)

    const handleDrawerToggle = () => {
        setMobileOpen(!mobileOpen)
    }

    return (
        <Box display="flex" minHeight="100vh">
            {/* Mobile Menu Button */}
            {isMobile && (
                <IconButton
                    color="inherit"
                    aria-label="open drawer"
                    edge="start"
                    onClick={handleDrawerToggle}
                    sx={{
                        position: "fixed",
                        top: 16,
                        left: 16,
                        zIndex: theme.zIndex.drawer + 1,
                        bgcolor: "white",
                        boxShadow: 2,
                        "&:hover": {
                            bgcolor: "grey.100",
                        },
                    }}
                >
                    <MenuIcon />
                </IconButton>
            )}

            {/* Desktop Sidebar - Fixo */}
            {!isMobile && (
                <Box
                    component="nav"
                    sx={{
                        width: SIDEBAR_WIDTH,
                        flexShrink: 0,
                        position: "fixed",
                        height: "100vh",
                        zIndex: theme.zIndex.drawer,
                    }}
                >
                    <Sidebar />
                </Box>
            )}

            {/* Mobile Sidebar */}
            {isMobile && (
                <Drawer
                    variant="temporary"
                    open={mobileOpen}
                    onClose={handleDrawerToggle}
                    ModalProps={{
                        keepMounted: true, // Better open performance on mobile
                    }}
                    sx={{
                        "& .MuiDrawer-paper": {
                            boxSizing: "border-box",
                            width: SIDEBAR_WIDTH,
                        },
                    }}
                >
                    <Sidebar onClose={handleDrawerToggle} />
                </Drawer>
            )}

            {/* Main Content */}
            <Box
                component="main"
                sx={{
                    flexGrow: 1,
                    bgcolor: "#f5f6fa",
                    minHeight: "100vh",
                    ml: isMobile ? 0 : `${SIDEBAR_WIDTH}px`, // Margem para compensar sidebar fixo
                    pt: isMobile ? 8 : 0, // Espaço para o botão mobile
                }}
            >
                <Container
                    maxWidth={maxWidth}
                    sx={{
                        py: disablePadding ? 0 : 0, // Removendo padding do container
                        px: disablePadding ? 0 : 0, // Removendo padding do container
                        height: "100%",
                    }}
                >
                    {title && (
                        <Box mb={3} pt={3} px={3}>
                            <h1 style={{ margin: 0, color: "#2c3e50", fontSize: "1.8rem" }}>{title}</h1>
                        </Box>
                    )}
                    {children}
                </Container>
            </Box>
        </Box>
    )
}
