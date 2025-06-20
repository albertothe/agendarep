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
import { People, CalendarMonth, MonetizationOn, Dashboard as DashboardIcon, TrendingUp } from "@mui/icons-material"
import { CheckCircle, Schedule } from "@mui/icons-material"
import axios from "axios"
import dayjs from "dayjs"
import { useEffect, useState } from "react"
import { jwtDecode } from "jwt-decode"

const API = import.meta.env.VITE_API_URL

export default function Dashboard() {
    const [clientes, setClientes] = useState<any[]>([])
    const [visitas, setVisitas] = useState<any[]>([])
    const [potencialTotal, setPotencialTotal] = useState(0)
    const [totalComprado, setTotalComprado] = useState(0)
    const [representantes, setRepresentantes] = useState<any[]>([])
    const [repSelecionado, setRepSelecionado] = useState("")
    const [perfil, setPerfil] = useState("")
    const [, setLoading] = useState(true)
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
                valor_comprado: Number(l.valor_comprado),
            }))
            setClientes(dadosClientes)
            setPotencialTotal(dadosClientes.reduce((s: number, c: any) => s + c.potencial_compra, 0))
            setTotalComprado(dadosClientes.reduce((s: number, c: any) => s + c.valor_comprado, 0))

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

            {/* 1ª Linha - Cards principais */}
            <Box
                sx={{
                    display: "flex",
                    gap: 2,
                    mb: 3,
                    flexWrap: "nowrap",
                    "& > *": {
                        flex: "1 1 0",
                        minWidth: 0,
                    },
                }}
            >
                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 2 }}>
                        <People sx={{ fontSize: 32, color: "#6366f1", mb: 1 }} />
                        <Typography variant="h4" sx={{ fontWeight: 700, color: "#1f2937", mb: 0.5, lineHeight: 1 }}>
                            {qtdClientes}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                            Clientes Ativos
                        </Typography>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 2 }}>
                        <MonetizationOn sx={{ fontSize: 32, color: "#f59e0b", mb: 1 }} />
                        <Typography variant="h6" sx={{ fontWeight: 700, color: "#1f2937", mb: 0.5, lineHeight: 1 }}>
                            {formatarMoeda(potencialTotal)}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                            Potencial Total
                        </Typography>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 2 }}>
                        <TrendingUp sx={{ fontSize: 32, color: "#10b981", mb: 1 }} />
                        <Typography variant="h6" sx={{ fontWeight: 700, color: "#1f2937", mb: 0.5, lineHeight: 1 }}>
                            {formatarMoeda(totalComprado)}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                            Total Comprado
                        </Typography>
                    </CardContent>
                </Card>
            </Box>

            {/* 2ª Linha - Cards de visitas */}
            <Box
                sx={{
                    display: "flex",
                    gap: 2,
                    mb: 3,
                    flexWrap: "nowrap",
                    "& > *": {
                        flex: "1 1 0",
                        minWidth: 0,
                    },
                }}
            >
                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 2 }}>
                        <CalendarMonth sx={{ fontSize: 32, color: "#8b5cf6", mb: 1 }} />
                        <Typography variant="h4" sx={{ fontWeight: 700, color: "#1f2937", mb: 0.5, lineHeight: 1 }}>
                            {visitas.length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                            Visitas na Semana
                        </Typography>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ textAlign: "center", p: 2 }}>
                        <CheckCircle sx={{ fontSize: 32, color: "#10b981", mb: 1 }} />
                        <Typography variant="h4" sx={{ fontWeight: 700, color: "#1f2937", mb: 0.5, lineHeight: 1 }}>
                            {visitasConfirmadas}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                            Visitas Confirmadas
                        </Typography>
                    </CardContent>
                </Card>

                <Card elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                    <CardContent sx={{ p: 2, display: "flex", flexDirection: "column", alignItems: "center" }}>
                        <Typography variant="body1" sx={{ fontWeight: 600, mb: 1, color: "#1f2937", fontSize: "0.9rem" }}>
                            Status das Visitas
                        </Typography>
                        <Box sx={{ display: "flex", gap: 0.5, flexDirection: "column", alignItems: "center" }}>
                            <Chip
                                icon={<CheckCircle sx={{ fontSize: "14px !important" }} />}
                                label={`${visitasConfirmadas} Confirmadas`}
                                color="success"
                                variant="outlined"
                                size="small"
                                sx={{ fontSize: "0.7rem", height: 24 }}
                            />
                            <Chip
                                icon={<Schedule sx={{ fontSize: "14px !important" }} />}
                                label={`${visitasPendentes} Pendentes`}
                                color="warning"
                                variant="outlined"
                                size="small"
                                sx={{ fontSize: "0.7rem", height: 24 }}
                            />
                        </Box>
                    </CardContent>
                </Card>
            </Box>

            {/* 3ª Linha - Atividades recentes */}
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
