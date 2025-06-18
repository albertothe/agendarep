"use client"

import {
    Box,
    List,
    ListItem,
    ListItemButton,
    ListItemIcon,
    ListItemText,
    Divider,
    Typography,
    Avatar,
    Menu,
    MenuItem,
    useMediaQuery,
    useTheme,
} from "@mui/material"
import {
    GridView,
    CalendarMonth,
    Person,
    Lightbulb,
    Settings,
    Logout,
    KeyboardArrowDown,
    Link as LinkIcon,
} from "@mui/icons-material"
import { useNavigate, useLocation } from "react-router-dom"
import { useEffect, useState, useCallback, useContext } from "react"
import { jwtDecode } from "jwt-decode"
import { AuthContext } from "../context/AuthContext"

// Interfaces
interface Usuario {
    nome: string
    perfil: string
    email?: string
    id?: string
}

interface TokenPayload extends Usuario {
    exp: number
}

interface SidebarProps {
    onClose?: () => void // Para fechar drawer mobile
}

const Sidebar = ({ onClose }: SidebarProps) => {
    const navigate = useNavigate()
    const location = useLocation()
    const theme = useTheme()
    const isMobile = useMediaQuery(theme.breakpoints.down("md"))
    const [usuario, setUsuario] = useState<Usuario | null>(null)
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)

    const menu = [
        {
            texto: "Painel Principal",
            icone: <GridView />,
            rota: "/dashboard",
        },
        {
            texto: "Agenda Semanal",
            icone: <CalendarMonth />,
            rota: "/agenda",
        },
        {
            texto: "Clientes",
            icone: <Person />,
            rota: "/clientes",
        },
        {
            texto: "Sugestões de Visita",
            icone: <Lightbulb />,
            rota: "/sugestoes",
        },
    ]

    const isTokenValid = useCallback((token: string): boolean => {
        try {
            const decoded = jwtDecode<TokenPayload>(token)
            const currentTime = Date.now() / 1000
            return decoded.exp > currentTime
        } catch {
            return false
        }
    }, [])

    useEffect(() => {
        const token = localStorage.getItem("token")

        if (token && isTokenValid(token)) {
            try {
                const decoded = jwtDecode<TokenPayload>(token)
                setUsuario({
                    nome: decoded.nome,
                    perfil: decoded.perfil,
                    email: decoded.email,
                    id: decoded.id,
                })
            } catch (error) {
                console.error("Erro ao decodificar token:", error)
                handleLogout()
            }
        } else {
            handleLogout()
        }
    }, [isTokenValid])

    const { setToken } = useContext(AuthContext)

    const handleLogout = useCallback(() => {
        setToken(null)
        localStorage.removeItem("usuario")
        setUsuario(null)
        navigate("/login", { replace: true })
    }, [navigate, setToken])

    const handleNavigation = (rota: string) => {
        navigate(rota)
        // Fecha o drawer mobile após navegação
        if (isMobile && onClose) {
            onClose()
        }
    }

    const handleCloseMenu = () => {
        setAnchorEl(null)
    }

    const handleSettings = () => {
        handleCloseMenu()
        navigate("/configuracoes")
        if (isMobile && onClose) {
            onClose()
        }
    }

    const handleMenuLogout = () => {
        handleCloseMenu()
        handleLogout()
    }

    return (
        <Box
            sx={{
                width: 250,
                bgcolor: "#e8f0fe",
                height: "100vh",
                display: "flex",
                flexDirection: "column",
                justifyContent: "space-between",
                borderRight: "1px solid #d1d9e8",
            }}
        >
            {/* Header */}
            <Box>
                <Box sx={{ p: 3, display: "flex", alignItems: "center", gap: 1.5 }}>
                    <LinkIcon sx={{ color: "#4285f4", fontSize: 24 }} />
                    <Typography
                        variant="h6"
                        sx={{
                            fontWeight: 600,
                            color: "#4285f4",
                            fontSize: "1.1rem",
                        }}
                    >
                        AgendaRep
                    </Typography>
                </Box>

                <Divider sx={{ borderColor: "#d1d9e8" }} />

                {/* Menu de Navegação */}
                <List sx={{ px: 2, py: 1 }}>
                    {menu.map((item) => {
                        const isSelected = location.pathname === item.rota
                        return (
                            <ListItem key={item.texto} disablePadding sx={{ mb: 0.5 }}>
                                <ListItemButton
                                    selected={isSelected}
                                    onClick={() => handleNavigation(item.rota)}
                                    sx={{
                                        borderRadius: 2,
                                        py: 1.5,
                                        px: 2,
                                        "&.Mui-selected": {
                                            bgcolor: "#4285f4",
                                            color: "white",
                                            "&:hover": {
                                                bgcolor: "#3367d6",
                                            },
                                            "& .MuiListItemIcon-root": {
                                                color: "white",
                                            },
                                        },
                                        "&:hover": {
                                            bgcolor: isSelected ? "#3367d6" : "#d2e3fc",
                                        },
                                    }}
                                >
                                    <ListItemIcon
                                        sx={{
                                            minWidth: 36,
                                            color: isSelected ? "white" : "#5f6368",
                                        }}
                                    >
                                        {item.icone}
                                    </ListItemIcon>
                                    <ListItemText
                                        primary={item.texto}
                                        primaryTypographyProps={{
                                            fontSize: "0.9rem",
                                            fontWeight: isSelected ? 600 : 500,
                                            color: isSelected ? "white" : "#3c4043",
                                        }}
                                    />
                                </ListItemButton>
                            </ListItem>
                        )
                    })}
                </List>
            </Box>

            {/* Footer com informações do usuário */}
            <Box sx={{ p: 2 }}>
                <Divider sx={{ mb: 2, borderColor: "#d1d9e8" }} />
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        bgcolor: "rgba(255, 255, 255, 0.7)",
                        borderRadius: 2,
                        p: 1.5,
                        cursor: "pointer",
                        "&:hover": {
                            bgcolor: "rgba(255, 255, 255, 0.9)",
                        },
                    }}
                    onClick={(e) => setAnchorEl(e.currentTarget)}
                >
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, flex: 1 }}>
                        <Avatar
                            sx={{
                                width: 32,
                                height: 32,
                                bgcolor: "#4285f4",
                                fontSize: "0.9rem",
                                fontWeight: 600,
                            }}
                        >
                            {usuario?.nome?.[0]?.toUpperCase() || "U"}
                        </Avatar>
                        <Box sx={{ flex: 1, minWidth: 0 }}>
                            <Typography
                                variant="body2"
                                sx={{
                                    fontWeight: 600,
                                    color: "#3c4043",
                                    fontSize: "0.85rem",
                                    overflow: "hidden",
                                    textOverflow: "ellipsis",
                                    whiteSpace: "nowrap",
                                }}
                            >
                                {usuario?.nome || "Carregando..."}
                            </Typography>
                            <Typography
                                variant="caption"
                                sx={{
                                    color: "#5f6368",
                                    fontSize: "0.75rem",
                                    textTransform: "capitalize",
                                }}
                            >
                                {usuario?.perfil || "representante"}
                            </Typography>
                        </Box>
                    </Box>
                    <KeyboardArrowDown sx={{ color: "#5f6368", fontSize: "1.2rem" }} />
                </Box>

                {/* Menu do usuário */}
                <Menu
                    anchorEl={anchorEl}
                    open={Boolean(anchorEl)}
                    onClose={handleCloseMenu}
                    PaperProps={{
                        sx: {
                            mt: 1,
                            minWidth: 180,
                            boxShadow: "0 4px 12px rgba(0,0,0,0.15)",
                            borderRadius: 2,
                        },
                    }}
                >
                    <MenuItem onClick={handleSettings} sx={{ py: 1.5 }}>
                        <ListItemIcon>
                            <Settings fontSize="small" sx={{ color: "#5f6368" }} />
                        </ListItemIcon>
                        <ListItemText>
                            <Typography variant="body2">Configurações</Typography>
                        </ListItemText>
                    </MenuItem>
                    <Divider />
                    <MenuItem onClick={handleMenuLogout} sx={{ py: 1.5, color: "#d93025" }}>
                        <ListItemIcon>
                            <Logout fontSize="small" sx={{ color: "#d93025" }} />
                        </ListItemIcon>
                        <ListItemText>
                            <Typography variant="body2" color="#d93025">
                                Sair
                            </Typography>
                        </ListItemText>
                    </MenuItem>
                </Menu>
            </Box>
        </Box>
    )
}

export default Sidebar
