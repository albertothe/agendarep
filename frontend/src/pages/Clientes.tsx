import { Box, Typography, Table, TableBody, TableCell, TableHead, TableRow, TextField, LinearProgress, Button, Paper, Collapse, IconButton, TablePagination } from "@mui/material";
import { KeyboardArrowDown, KeyboardArrowUp } from "@mui/icons-material";
import axios from "axios";
import { useEffect, useState } from "react";

interface LinhaCliente {
    id_cliente: string;
    nome_cliente: string;
    id_grupo: string;
    nome_grupo: string;
    potencial_compra: number;
    valor_comprado: number;
}

export default function Clientes() {
    const [dados, setDados] = useState<LinhaCliente[]>([]);
    const [page, setPage] = useState(0);
    const rowsPerPage = 10;
    const [abertos, setAbertos] = useState<Record<string, boolean>>({});
    const token = localStorage.getItem("token");

    const carregar = async () => {
        const res = await axios.get("http://localhost:8501/clientes", {
            headers: { Authorization: `Bearer ${token}` },
        });
        setDados(res.data);
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
                    grupos: [],
                };
            }
            acc[linha.id_cliente].grupos.push({ ...linha, index });
            return acc;
        }, {})
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

    return (
        <Box>
            <Typography variant="h5" gutterBottom>Clientes</Typography>
            <Paper>
                <Table size="small">
                    <TableHead>
                        <TableRow>
                            <TableCell width="50"></TableCell>
                            <TableCell>Cliente</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {clientes.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage).map((c) => (
                            <>
                                <TableRow hover key={c.id_cliente} onClick={() => setAbertos({ ...abertos, [c.id_cliente]: !abertos[c.id_cliente] })}>
                                    <TableCell>
                                        <IconButton size="small">
                                            {abertos[c.id_cliente] ? <KeyboardArrowUp /> : <KeyboardArrowDown />}
                                        </IconButton>
                                    </TableCell>
                                    <TableCell>{c.nome}</TableCell>
                                </TableRow>
                                <TableRow>
                                    <TableCell style={{ paddingBottom: 0, paddingTop: 0 }} colSpan={2}>
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
                    count={clientes.length}
                    page={page}
                    onPageChange={handleChangePage}
                    rowsPerPage={rowsPerPage}
                    rowsPerPageOptions={[]}
                />
            </Paper>
        </Box>
    );
}
