"use client"

import { useEffect, useState } from "react"
import { jwtDecode } from "jwt-decode"
import axios from "axios"
import dayjs from "dayjs"
import "dayjs/locale/pt-br"
import {
    Box,
    Button,
    IconButton,
    Modal,
    TextField,
    Typography,
    MenuItem,
    Paper,
    Switch,
    FormControlLabel,
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableRow,
} from "@mui/material"
import { Add, Check, CalendarMonth } from "@mui/icons-material"

const API = import.meta.env.VITE_API_URL

const horas = ["08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00"]

dayjs.locale("pt-br")

const Agenda = () => {
    const [semanaAtual, setSemanaAtual] = useState(dayjs())
    const [visitas, setVisitas] = useState<any[]>([])
    const [clientes, setClientes] = useState<any[]>([])
    const [representantes, setRepresentantes] = useState<any[]>([])
    const [repSelecionado, setRepSelecionado] = useState("")
    const [perfil, setPerfil] = useState("")
    const [modalAberto, setModalAberto] = useState(false)
    const [novaVisita, setNovaVisita] = useState<any>({})
    const [usarClienteTemporario, setUsarClienteTemporario] = useState(false)
    const [observacaoEditada, setObservacaoEditada] = useState("")
    const [visitaParaConfirmar, setVisitaParaConfirmar] = useState<any | null>(null)

    const token = localStorage.getItem("token")

    const diasSemana = [...Array(7)].map((_, i) => semanaAtual.startOf("week").add(i, "day"))

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
            buscarVisitas()
            buscarClientes()
        }
    }, [semanaAtual, token, repSelecionado])

    const buscarVisitas = async () => {
        const inicio = diasSemana[0].format("YYYY-MM-DD")
        const fim = diasSemana[6].format("YYYY-MM-DD")
        const params: any = { inicio, fim }
        if (repSelecionado) params.codusuario = repSelecionado
        const res = await axios.get(`${API}/visitas`, {
            params,
            headers: { Authorization: `Bearer ${token}` },
        })
        setVisitas(res.data)
    }

    const buscarClientes = async () => {
        const params: any = {}
        if (repSelecionado) params.codusuario = repSelecionado
        const res = await axios.get(`${API}/visitas/clientes/representante`, {
            params,
            headers: { Authorization: `Bearer ${token}` },
        })
        setClientes(res.data)
    }

    const carregarRepresentantes = async () => {
        const res = await axios.get(`${API}/usuarios/representantes`, {
            headers: { Authorization: `Bearer ${token}` },
        })
        setRepresentantes(res.data)
    }

    const abrirModal = (data: string, hora: string) => {
        setNovaVisita({ data, hora })
        setUsarClienteTemporario(false)
        setModalAberto(true)
    }

    const salvarVisita = async () => {
        await axios.post(`${API}/visitas`, novaVisita, {
            headers: { Authorization: `Bearer ${token}` },
        })
        setModalAberto(false)
        buscarVisitas()
    }

    const abrirModalConfirmar = (visita: any) => {
        setVisitaParaConfirmar(visita)
        setObservacaoEditada(visita.observacao || "")
    }

    const confirmarVisita = async () => {
        if (!visitaParaConfirmar) return
        await axios.put(
            `${API}/visitas/${visitaParaConfirmar.id}/observacao`,
            { observacao: observacaoEditada },
            {
                headers: { Authorization: `Bearer ${token}` },
            },
        )
        await axios.put(
            `${API}/visitas/${visitaParaConfirmar.id}/confirmar`,
            {},
            {
                headers: { Authorization: `Bearer ${token}` },
            },
        )
        setVisitaParaConfirmar(null)
        buscarVisitas()
    }

    const formatarTituloSemana = () => {
        const inicio = diasSemana[0]
        const fim = diasSemana[6]
        const mesInicio = inicio.format("MMMM")
        const mesFim = fim.format("MMMM")
        const anoInicio = inicio.format("YYYY")
        const anoFim = fim.format("YYYY")

        if (mesInicio === mesFim && anoInicio === anoFim) {
            return `Semana De ${mesInicio} ${inicio.format("DD")}, ${anoInicio}`
        }
        return `Semana De ${inicio.format("MMMM DD")} a ${fim.format("MMMM DD, YYYY")}`
    }

    const formatarDiaSemana = (dia: dayjs.Dayjs) => {
        // dayjs retorna os nomes dos dias em português quando a localidade
        // "pt-br" está ativa. Porém, alguns dias incluem o sufixo "-feira",
        // que não desejamos exibir.
        let nome = dia.format("dddd")
        nome = nome.charAt(0).toUpperCase() + nome.slice(1)
        if (nome.endsWith("-feira")) {
            nome = nome.replace("-feira", "")
        }
        return `${nome}, ${dia.format("MMM DD")}`
    }

    return (
        <Box sx={{ p: 3 }}>
            {/* Header */}
            <Box sx={{ mb: 4 }}>
                <Box sx={{ display: "flex", alignItems: "center", mb: 1 }}>
                    <CalendarMonth sx={{ color: "#6366f1", mr: 1, fontSize: 28 }} />
                    <Typography variant="h4" sx={{ fontWeight: 600, color: "#1f2937" }}>
                        Agenda Semanal de Visitas
                    </Typography>
                </Box>
                <Typography variant="body1" color="text.secondary">
                    Gerencie suas visitas a clientes para a semana. Clique em um horário para agendar uma nova visita ou ver
                    detalhes de uma existente.
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

            {/* Controles de navegação */}
            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
                <Button
                    variant="contained"
                    onClick={() => setSemanaAtual(semanaAtual.subtract(1, "week"))}
                    sx={{ bgcolor: "#6366f1", "&:hover": { bgcolor: "#5856eb" } }}
                >
                    Semana Anterior
                </Button>

                <Typography variant="h6" sx={{ fontWeight: 600, color: "#1f2937", textTransform: "capitalize" }}>
                    {formatarTituloSemana()}
                </Typography>

                <Button
                    variant="contained"
                    onClick={() => setSemanaAtual(semanaAtual.add(1, "week"))}
                    sx={{ bgcolor: "#6366f1", "&:hover": { bgcolor: "#5856eb" } }}
                >
                    Próxima Semana
                </Button>
            </Box>

            {/* Grid da agenda */}
            <Paper elevation={0} sx={{ border: "1px solid #e5e7eb", overflow: "hidden" }}>
                <Table sx={{ minWidth: 800 }}>
                    <TableHead>
                        <TableRow sx={{ bgcolor: "#f9fafb" }}>
                            <TableCell sx={{ fontWeight: 600, color: "#374151", width: 100, textAlign: "center" }}>Hora</TableCell>
                            {diasSemana.map((dia, i) => (
                                <TableCell key={i} sx={{ fontWeight: 600, color: "#374151", textAlign: "center", minWidth: 150 }}>
                                    {formatarDiaSemana(dia)}
                                </TableCell>
                            ))}
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {horas.map((hora) => (
                            <TableRow key={hora}>
                                <TableCell
                                    sx={{
                                        bgcolor: "#f8fafc",
                                        fontWeight: 600,
                                        color: "#6b7280",
                                        textAlign: "center",
                                        borderRight: "1px solid #e5e7eb",
                                    }}
                                >
                                    {hora}
                                </TableCell>
                                {diasSemana.map((dia, i) => {
                                    const data = dia.format("YYYY-MM-DD")
                                    const visitasHorario = visitas.filter(
                                        (v) => dayjs(v.data).format("YYYY-MM-DD") === data && String(v.hora).slice(0, 5) === hora,
                                    )
                                    const visita = visitasHorario[0]

                                    return (
                                        <TableCell
                                            key={i}
                                            sx={{
                                                position: "relative",
                                                height: 80,
                                                p: 1,
                                                bgcolor: visita ? (visita.confirmado ? "#f0fdf4" : "#eff6ff") : "white",
                                                border: "1px solid #e5e7eb",
                                                verticalAlign: "top",
                                                "&:hover": {
                                                    bgcolor: visita ? undefined : "#f9fafb",
                                                },
                                            }}
                                        >
                                            {visita ? (
                                                <Box sx={{ height: "100%", position: "relative" }}>
                                                    <Typography
                                                        variant="body2"
                                                        sx={{
                                                            fontWeight: 600,
                                                            fontSize: "0.75rem",
                                                            color: "#1f2937",
                                                            mb: 0.5,
                                                            lineHeight: 1.2,
                                                        }}
                                                    >
                                                        {visita.nome_cliente || visita.nome_cliente_temp}
                                                    </Typography>
                                                    <Typography
                                                        variant="caption"
                                                        sx={{
                                                            fontSize: "0.7rem",
                                                            color: "#6b7280",
                                                            lineHeight: 1.2,
                                                            display: "-webkit-box",
                                                            WebkitLineClamp: 2,
                                                            WebkitBoxOrient: "vertical",
                                                            overflow: "hidden",
                                                        }}
                                                    >
                                                        {visita.observacao}
                                                    </Typography>

                                                    {visitasHorario.length > 1 && (
                                                        <Box
                                                            sx={{
                                                                position: "absolute",
                                                                top: 2,
                                                                right: 2,
                                                                bgcolor: "#6366f1",
                                                                color: "white",
                                                                borderRadius: "50%",
                                                                width: 16,
                                                                height: 16,
                                                                display: "flex",
                                                                alignItems: "center",
                                                                justifyContent: "center",
                                                                fontSize: "0.6rem",
                                                                fontWeight: 600,
                                                            }}
                                                        >
                                                            +{visitasHorario.length - 1}
                                                        </Box>
                                                    )}

                                                    {!visita.confirmado && (
                                                        <IconButton
                                                            size="small"
                                                            onClick={() => abrirModalConfirmar(visita)}
                                                            sx={{
                                                                position: "absolute",
                                                                bottom: 2,
                                                                right: 2,
                                                                bgcolor: "#10b981",
                                                                color: "white",
                                                                width: 20,
                                                                height: 20,
                                                                "&:hover": {
                                                                    bgcolor: "#059669",
                                                                },
                                                            }}
                                                        >
                                                            <Check sx={{ fontSize: 14 }} />
                                                        </IconButton>
                                                    )}
                                                </Box>
                                            ) : (
                                                <Box
                                                    sx={{
                                                        display: "flex",
                                                        alignItems: "center",
                                                        justifyContent: "center",
                                                        height: "100%",
                                                        cursor: "pointer",
                                                    }}
                                                    onClick={() => abrirModal(data, hora)}
                                                >
                                                    <IconButton
                                                        size="small"
                                                        sx={{
                                                            color: "#9ca3af",
                                                            "&:hover": {
                                                                color: "#6366f1",
                                                                bgcolor: "#f0f9ff",
                                                            },
                                                        }}
                                                    >
                                                        <Add />
                                                    </IconButton>
                                                </Box>
                                            )}
                                        </TableCell>
                                    )
                                })}
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            </Paper>

            {/* Modal Nova Visita */}
            <Modal open={modalAberto} onClose={() => setModalAberto(false)}>
                <Box
                    sx={{
                        position: "absolute",
                        top: "50%",
                        left: "50%",
                        transform: "translate(-50%, -50%)",
                        width: 400,
                        bgcolor: "background.paper",
                        borderRadius: 2,
                        boxShadow: 24,
                        p: 3,
                    }}
                >
                    <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
                        Nova Visita
                    </Typography>

                    <FormControlLabel
                        control={
                            <Switch
                                checked={usarClienteTemporario}
                                onChange={() => setUsarClienteTemporario(!usarClienteTemporario)}
                            />
                        }
                        label="Cliente temporário"
                        sx={{ mb: 2 }}
                    />

                    {!usarClienteTemporario ? (
                        <TextField
                            select
                            fullWidth
                            label="Cliente"
                            value={novaVisita.id_cliente || ""}
                            onChange={(e) =>
                                setNovaVisita({ ...novaVisita, id_cliente: e.target.value, nome_cliente_temp: "", telefone_temp: "" })
                            }
                            sx={{ mb: 2 }}
                        >
                            {clientes.map((c: any) => (
                                <MenuItem key={c.id_cliente} value={c.id_cliente}>
                                    {c.nome}
                                </MenuItem>
                            ))}
                        </TextField>
                    ) : (
                        <>
                            <TextField
                                fullWidth
                                label="Nome do cliente"
                                value={novaVisita.nome_cliente_temp || ""}
                                onChange={(e) => setNovaVisita({ ...novaVisita, nome_cliente_temp: e.target.value, id_cliente: null })}
                                sx={{ mb: 2 }}
                            />
                            <TextField
                                fullWidth
                                label="Telefone"
                                value={novaVisita.telefone_temp || ""}
                                onChange={(e) => setNovaVisita({ ...novaVisita, telefone_temp: e.target.value })}
                                sx={{ mb: 2 }}
                            />
                        </>
                    )}

                    <TextField
                        fullWidth
                        label="Observação"
                        multiline
                        rows={3}
                        value={novaVisita.observacao || ""}
                        onChange={(e) => setNovaVisita({ ...novaVisita, observacao: e.target.value })}
                        sx={{ mb: 3 }}
                    />

                    <Box sx={{ display: "flex", gap: 2 }}>
                        <Button fullWidth variant="outlined" onClick={() => setModalAberto(false)}>
                            Cancelar
                        </Button>
                        <Button fullWidth variant="contained" onClick={salvarVisita}>
                            Salvar
                        </Button>
                    </Box>
                </Box>
            </Modal>

            {/* Modal Confirmar Visita */}
            <Modal open={Boolean(visitaParaConfirmar)} onClose={() => setVisitaParaConfirmar(null)}>
                <Box
                    sx={{
                        position: "absolute",
                        top: "50%",
                        left: "50%",
                        transform: "translate(-50%, -50%)",
                        width: 400,
                        bgcolor: "background.paper",
                        borderRadius: 2,
                        boxShadow: 24,
                        p: 3,
                    }}
                >
                    <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
                        Confirmar Visita
                    </Typography>
                    <TextField
                        fullWidth
                        label="Observação"
                        multiline
                        rows={3}
                        value={observacaoEditada}
                        onChange={(e) => setObservacaoEditada(e.target.value)}
                        sx={{ mb: 3 }}
                    />
                    <Box sx={{ display: "flex", gap: 2 }}>
                        <Button fullWidth variant="outlined" onClick={() => setVisitaParaConfirmar(null)}>
                            Cancelar
                        </Button>
                        <Button fullWidth variant="contained" onClick={confirmarVisita}>
                            Confirmar
                        </Button>
                    </Box>
                </Box>
            </Modal>
        </Box>
    )
}

export default Agenda
