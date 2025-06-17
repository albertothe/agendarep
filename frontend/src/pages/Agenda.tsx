// frontend/src/pages/Agenda.tsx
import React, { useEffect, useState } from "react"
import { jwtDecode } from "jwt-decode";
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
    FormControlLabel
} from "@mui/material"
import { Add, Check } from "@mui/icons-material"

const horas = [
    "08:00", "09:00", "10:00", "11:00", "12:00",
    "13:00", "14:00", "15:00", "16:00", "17:00"
]

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
        const res = await axios.get("http://localhost:8501/visitas", {
            params,
            headers: { Authorization: `Bearer ${token}` }
        })
        setVisitas(res.data)
    }

    const buscarClientes = async () => {
        const params: any = {}
        if (repSelecionado) params.codusuario = repSelecionado
        const res = await axios.get("http://localhost:8501/visitas/clientes/representante", {
            params,
            headers: { Authorization: `Bearer ${token}` }
        })
        setClientes(res.data)
    }

    const carregarRepresentantes = async () => {
        const res = await axios.get("http://localhost:8501/usuarios/representantes", {
            headers: { Authorization: `Bearer ${token}` }
        })
        setRepresentantes(res.data)
    }

    const abrirModal = (data: string, hora: string) => {
        setNovaVisita({ data, hora })
        setUsarClienteTemporario(false)
        setModalAberto(true)
    }

    const salvarVisita = async () => {
        await axios.post("http://localhost:8501/visitas", novaVisita, {
            headers: { Authorization: `Bearer ${token}` }
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
        await axios.put(`http://localhost:8501/visitas/${visitaParaConfirmar.id}/observacao`, { observacao: observacaoEditada }, {
            headers: { Authorization: `Bearer ${token}` }
        })
        await axios.put(`http://localhost:8501/visitas/${visitaParaConfirmar.id}/confirmar`, {}, {
            headers: { Authorization: `Bearer ${token}` }
        })
        setVisitaParaConfirmar(null)
        buscarVisitas()
    }


    return (
        <Box p={2}>
            {(perfil === "coordenador" || perfil === "diretor") && (
                <Box mb={2}>
                    <TextField
                        select
                        label="Representante"
                        value={repSelecionado}
                        onChange={(e) => setRepSelecionado(e.target.value)}
                        size="small"
                    >
                        <MenuItem value="">Todos</MenuItem>
                        {representantes.map((r: any) => (
                            <MenuItem key={r.codusuario} value={r.codusuario}>{r.nome}</MenuItem>
                        ))}
                    </TextField>
                </Box>
            )}
            <Box display="flex" justifyContent="space-between" mb={2}>
                <Button onClick={() => setSemanaAtual(semanaAtual.subtract(1, "week"))}>Semana anterior</Button>
                <Typography variant="h6">Semana de {diasSemana[0].format("DD/MM")} a {diasSemana[6].format("DD/MM")}</Typography>
                <Button onClick={() => setSemanaAtual(semanaAtual.add(1, "week"))}>Próxima semana</Button>
            </Box>

            <Box display="grid" gridTemplateColumns="100px repeat(7, 1fr)" gap={1}>
                <Box></Box>
                {diasSemana.map((dia, i) => (
                    <Paper key={i} sx={{ p: 1, textAlign: "center" }}>
                        <Typography fontWeight="bold">{dia.format("dddd")}</Typography>
                        <Typography variant="body2">{dia.format("DD/MM")}</Typography>
                    </Paper>
                ))}

                {horas.map((hora) => (
                    <React.Fragment key={hora}>
                        <Box sx={{ border: "1px solid #ccc", textAlign: "center" }}>{hora}</Box>
                        {diasSemana.map((dia, i) => {
                            const data = dia.format("YYYY-MM-DD")
                            const visitasHorario = visitas.filter(
                                (v) => dayjs(v.data).format("YYYY-MM-DD") === data && String(v.hora).slice(0, 5) === hora
                            )
                            const visita = visitasHorario[0]
                            return (
                                <Box key={i} sx={{ border: "1px solid #ccc", position: "relative", minHeight: 70, bgcolor: visita ? (visita.confirmado ? "#e8f5e9" : "#e3f2fd") : "inherit" }}>
                                    {visita ? (
                                        <Box p={1} sx={{ fontSize: 12, lineHeight: 1.2 }}>
                                            <Typography variant="body2" fontWeight="bold" sx={{ fontSize: 12 }}>
                                                {visita.nome_cliente || visita.nome_cliente_temp}
                                            </Typography>
                                            <Typography variant="body2" fontSize={12} sx={{ wordBreak: "break-word" }}>{visita.observacao}</Typography>
                                            {visitasHorario.length > 1 && (
                                                <Typography variant="caption" sx={{ position: "absolute", top: 2, right: 2 }}>
                                                    +{visitasHorario.length - 1}
                                                </Typography>
                                            )}
                                            {!visita.confirmado && (
                                                <IconButton size="small" onClick={() => abrirModalConfirmar(visita)} sx={{ position: "absolute", bottom: 2, right: 2 }}>
                                                    <Check fontSize="small" />
                                                </IconButton>
                                            )}
                                        </Box>
                                    ) : (
                                        <IconButton size="small" onClick={() => abrirModal(data, hora)}>
                                            <Add fontSize="small" />
                                        </IconButton>
                                    )}
                                </Box>
                            )
                        })}
                    </React.Fragment>
                ))}
            </Box>

            <Modal open={modalAberto} onClose={() => setModalAberto(false)}>
                <Box p={3} bgcolor="#fff" width={400} mx="auto" mt={10} borderRadius={2}>
                    <Typography variant="h6" mb={2}>Nova Visita</Typography>

                    <FormControlLabel
                        control={<Switch checked={usarClienteTemporario} onChange={() => setUsarClienteTemporario(!usarClienteTemporario)} />}
                        label="Cliente temporário"
                        sx={{ mb: 2 }}
                    />

                    {!usarClienteTemporario ? (
                        <TextField
                            select
                            fullWidth
                            label="Cliente"
                            value={novaVisita.id_cliente || ""}
                            onChange={(e) => setNovaVisita({ ...novaVisita, id_cliente: e.target.value, nome_cliente_temp: "", telefone_temp: "" })}
                            sx={{ mb: 2 }}
                        >
                            {clientes.map((c: any) => (
                                <MenuItem key={c.id_cliente} value={c.id_cliente}>{c.nome}</MenuItem>
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
                        value={novaVisita.observacao || ""}
                        onChange={(e) => setNovaVisita({ ...novaVisita, observacao: e.target.value })}
                        sx={{ mb: 2 }}
                    />
                    <Button fullWidth variant="contained" onClick={salvarVisita}>Salvar</Button>
                </Box>
            </Modal>

            <Modal open={Boolean(visitaParaConfirmar)} onClose={() => setVisitaParaConfirmar(null)}>
                <Box p={3} bgcolor="#fff" width={400} mx="auto" mt={10} borderRadius={2}>
                    <Typography variant="h6" mb={2}>Confirmar Visita</Typography>
                    <TextField
                        fullWidth
                        label="Observação"
                        value={observacaoEditada}
                        onChange={(e) => setObservacaoEditada(e.target.value)}
                        sx={{ mb: 2 }}
                    />
                    <Button fullWidth variant="contained" onClick={confirmarVisita}>Confirmar</Button>
                </Box>
            </Modal>
        </Box>
    )
}

export default Agenda
