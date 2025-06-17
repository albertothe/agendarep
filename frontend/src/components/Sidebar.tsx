// frontend/src/components/Sidebar.tsx
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
    IconButton,
    Menu,
    MenuItem
} from "@mui/material"
import {
    Home,
    CalendarMonth,
    Settings,
    Logout,
    KeyboardArrowDown,
    People
} from "@mui/icons-material"
import { useNavigate, useLocation } from "react-router-dom"
import { useEffect, useState } from "react"
import { jwtDecode } from "jwt-decode"

const Sidebar = () => {
    const navigate = useNavigate()
    const location = useLocation()
    const [usuario, setUsuario] = useState<any>(null)
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)

    useEffect(() => {
        const token = localStorage.getItem("token")
        if (token) {
            const decoded: any = jwtDecode(token)
            setUsuario(decoded)
        }
    }, [])

    const menu = [
        { texto: "Painel", icone: <Home />, rota: "/dashboard" },
        { texto: "Agenda Semanal", icone: <CalendarMonth />, rota: "/agenda" },
        { texto: "Clientes", icone: <People />, rota: "/clientes" },
        { texto: "Sugestões de Visita", icone: <Settings />, rota: "/sugestoes" },
    ]

    const sair = () => {
        localStorage.removeItem("token")
        localStorage.removeItem("usuario")
        navigate("/login")
    }

    return (
        <Box width={250} bgcolor="#eef3fd" height="100vh" display="flex" flexDirection="column" justifyContent="space-between">
            <Box>
                <Typography variant="h6" p={2} fontWeight={700} color="#5b82ea">
                    AgendaRep
                </Typography>
                <Divider />
                <List>
                    {menu.map((item) => (
                        <ListItem key={item.texto} disablePadding>
                            <ListItemButton selected={location.pathname === item.rota} onClick={() => navigate(item.rota)}>
                                <ListItemIcon>{item.icone}</ListItemIcon>
                                <ListItemText primary={item.texto} />
                            </ListItemButton>
                        </ListItem>
                    ))}
                </List>
            </Box>

            <Box px={2} pb={1}>
                <Divider sx={{ mb: 1 }} />
                <Box display="flex" alignItems="center" justifyContent="space-between">
                    <Box>
                        <Typography fontSize={13} fontWeight={600}>{usuario?.nome || "Usuário"}</Typography>
                        <Typography variant="caption">{usuario?.perfil || "representante"}</Typography>
                    </Box>
                    <IconButton size="small" onClick={(e) => setAnchorEl(e.currentTarget)}>
                        <Avatar sx={{ width: 30, height: 30 }}>{usuario?.nome?.[0] || "U"}</Avatar>
                        <KeyboardArrowDown />
                    </IconButton>
                    <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={() => setAnchorEl(null)}>
                        <MenuItem onClick={() => setAnchorEl(null)}>Configurações</MenuItem>
                        <MenuItem onClick={sair} sx={{ color: "red" }}>Sair</MenuItem>
                    </Menu>
                </Box>
            </Box>
        </Box>
    )
}

export default Sidebar
