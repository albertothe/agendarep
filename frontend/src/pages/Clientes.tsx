"use client"

import type React from "react"

import {
    Box,
    Typography,
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableRow,
    TextField,
    Button,
    Paper,
    IconButton,
    TablePagination,
    InputAdornment,
    Menu,
    MenuItem,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Slider,
    Alert,
    Divider,
    Chip,
    List,
    ListItem,
    CircularProgress,
} from "@mui/material"
import { Search, MoreHoriz, Visibility, Edit, Person, MonetizationOn, TrendingUp } from "@mui/icons-material"
import { useState, useEffect } from "react"
import { jwtDecode } from "jwt-decode"
import { useClientes } from "../hooks/useClientes"
import { formatarTelefone, formatarMoeda } from "../utils/formatters"

// Interfaces
interface LinhaCliente {
    id_cliente: string
    nome_cliente: string
    telefone: string | null
    id_grupo: string
    nome_grupo: string
    potencial_compra: number
    valor_comprado: number
}

interface ClienteAgrupado {
    id_cliente: string
    nome: string
    telefone: string | null
    grupos: LinhaCliente[]
    totalPotencial: number
    totalComprado: number
    progresso: number
}

interface GrupoEdicao {
    id_grupo: string
    nome_grupo: string
    potencial_compra: number
    valor_original: number
}

interface Usuario {
    perfil: string
    codusuario?: string
}

export default function Clientes() {
    const [page, setPage] = useState(0)
    const [rowsPerPage, setRowsPerPage] = useState(15)
    const [busca, setBusca] = useState("")
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
    const [clienteSelecionado, setClienteSelecionado] = useState<ClienteAgrupado | null>(null)
    const [modalAberto, setModalAberto] = useState(false)
    const [modalDetalhesAberto, setModalDetalhesAberto] = useState(false)
    const [gruposEdicao, setGruposEdicao] = useState<GrupoEdicao[]>([])
    const [novoGrupo, setNovoGrupo] = useState("")
    const [usuario, setUsuario] = useState<Usuario | null>(null)
    const [salvando, setSalvando] = useState(false)

    const { dados, representantes, repSelecionado, setRepSelecionado, loading, error, salvarPotencial, recarregar } =
        useClientes()

    // Decodificar token para obter perfil do usuário
    useEffect(() => {
        const token = localStorage.getItem("token")
        if (token) {
            try {
                const decoded = jwtDecode<any>(token)
                setUsuario({
                    perfil: decoded.perfil,
                    codusuario: decoded.codusuario,
                })
            } catch (error) {
                console.error("Erro ao decodificar token:", error)
            }
        }
    }, [])

    // Agrupar clientes
    const clientes = dados.reduce((acc: any, linha) => {
        if (!acc[linha.id_cliente]) {
            acc[linha.id_cliente] = {
                id_cliente: linha.id_cliente,
                nome: linha.nome_cliente,
                telefone: linha.telefone,
                grupos: [],
                totalPotencial: 0,
                totalComprado: 0,
                progresso: 0,
            }
        }
        acc[linha.id_cliente].grupos.push(linha)
        acc[linha.id_cliente].totalPotencial += linha.potencial_compra
        acc[linha.id_cliente].totalComprado += linha.valor_comprado
        return acc
    }, {})

    const clientesArray = Object.values(clientes).map((cliente: any) => ({
        ...cliente,
        progresso: cliente.totalPotencial > 0 ? Math.round((cliente.totalComprado / cliente.totalPotencial) * 100) : 0,
    })) as ClienteAgrupado[]

    // Filtrar e ordenar clientes por potencial (maior para menor)
    const clientesFiltrados = clientesArray
        .filter((c) => c.nome.toLowerCase().includes(busca.toLowerCase()))
        .sort((a, b) => b.totalPotencial - a.totalPotencial)

    // Calcular totalizadores
    const totalizadores = clientesFiltrados.reduce(
        (acc, cliente) => ({
            totalClientes: acc.totalClientes + 1,
            totalPotencial: acc.totalPotencial + cliente.totalPotencial,
            totalComprado: acc.totalComprado + cliente.totalComprado,
        }),
        { totalClientes: 0, totalPotencial: 0, totalComprado: 0 },
    )

    // Remover esta linha completamente:
    // totalizadores.mediaProgresso = totalizadores.totalClientes > 0 ? Math.round(totalizadores.mediaProgresso / totalizadores.totalClientes) : 0

    // Handlers do menu
    const handleMenuClick = (event: React.MouseEvent<HTMLElement>, cliente: ClienteAgrupado) => {
        event.stopPropagation()
        setAnchorEl(event.currentTarget)
        setClienteSelecionado(cliente)
    }

    const handleMenuClose = () => {
        setAnchorEl(null)
        setClienteSelecionado(null)
    }

    const fecharMenu = () => {
        setAnchorEl(null)
    }

    const handleVerDetalhes = () => {
        setModalDetalhesAberto(true)
        fecharMenu()
    }

    const handleEditarPotencial = () => {
        if (clienteSelecionado) {
            setGruposEdicao(
                clienteSelecionado.grupos.map((grupo) => ({
                    id_grupo: grupo.id_grupo,
                    nome_grupo: grupo.nome_grupo,
                    potencial_compra: grupo.potencial_compra,
                    valor_original: grupo.potencial_compra,
                })),
            )
            setModalAberto(true)
        }
        fecharMenu()
    }

    const handleFecharModal = () => {
        setModalAberto(false)
        setClienteSelecionado(null)
        setGruposEdicao([])
        setNovoGrupo("")
        setSalvando(false)
    }

    const handleFecharModalDetalhes = () => {
        setModalDetalhesAberto(false)
        setClienteSelecionado(null)
    }

    const handleSliderChange = (index: number, valor: number) => {
        const novosGrupos = [...gruposEdicao]
        novosGrupos[index].potencial_compra = valor
        setGruposEdicao(novosGrupos)
    }

    const handleSalvarPotencial = async () => {
        if (!clienteSelecionado) return

        try {
            setSalvando(true)

            // Salvar cada grupo modificado
            for (const grupo of gruposEdicao) {
                if (grupo.potencial_compra !== grupo.valor_original) {
                    console.log("Salvando grupo:", {
                        clienteId: clienteSelecionado.id_cliente,
                        grupoId: grupo.id_grupo,
                        potencial: grupo.potencial_compra,
                    })

                    await salvarPotencial(clienteSelecionado.id_cliente, grupo.id_grupo, grupo.potencial_compra)
                }
            }

            // Recarregar dados
            await recarregar()

            // Fechar modal
            handleFecharModal()

            console.log("Potencial salvo com sucesso!")
        } catch (error) {
            console.error("Erro ao salvar potencial:", error)
            alert("Erro ao salvar potencial. Tente novamente.")
        } finally {
            setSalvando(false)
        }
    }

    const totalPotencialCalculado = gruposEdicao.reduce((acc, grupo) => acc + grupo.potencial_compra, 0)

    return (
        <Box sx={{ p: 3 }}>
            {/* Header */}
            <Box sx={{ mb: 4 }}>
                <Box sx={{ display: "flex", alignItems: "center", mb: 1 }}>
                    <Person sx={{ color: "#6366f1", mr: 1, fontSize: 28 }} />
                    <Typography variant="h4" sx={{ fontWeight: 600, color: "#1f2937" }}>
                        Gestão de Clientes
                    </Typography>
                </Box>
                <Typography variant="body1" color="text.secondary">
                    Visualize, edite e gerencie as informações e o potencial de vendas de seus clientes.
                </Typography>
            </Box>

            {/* Controles */}
            <Box sx={{ display: "flex", gap: 2, mb: 3, flexWrap: "wrap" }}>
                {/* Campo de busca */}
                <TextField
                    placeholder="Buscar nome do cliente..."
                    value={busca}
                    onChange={(e) => setBusca(e.target.value)}
                    sx={{ flex: 1, minWidth: 300 }}
                    InputProps={{
                        startAdornment: (
                            <InputAdornment position="start">
                                <Search sx={{ color: "text.secondary" }} />
                            </InputAdornment>
                        ),
                    }}
                />

                {/* Filtro de representantes */}
                {(usuario?.perfil === "coordenador" || usuario?.perfil === "diretor") && (
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
                )}
            </Box>

            {/* Totalizadores */}
            <Box
                sx={{
                    display: "flex",
                    gap: 2,
                    mb: 3,
                    flexWrap: "nowrap", // Força os cards a ficarem na mesma linha
                    "& > *": {
                        flex: "1 1 0", // Distribui igualmente o espaço
                        minWidth: 0, // Remove minWidth que estava forçando quebra
                    },
                }}
            >
                <Paper elevation={0} sx={{ border: "1px solid #e5e7eb", p: 1.5 }}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                        <Person sx={{ fontSize: 24, color: "#6366f1" }} />
                        <Box>
                            <Typography variant="h5" sx={{ fontWeight: 700, color: "#1f2937", lineHeight: 1 }}>
                                {totalizadores.totalClientes}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                                Total de Clientes
                            </Typography>
                        </Box>
                    </Box>
                </Paper>

                <Paper elevation={0} sx={{ border: "1px solid #e5e7eb", p: 1.5 }}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                        <MonetizationOn sx={{ fontSize: 24, color: "#f59e0b" }} />
                        <Box>
                            <Typography variant="h6" sx={{ fontWeight: 700, color: "#1f2937", lineHeight: 1 }}>
                                {formatarMoeda(totalizadores.totalPotencial)}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                                Potencial Total
                            </Typography>
                        </Box>
                    </Box>
                </Paper>

                <Paper elevation={0} sx={{ border: "1px solid #e5e7eb", p: 1.5 }}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                        <TrendingUp sx={{ fontSize: 24, color: "#10b981" }} />
                        <Box>
                            <Typography variant="h6" sx={{ fontWeight: 700, color: "#1f2937", lineHeight: 1 }}>
                                {formatarMoeda(totalizadores.totalComprado)}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ fontSize: "0.8rem" }}>
                                Total Comprado
                            </Typography>
                        </Box>
                    </Box>
                </Paper>
            </Box>

            {/* Tabela */}
            <Paper elevation={0} sx={{ border: "1px solid #e5e7eb" }}>
                <Table>
                    <TableHead>
                        <TableRow sx={{ bgcolor: "#f9fafb" }}>
                            <TableCell sx={{ fontWeight: 600, color: "#374151" }}>Nome</TableCell>
                            <TableCell sx={{ fontWeight: 600, color: "#374151" }}>Telefone</TableCell>
                            <TableCell sx={{ fontWeight: 600, color: "#374151" }} align="right">
                                Potencial Mensal
                            </TableCell>
                            <TableCell sx={{ fontWeight: 600, color: "#374151" }} align="right">
                                Comprado no Mês
                            </TableCell>
                            <TableCell sx={{ fontWeight: 600, color: "#374151" }} align="center">
                                Progresso
                            </TableCell>
                            <TableCell sx={{ fontWeight: 600, color: "#374151" }} align="center">
                                Ações
                            </TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {clientesFiltrados.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage).map((cliente) => (
                            <TableRow key={cliente.id_cliente} hover>
                                <TableCell>
                                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                        {cliente.nome}
                                    </Typography>
                                </TableCell>
                                <TableCell>
                                    <Typography variant="body2" color="text.secondary">
                                        {formatarTelefone(cliente.telefone)}
                                    </Typography>
                                </TableCell>
                                <TableCell align="right">
                                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                        {formatarMoeda(cliente.totalPotencial)}
                                    </Typography>
                                </TableCell>
                                <TableCell align="right">
                                    <Typography variant="body2" color="text.secondary">
                                        {formatarMoeda(cliente.totalComprado)}
                                    </Typography>
                                </TableCell>
                                <TableCell align="center">
                                    <Chip
                                        label={`${cliente.progresso}%`}
                                        size="small"
                                        sx={{
                                            bgcolor: cliente.progresso === 0 ? "#fef2f2" : "#dcfce7",
                                            color: cliente.progresso === 0 ? "#dc2626" : "#16a34a",
                                            fontWeight: 500,
                                        }}
                                    />
                                </TableCell>
                                <TableCell align="center">
                                    <IconButton
                                        size="small"
                                        onClick={(e) => handleMenuClick(e, cliente)}
                                        sx={{ color: "text.secondary" }}
                                    >
                                        <MoreHoriz />
                                    </IconButton>
                                </TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>

                <TablePagination
                    component="div"
                    count={clientesFiltrados.length}
                    page={page}
                    onPageChange={(_, newPage) => setPage(newPage)}
                    rowsPerPage={rowsPerPage}
                    onRowsPerPageChange={(e) => {
                        setRowsPerPage(Number.parseInt(e.target.value, 10))
                        setPage(0)
                    }}
                    rowsPerPageOptions={[15, 30, 50]}
                    labelRowsPerPage="Linhas por página:"
                />
            </Paper>

            {/* Menu de ações */}
            <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={handleMenuClose}>
                <MenuItem onClick={handleVerDetalhes}>
                    <Visibility sx={{ mr: 1, fontSize: 20 }} />
                    Ver Detalhes
                </MenuItem>
                <MenuItem onClick={handleEditarPotencial}>
                    <Edit sx={{ mr: 1, fontSize: 20 }} />
                    Editar Potencial
                </MenuItem>
            </Menu>

            {/* Modal Ver Detalhes */}
            <Dialog
                open={modalDetalhesAberto}
                onClose={handleFecharModalDetalhes}
                maxWidth="md"
                fullWidth
                PaperProps={{
                    sx: { borderRadius: 2 },
                }}
            >
                <DialogTitle sx={{ pb: 1 }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                        Detalhes do Cliente: {clienteSelecionado?.nome}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                        Visualize o potencial e compras por grupo de produtos
                    </Typography>
                </DialogTitle>

                <DialogContent sx={{ pt: 2 }}>
                    {/* Resumo geral */}
                    <Box sx={{ mb: 3, p: 2, bgcolor: "#f8fafc", borderRadius: 1 }}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                            Resumo Geral
                        </Typography>
                        <Box sx={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                            <Box>
                                <Typography variant="body2" color="text.secondary">
                                    Potencial Total
                                </Typography>
                                <Typography variant="h6" sx={{ color: "#3b82f6", fontWeight: 600 }}>
                                    {formatarMoeda(clienteSelecionado?.totalPotencial || 0)}
                                </Typography>
                            </Box>
                            <Box>
                                <Typography variant="body2" color="text.secondary">
                                    Comprado Total
                                </Typography>
                                <Typography variant="h6" sx={{ color: "#10b981", fontWeight: 600 }}>
                                    {formatarMoeda(clienteSelecionado?.totalComprado || 0)}
                                </Typography>
                            </Box>
                            <Box>
                                <Typography variant="body2" color="text.secondary">
                                    Progresso
                                </Typography>
                                <Typography variant="h6" sx={{ color: "#f59e0b", fontWeight: 600 }}>
                                    {clienteSelecionado?.progresso || 0}%
                                </Typography>
                            </Box>
                        </Box>
                    </Box>

                    <Divider sx={{ mb: 3 }} />

                    {/* Detalhes por grupo */}
                    <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 600 }}>
                        Detalhes por Grupo de Produtos
                    </Typography>

                    <List sx={{ p: 0 }}>
                        {clienteSelecionado?.grupos.map((grupo, index) => (
                            <ListItem
                                key={grupo.id_grupo}
                                sx={{
                                    mb: 2,
                                    p: 2,
                                    border: "1px solid #e5e7eb",
                                    borderRadius: 1,
                                    flexDirection: "column",
                                    alignItems: "stretch",
                                }}
                            >
                                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
                                    <Typography variant="body1" sx={{ fontWeight: 600 }}>
                                        {grupo.nome_grupo}
                                    </Typography>
                                    <Chip
                                        label={`${grupo.potencial_compra > 0 ? Math.round((grupo.valor_comprado / grupo.potencial_compra) * 100) : 0}%`}
                                        size="small"
                                        sx={{
                                            bgcolor: grupo.valor_comprado === 0 ? "#fef2f2" : "#dcfce7",
                                            color: grupo.valor_comprado === 0 ? "#dc2626" : "#16a34a",
                                            fontWeight: 500,
                                        }}
                                    />
                                </Box>

                                <Box sx={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                                    <Box sx={{ flex: 1, minWidth: 150 }}>
                                        <Typography variant="caption" color="text.secondary">
                                            Potencial Mensal
                                        </Typography>
                                        <Typography variant="body1" sx={{ fontWeight: 600, color: "#3b82f6" }}>
                                            {formatarMoeda(grupo.potencial_compra)}
                                        </Typography>
                                    </Box>
                                    <Box sx={{ flex: 1, minWidth: 150 }}>
                                        <Typography variant="caption" color="text.secondary">
                                            Comprado no Mês
                                        </Typography>
                                        <Typography variant="body1" sx={{ fontWeight: 600, color: "#10b981" }}>
                                            {formatarMoeda(grupo.valor_comprado)}
                                        </Typography>
                                    </Box>
                                    <Box sx={{ flex: 1, minWidth: 150 }}>
                                        <Typography variant="caption" color="text.secondary">
                                            Diferença
                                        </Typography>
                                        <Typography
                                            variant="body1"
                                            sx={{
                                                fontWeight: 600,
                                                color: grupo.potencial_compra - grupo.valor_comprado >= 0 ? "#f59e0b" : "#ef4444",
                                            }}
                                        >
                                            {formatarMoeda(grupo.potencial_compra - grupo.valor_comprado)}
                                        </Typography>
                                    </Box>
                                </Box>
                            </ListItem>
                        ))}
                    </List>
                </DialogContent>

                <DialogActions sx={{ p: 3, pt: 1 }}>
                    <Button onClick={handleFecharModalDetalhes} variant="contained">
                        Fechar
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Modal de edição */}
            <Dialog
                open={modalAberto}
                onClose={handleFecharModal}
                maxWidth="sm"
                fullWidth
                PaperProps={{
                    sx: { borderRadius: 2 },
                }}
            >
                <DialogTitle sx={{ pb: 1 }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                        Editar Potencial de Compra para {clienteSelecionado?.nome}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                        Ajuste o potencial de compra mensal por grupo de produtos. O potencial geral é a soma dos grupos.
                    </Typography>
                </DialogTitle>

                <DialogContent sx={{ pt: 2 }}>
                    {/* Informação sobre compras */}
                    <Alert severity="info" sx={{ mb: 3 }}>
                        Total comprado por {clienteSelecionado?.nome} este mês:{" "}
                        {formatarMoeda(clienteSelecionado?.totalComprado || 0)}
                    </Alert>

                    {/* Potencial geral calculado */}
                    <Box sx={{ mb: 3, p: 2, bgcolor: "#f8fafc", borderRadius: 1 }}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                            Potencial Geral Mensal (Calculado)
                        </Typography>
                        <Typography variant="h5" sx={{ color: "#3b82f6", fontWeight: 600 }}>
                            {formatarMoeda(totalPotencialCalculado)}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                            Este valor é a soma dos potenciais de cada grupo de produtos.
                        </Typography>
                    </Box>

                    <Divider sx={{ mb: 3 }} />

                    {/* Grupos de produtos */}
                    <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 600 }}>
                        Potencial Mensal por Grupo de Produtos
                    </Typography>

                    {gruposEdicao.map((grupo, index) => (
                        <Box key={grupo.id_grupo} sx={{ mb: 3, p: 2, border: "1px solid #e5e7eb", borderRadius: 1 }}>
                            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
                                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                                    {grupo.nome_grupo}
                                </Typography>
                            </Box>

                            <Box sx={{ px: 1 }}>
                                <Slider
                                    value={grupo.potencial_compra}
                                    onChange={(_, value) => handleSliderChange(index, value as number)}
                                    min={0}
                                    max={500000}
                                    step={1000}
                                    sx={{ mb: 1 }}
                                />
                                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                                    <Typography variant="body2" color="text.secondary">
                                        R$ {grupo.potencial_compra.toLocaleString("pt-BR")}
                                    </Typography>
                                    <Typography variant="body1" sx={{ fontWeight: 600 }}>
                                        {formatarMoeda(grupo.potencial_compra)}
                                    </Typography>
                                </Box>
                            </Box>
                        </Box>
                    ))}

                    {/* Campo para novo grupo */}
                    <TextField
                        fullWidth
                        placeholder="Nome do novo grupo"
                        value={novoGrupo}
                        onChange={(e) => setNovoGrupo(e.target.value)}
                        sx={{ mt: 2 }}
                    />
                </DialogContent>

                <DialogActions sx={{ p: 3, pt: 1 }}>
                    <Button onClick={handleFecharModal} color="inherit" disabled={salvando}>
                        Cancelar
                    </Button>
                    <Button
                        onClick={handleSalvarPotencial}
                        variant="contained"
                        disabled={salvando}
                        sx={{
                            bgcolor: "#f97316",
                            "&:hover": { bgcolor: "#ea580c" },
                        }}
                    >
                        {salvando ? (
                            <>
                                <CircularProgress size={16} sx={{ mr: 1, color: "white" }} />
                                Salvando...
                            </>
                        ) : (
                            "Salvar Potencial"
                        )}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    )
}
