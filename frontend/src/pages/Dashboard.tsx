"use client"

import {
    Box,
    Typography,
    TextField,
    MenuItem,
    Card,
    CardContent,
    List,
    ListItem,
    ListItemText,
    ListItemIcon,
    Chip,
} from "@mui/material"
import {
    People,
    CalendarMonth,
    MonetizationOn,
    Dashboard as DashboardIcon,
    CheckCircle,
    Schedule,
    TrendingUp,
} from "@mui/icons-material"
import axios from "axios"
import dayjs from "dayjs"
import { useEffect, useState } from "react"
import { jwtDecode } from "jwt-decode"

const API = import.meta.env.VITE_API_URL

export default function Dashboard() {
    const [clientes, setClientes] = useState<any[]>([])
    const [visitas, setVisitas] = useState<any[]>([])
    const [potencialTotal, setPotencialTotal] = useState(0)
    const [representantes, setRepresentantes] = useState<any[]>([])
    const [repSelecionado, setRepSelecionado] = useState("")
    const [perfil, setPerfil] = useState("")
    const [loading, setLoading] = useState(true)
    const token = localStorage.getItem("token")

    const carregar = async () => {
        try {
            setLoading(true)
            const params: any = {}
            if (repSelecionado) params.codusuario = repSelecionado

            // Carregar clientes
            const resClientes = await axios.get(`${API}/clientes`, {
                params,
                headers: { Authorization: `Bearer ${token}` },
            })
            const dadosClientes = resClientes.data.map((l: any) => ({
                ...l,
                potencial_compra: Number(l.potencial_compra),
            }))
            setClientes(dadosClientes)
            setPotencialTotal(dadosClientes.reduce((s: number, c: any) => s + c.potencial_compra, 0))

            // Carregar visitas da semana
            const inicio = dayjs().startOf("week").format("YYYY-MM-DD")
            const fim = dayjs().endOf("week").format("YYYY-MM-DD")
            const paramsVisitas: any = { inicio, fim }
            if (repSelecionado) paramsVisitas.codusuario = repSelecionado
            const resVisitas = await axios.get(`${API}/visitas`, {
                params: paramsVisitas,
                headers: { Authorization: `Bearer ${token}` },
            })
            setVisitas(resVisitas.data)
        } catch (error) {
            console.error("Erro ao carregar dados:", error)
        } finally {
            setLoading(false)
        }
    }

    const carregarRepresentantes = async () => {
        const res = await axios.get(`${API}/usuarios/representantes`, {
            headers: { Authorization: `Bearer ${token}` },
        })
        setRepresentantes(res.data)
    }

    useEffect(() => {
        if (token) {
            const data: any = jwtDecode(token)
            setPerfil(data.perfil)
            if (data.perfil === "coordenador" || data.perfil === "diretor") {
                carregarRepresentantes()
            }
        }
    }, [token])

    useEffect(() => {
        if (token) {
            carregar()
        }
    }, [token, repSelecionado])

    const qtdClientes = Array.from(new Set(clientes.map((c: any) => c.id_cliente))).length

    const formatarMoeda = (valor: number) =>
        valor.toLocaleString("pt-BR", {
            style: "currency",
            currency: "BRL",
        })

    const visitasConfirmadas = visitas.filter((v) => v.confirmado).length
    const visitasPendentes = visitas.filter((v) => !v.confirmado).length

    const atividades = visitas
        .slice()
        .sort((a, b) => dayjs(`${b.data} ${b.hora}`).diff(dayjs(`${a.data} ${a.hora}`)))
        .slice(0, 10) // Mostrar apenas as 10 mais recentes
        .map((v) => ({
            id: v.id,
            nome: v.nome_cliente || v.nome_cliente_temp,
            data: dayjs(v.data).format("DD/MM/YYYY"),
            hora: v.hora,
            confirmado: v.confirmado,
            observacao: v.observacao,
        }))

    return (
        <Box sx={{ p: 3 }}>
            {/* Header */}
            <Box sx={{ mb: 4 }}>
                <Box sx={{ display: "flex", alignItems: "center", mb: 1 }}>
                    <DashboardIcon sx={{ color: "#6366f1", mr: 1, fontSize: 28 }} />
                    <Typography variant="h4" sx={{ fontWeight: 600, color: "#1f2937" }}>
                        Painel Geral
                    </Typography>
                </Box>
                <Typography variant="body1" color="text.secondary">
                    Visão geral das suas atividades, clientes e potencial de vendas.
                </Typography>
            </Box>

            {/* Filtro de representantes */}
            {(perfil === "coordenador" || perfil === "diretor") && (
                <Box sx={{ mb: 3 }}>
                    <TextField
                        select
                        label="Representante"
                        value={repSelecionado}
                        onChange={(e) => setRepSelecionado(e.target.value)}
                        sx={{ minWidth: 200 }}
                    >
                        <MenuItem value="">Todos os Representantes</MenuItem>
                        {representantes.map((r: any) => (
                            <MenuItem key={r.codusuario} value={r.codusuario}>
                                {r.nome}
                            </MenuItem>
                        ))}
                    </TextField>
                </Box>
            )}

            {/* Cards de estatísticas */}
            <Box
                sx={{
                    display: "flex",
                    gap: 3,
                    mb: 4,
                    flexWrap: "wrap",
                    "& > *": {
                        flex: { xs: "1 1 100%", sm: "1 1 calc(50% - 12px)", md: "1 1 calc(25% - 18px)" },
                        minWidth: 250,
                    },
                }}
            >
                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 3 }}>
                        <People sx={{ fontSize: 48, color: "#6366f1", mb: 2 }} />
                        <Typography variant="h3" sx={{ fontWeight: 700, color: "#1f2937", mb: 1 }}>
                            {qtdClientes}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Clientes Ativos
                        </Typography>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 3 }}>
                        <CalendarMonth sx={{ fontSize: 48, color: "#10b981", mb: 2 }} />
                        <Typography variant="h3" sx={{ fontWeight: 700, color: "#1f2937", mb: 1 }}>
                            {visitas.length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Visitas na Semana
                        </Typography>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 3 }}>
                        <MonetizationOn sx={{ fontSize: 48, color: "#f59e0b", mb: 2 }} />
                        <Typography variant="h6" sx={{ fontWeight: 700, color: "#1f2937", mb: 1 }}>
                            {formatarMoeda(potencialTotal)}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Potencial Total
                        </Typography>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 3 }}>
                        <TrendingUp sx={{ fontSize: 48, color: "#8b5cf6", mb: 2 }} />
                        <Typography variant="h3" sx={{ fontWeight: 700, color: "#1f2937", mb: 1 }}>
                            {visitasConfirmadas}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Visitas Confirmadas
                        </Typography>
                    </CardContent>
                </Card>
            </Box>

            {/* Resumo de visitas */}
            <Box
                sx={{
                    display: "flex",
                    gap: 3,
                    mb: 4,
                    flexDirection: { xs: "column", md: "row" },
                }}
            >
                <Card elevation={0} sx={{ border: "1px solid #e5e7eb", flex: 1 }}>
                    <CardContent sx={{ p: 3 }}>
                        <Typography variant="h6" sx={{ fontWeight: 600, mb: 2, color: "#1f2937" }}>
                            Status das Visitas
                        </Typography>
                        <Box sx={{ display: "flex", gap: 2, flexWrap: "wrap" }}>
                            <Chip
                                icon={<CheckCircle />}
                                label={`${visitasConfirmadas} Confirmadas`}
                                color="success"
                                variant="outlined"
                            />
                            <Chip icon={<Schedule />} label={`${visitasPendentes} Pendentes`} color="warning" variant="outlined" />
                        </Box>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb", flex: 1 }}>
                    <CardContent sx={{ p: 3 }}>
                        <Typography variant="h6" sx={{ fontWeight: 600, mb: 2, color: "#1f2937" }}>
                            Resumo da Semana
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                            Período: {dayjs().startOf("week").format("DD/MM")} a {dayjs().endOf("week").format("DD/MM/YYYY")}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Total de {visitas.length} visitas agendadas
                        </Typography>
                    </CardContent>
                </Card>
            </Box>

            {/* Atividades recentes */}
            <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                <CardContent sx={{ p: 3 }}>
                    <Typography variant="h6" sx={{ fontWeight: 600, mb: 3, color: "#1f2937" }}>
                        Atividades Recentes
                    </Typography>

                    {atividades.length > 0 ? (
                        <List sx={{ p: 0 }}>
                            {atividades.map((atividade, index) => (
                                <ListItem
                                    key={atividade.id}
                                    sx={{
                                        px: 0,
                                        py: 1.5,
                                        borderBottom: index < atividades.length - 1 ? "1px solid #f3f4f6" : "none",
                                    }}
                                >
                                    <ListItemIcon sx={{ minWidth: 40 }}>
                                        {atividade.confirmado ? (
                                            <CheckCircle sx={{ color: "#10b981", fontSize: 20 }} />
                                        ) : (
                                            <Schedule sx={{ color: "#f59e0b", fontSize: 20 }} />
                                        )}
                                    </ListItemIcon>
                                    <ListItemText
                                        primary={
                                            <Box sx={{ display: "flex", alignItems: "center", gap: 1, flexWrap: "wrap" }}>
                                                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                                    {atividade.confirmado ? "Visita confirmada" : "Visita agendada"} com {atividade.nome}
                                                </Typography>
                                                <Chip
                                                    label={`${atividade.data} às ${atividade.hora}`}
                                                    size="small"
                                                    variant="outlined"
                                                    sx={{ fontSize: "0.7rem" }}
                                                />
                                            </Box>
                                        }
                                        secondary={
                                            atividade.observacao && (
                                                <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: "block" }}>
                                                    {atividade.observacao}
                                                </Typography>
                                            )
                                        }
                                    />
                                </ListItem>
                            ))}
                        </List>
                    ) : (
                        <Box sx={{ textAlign: "center", py: 4 }}>
                            <CalendarMonth sx={{ fontSize: 48, color: "#d1d5db", mb: 2 }} />
                            <Typography variant="body1" color="text.secondary">
                                Nenhuma atividade recente encontrada
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                                Suas visitas agendadas aparecerão aqui
                            </Typography>
                        </Box>
                    )}
                </CardContent>
            </Card>
        </Box>
    )
}
