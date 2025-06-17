import { Box, Typography, Table, TableBody, TableCell, TableHead, TableRow, TextField, LinearProgress, Button, Paper, Collapse, IconButton, TablePagination } from "@mui/material";
import { KeyboardArrowDown, KeyboardArrowUp } from "@mui/icons-material";
import axios from "axios";
import { useEffect, useState } from "react";

const formatarTelefone = (tel: string) => {
    const numeros = tel.replace(/\D/g, "");
    if (numeros.length === 11) {
        return numeros.replace(/(\d{2})(\d{5})(\d{4})/, "($1) $2-$3");
    }
    if (numeros.length === 10) {
        return numeros.replace(/(\d{2})(\d{4})(\d{4})/, "($1) $2-$3");
    }
    return tel;
};

interface LinhaCliente {
    id_cliente: string;
    nome_cliente: string;
    telefone: string;
    id_grupo: string;
    nome_grupo: string;
    potencial_compra: number;
    valor_comprado: number;
}

export default function Clientes() {
    const [dados, setDados] = useState<LinhaCliente[]>([]);
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [busca, setBusca] = useState("");
    const [abertos, setAbertos] = useState<Record<string, boolean>>({});
    const token = localStorage.getItem("token");

    const carregar = async () => {
        const res = await axios.get("http://localhost:8501/clientes", {
            headers: { Authorization: `Bearer ${token}` },
        });
        const convertidos = res.data.map((linha: any) => ({
            ...linha,
            potencial_compra: Number(linha.potencial_compra),
            valor_comprado: Number(linha.valor_comprado),
        }));
        setDados(convertidos);
    };

    useEffect(() => {
        carregar();
    }, []);

    const clientes = Object.values(
        dados.reduce((acc: any, linha, index) => {
            if (!acc[linha.id_cliente]) {
                acc[linha.id_cliente] = {
                    id_cliente: linha.id_cliente,
                    nome: linha.nome_cliente,
                    telefone: linha.telefone,
                    grupos: [],
                    totalPotencial: 0,
                    totalComprado: 0,
                };
            }
            acc[linha.id_cliente].grupos.push({ ...linha, index });
            acc[linha.id_cliente].totalPotencial += linha.potencial_compra;
            acc[linha.id_cliente].totalComprado += linha.valor_comprado;
            return acc;
        }, {})
    ) as any[];

    const clientesFiltrados = clientes.filter((c: any) =>
        c.nome.toLowerCase().includes(busca.toLowerCase()) ||
        formatarTelefone(c.telefone).includes(busca)
    );

    const handleChange = (index: number, valor: string) => {
        const novo = [...dados];
        novo[index].potencial_compra = Number(valor);
        setDados(novo);
    };

    const salvar = async (linha: LinhaCliente) => {
        await axios.put(
            `http://localhost:8501/clientes/${linha.id_cliente}/grupos/${linha.id_grupo}`,
            { potencial_compra: linha.potencial_compra },
            { headers: { Authorization: `Bearer ${token}` } }
        );
        carregar();
    };

    const handleChangePage = (_: unknown, newPage: number) => {
        setPage(newPage);
    };

    const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
        setRowsPerPage(parseInt(event.target.value, 10));
        setPage(0);
    };

    return (
        <Box>
            <Typography variant="h5" gutterBottom>Clientes</Typography>
            <TextField
                size="small"
                placeholder="Buscar"
                value={busca}
                onChange={(e) => setBusca(e.target.value)}
                sx={{ mb: 1 }}
            />
            <Paper>
                <Table size="small">
                    <TableHead>
                        <TableRow>
                            <TableCell width="50"></TableCell>
                            <TableCell>Cliente</TableCell>
                            <TableCell>Telefone</TableCell>
                            <TableCell align="right">Comprado</TableCell>
                            <TableCell align="right">Potencial</TableCell>
                            <TableCell width="150">Progresso</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {clientesFiltrados.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage).map((c: any) => (
                            <>
                                <TableRow hover key={c.id_cliente} onClick={() => setAbertos({ ...abertos, [c.id_cliente]: !abertos[c.id_cliente] })}>
                                    <TableCell>
                                        <IconButton size="small">
                                            {abertos[c.id_cliente] ? <KeyboardArrowUp /> : <KeyboardArrowDown />}
                                        </IconButton>
                                    </TableCell>
                                    <TableCell>{c.nome}</TableCell>
                                    <TableCell>{c.telefone}</TableCell>
                                    <TableCell align="right">{c.totalComprado.toFixed(2)}</TableCell>
                                    <TableCell align="right">{c.totalPotencial.toFixed(2)}</TableCell>
                                    <TableCell>
                                        <LinearProgress variant="determinate" value={c.totalPotencial ? (c.totalComprado / c.totalPotencial) * 100 : 0} />
                                    </TableCell>
                                </TableRow>
                                <TableRow>
                                    <TableCell style={{ paddingBottom: 0, paddingTop: 0 }} colSpan={6}>
                                        <Collapse in={abertos[c.id_cliente]} timeout="auto" unmountOnExit>
                                            <Table size="small" sx={{ mt: 1 }}>
                                                <TableHead>
                                                    <TableRow>
                                                        <TableCell>Grupo</TableCell>
                                                        <TableCell align="right">Comprado</TableCell>
                                                        <TableCell align="right">Potencial</TableCell>
                                                        <TableCell width="150">Progresso</TableCell>
                                                        <TableCell></TableCell>
                                                    </TableRow>
                                                </TableHead>
                                                <TableBody>
                                                    {c.grupos.map((linha: any) => (
                                                        <TableRow key={`${linha.id_cliente}-${linha.id_grupo}`}>
                                                            <TableCell>{linha.nome_grupo}</TableCell>
                                                            <TableCell align="right">{linha.valor_comprado}</TableCell>
                                                            <TableCell align="right">
                                                                <TextField
                                                                    size="small"
                                                                    type="number"
                                                                    value={linha.potencial_compra}
                                                                    onChange={(e) => handleChange(linha.index, e.target.value)}
                                                                />
                                                            </TableCell>
                                                            <TableCell>
                                                                <LinearProgress variant="determinate" value={linha.potencial_compra ? (linha.valor_comprado / linha.potencial_compra) * 100 : 0} />
                                                            </TableCell>
                                                            <TableCell>
                                                                <Button size="small" variant="contained" onClick={() => salvar(linha)}>Salvar</Button>
                                                            </TableCell>
                                                        </TableRow>
                                                    ))}
                                                </TableBody>
                                            </Table>
                                        </Collapse>
                                    </TableCell>
                                </TableRow>
                            </>
                        ))}
                    </TableBody>
                </Table>
                <TablePagination
                    component="div"
                    count={clientesFiltrados.length}
                    page={page}
                    onPageChange={handleChangePage}
                    rowsPerPage={rowsPerPage}
                    onRowsPerPageChange={handleChangeRowsPerPage}
                    rowsPerPageOptions={[5, 10, 20]}
                />
            </Paper>
        </Box>
    );
}
