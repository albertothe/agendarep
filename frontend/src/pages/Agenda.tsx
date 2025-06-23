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
    const [buscaCliente, setBuscaCliente] = useState("")
    const [clienteSelecionado, setClienteSelecionado] = useState<any>(null)

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
        setBuscaCliente("")
        setClienteSelecionado(null)
        setModalAberto(true)
    }

    const salvarVisita = async () => {
        try {
            // Preparar dados da visita
            const dadosVisita = { ...novaVisita }

            // Se for coordenador/diretor, OBRIGATORIAMENTE usar o representante selecionado
            if (perfil === "coordenador" || perfil === "diretor") {
                if (!novaVisita.codusuario) {
                    console.error("Erro: Representante não selecionado!")
                    return
                }
                dadosVisita.codusuario = novaVisita.codusuario
            }
            // Se for representante, remover codusuario para que backend use o token
            else {
                delete dadosVisita.codusuario
            }

            console.log("=== DEBUG SALVAR VISITA ===")
            console.log("Perfil do usuário:", perfil)
            console.log("Representante selecionado no modal:", novaVisita.codusuario)
            console.log("Dados finais sendo enviados:", dadosVisita)
            console.log("Campo codusuario no payload:", dadosVisita.codusuario)
            console.log("========================")

            const response = await axios.post(`${API}/visitas`, dadosVisita, {
                headers: { Authorization: `Bearer ${token}` },
            })

            console.log("Resposta do backend:", response.data)

            setModalAberto(false)
            setNovaVisita({})
            setBuscaCliente("")
            setClienteSelecionado(null)
            buscarVisitas()

            console.log("Visita criada com sucesso!")
        } catch (error: any) {
            console.error("Erro ao criar visita:", error)
            if (error?.response) {
                console.error("Dados do erro:", error.response.data)
            }
        }
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
        const nomesDias = {
            domingo: "Domingo",
            segunda: "Segunda",
            terça: "Terça",
            quarta: "Quarta",
            quinta: "Quinta",
            sexta: "Sexta",
            sábado: "Sábado",
        }

        const diaSemanaKey = dia.format("dddd").toLowerCase()
        const diaSemana = nomesDias[diaSemanaKey as keyof typeof nomesDias] || dia.format("dddd")
        return `${diaSemana}, ${dia.format("MMM DD")}`
    }

    const clientesFiltrados = clientes.filter((cliente) =>
        cliente.nome.toLowerCase().includes(buscaCliente.toLowerCase()),
    )

    const buscarClientesRepresentante = async (codusuario: string) => {
        try {
            console.log("Buscando clientes para representante:", codusuario)
            const params = { codusuario }
            const res = await axios.get(`${API}/visitas/clientes/representante`, {
                params,
                headers: { Authorization: `Bearer ${token}` },
            })
            console.log("Clientes encontrados:", res.data)
            setClientes(res.data)
        } catch (error) {
            console.error("Erro ao buscar clientes do representante:", error)
            setClientes([])
        }
    }

    useEffect(() => {
        if (!modalAberto) {
            // Quando modal fechar, restaurar clientes baseado no filtro da página
            if (repSelecionado) {
                buscarClientesRepresentante(repSelecionado)
            } else {
                buscarClientes()
            }
        }
    }, [modalAberto])

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

                                                    {!visita.confirmado && perfil === "representante" && (
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
                        width: 500,
                        bgcolor: "background.paper",
                        borderRadius: 2,
                        boxShadow: 24,
                        p: 3,
                        maxHeight: "90vh",
                        overflow: "auto",
                    }}
                >
                    <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
                        Nova Visita
                    </Typography>

                    {/* Seleção de representante para coordenadores/diretores */}
                    {(perfil === "coordenador" || perfil === "diretor") && (
                        <TextField
                            select
                            fullWidth
                            label="Representante *"
                            value={novaVisita.codusuario || ""}
                            onChange={(e) => {
                                const codusuario = e.target.value
                                setNovaVisita({ ...novaVisita, codusuario })

                                // Buscar clientes do representante selecionado
                                if (codusuario) {
                                    buscarClientesRepresentante(codusuario)
                                } else {
                                    setClientes([])
                                }

                                // Limpar seleção de cliente atual
                                setBuscaCliente("")
                                setClienteSelecionado(null)
                                setNovaVisita((prev: any) => ({ ...prev, codusuario, id_cliente: null }))
                            }}
                            sx={{
                                mb: 2,
                                "& .MuiOutlinedInput-root": {
                                    "& fieldset": {
                                        borderColor: !novaVisita.codusuario ? "#f44336" : undefined,
                                        borderWidth: !novaVisita.codusuario ? 2 : 1,
                                    },
                                },
                                "& .MuiInputLabel-root": {
                                    color: !novaVisita.codusuario ? "#f44336" : undefined,
                                },
                            }}
                            required
                            error={!novaVisita.codusuario}
                            helperText={!novaVisita.codusuario ? "Selecione um representante" : ""}
                        >
                            <MenuItem value="" disabled>
                                <em>Selecione um representante</em>
                            </MenuItem>
                            {representantes.map((r: any) => (
                                <MenuItem key={r.codusuario} value={r.codusuario}>
                                    {r.nome}
                                </MenuItem>
                            ))}
                        </TextField>
                    )}

                    <FormControlLabel
                        control={
                            <Switch
                                checked={usarClienteTemporario}
                                onChange={() => {
                                    setUsarClienteTemporario(!usarClienteTemporario)
                                    setBuscaCliente("")
                                    setClienteSelecionado(null)
                                    setNovaVisita({ ...novaVisita, id_cliente: null, nome_cliente_temp: "", telefone_temp: "" })
                                }}
                            />
                        }
                        label="Cliente temporário"
                        sx={{ mb: 2 }}
                    />

                    {!usarClienteTemporario ? (
                        <Box sx={{ mb: 2 }}>
                            <TextField
                                fullWidth
                                label="Buscar cliente"
                                value={buscaCliente}
                                onChange={(e) => setBuscaCliente(e.target.value)}
                                placeholder="Digite o nome do cliente..."
                                sx={{ mb: 1 }}
                                InputProps={{
                                    endAdornment: buscaCliente && (
                                        <IconButton
                                            size="small"
                                            onClick={() => {
                                                setBuscaCliente("")
                                                setClienteSelecionado(null)
                                                setNovaVisita({ ...novaVisita, id_cliente: null })
                                            }}
                                        >
                                            <Typography variant="caption">✕</Typography>
                                        </IconButton>
                                    ),
                                }}
                            />

                            {clienteSelecionado && (
                                <Box
                                    sx={{
                                        p: 2,
                                        bgcolor: "#e3f2fd",
                                        borderRadius: 1,
                                        border: "2px solid #2196f3",
                                        mb: 1,
                                    }}
                                >
                                    <Typography variant="body2" sx={{ fontWeight: 600, color: "#1976d2" }}>
                                        ✓ {clienteSelecionado.nome}
                                    </Typography>
                                    <Typography variant="caption" color="text.secondary">
                                        {clienteSelecionado.telefone}
                                    </Typography>
                                </Box>
                            )}

                            {buscaCliente && !clienteSelecionado && (
                                <Paper
                                    elevation={2}
                                    sx={{
                                        maxHeight: 200,
                                        overflow: "auto",
                                        border: "1px solid #e0e0e0",
                                    }}
                                >
                                    {clientesFiltrados.length > 0 ? (
                                        clientesFiltrados.map((cliente: any) => (
                                            <Box
                                                key={cliente.id_cliente}
                                                sx={{
                                                    p: 2,
                                                    borderBottom: "1px solid #f0f0f0",
                                                    cursor: "pointer",
                                                    "&:hover": { bgcolor: "#f5f5f5" },
                                                    "&:last-child": { borderBottom: "none" },
                                                }}
                                                onClick={() => {
                                                    setClienteSelecionado(cliente)
                                                    setNovaVisita({ ...novaVisita, id_cliente: cliente.id_cliente })
                                                    setBuscaCliente("")
                                                }}
                                            >
                                                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                                    {cliente.nome}
                                                </Typography>
                                                <Typography variant="caption" color="text.secondary">
                                                    {cliente.telefone}
                                                </Typography>
                                            </Box>
                                        ))
                                    ) : (
                                        <Box sx={{ p: 2, textAlign: "center" }}>
                                            <Typography variant="body2" color="text.secondary">
                                                Nenhum cliente encontrado
                                            </Typography>
                                        </Box>
                                    )}
                                </Paper>
                            )}
                        </Box>
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
                        <Button
                            fullWidth
                            variant="outlined"
                            onClick={() => {
                                setModalAberto(false)
                                setBuscaCliente("")
                                setClienteSelecionado(null)
                            }}
                        >
                            Cancelar
                        </Button>
                        <Button
                            fullWidth
                            variant="contained"
                            onClick={salvarVisita}
                            disabled={
                                // Validação para coordenador/diretor: deve selecionar representante
                                ((perfil === "coordenador" || perfil === "diretor") && !novaVisita.codusuario) ||
                                // Validação de cliente: deve selecionar cliente ou preencher nome temporário
                                (!usarClienteTemporario && !novaVisita.id_cliente) ||
                                (usarClienteTemporario && !novaVisita.nome_cliente_temp)
                            }
                            sx={{
                                bgcolor:
                                    ((perfil === "coordenador" || perfil === "diretor") && !novaVisita.codusuario) ||
                                        (!usarClienteTemporario && !novaVisita.id_cliente) ||
                                        (usarClienteTemporario && !novaVisita.nome_cliente_temp)
                                        ? "#ccc"
                                        : "#6366f1",
                                "&:hover": {
                                    bgcolor:
                                        ((perfil === "coordenador" || perfil === "diretor") && !novaVisita.codusuario) ||
                                            (!usarClienteTemporario && !novaVisita.id_cliente) ||
                                            (usarClienteTemporario && !novaVisita.nome_cliente_temp)
                                            ? "#ccc"
                                            : "#5856eb",
                                },
                            }}
                        >
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
