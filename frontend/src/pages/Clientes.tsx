import { Box, Typography, Table, TableBody, TableCell, TableHead, TableRow, TextField, LinearProgress, Button, Paper } from "@mui/material";
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

    return (
        <Box>
            <Typography variant="h5" gutterBottom>Clientes</Typography>
            <Paper>
                <Table size="small">
                    <TableHead>
                        <TableRow>
                            <TableCell>Cliente</TableCell>
                            <TableCell>Grupo</TableCell>
                            <TableCell align="right">Comprado</TableCell>
                            <TableCell align="right">Potencial</TableCell>
                            <TableCell width="150">Progresso</TableCell>
                            <TableCell></TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {dados.map((linha, idx) => (
                            <TableRow key={`${linha.id_cliente}-${linha.id_grupo}`}>
                                <TableCell>{linha.nome_cliente}</TableCell>
                                <TableCell>{linha.nome_grupo}</TableCell>
                                <TableCell align="right">{linha.valor_comprado}</TableCell>
                                <TableCell align="right">
                                    <TextField
                                        size="small"
                                        type="number"
                                        value={linha.potencial_compra}
                                        onChange={(e) => handleChange(idx, e.target.value)}
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
            </Paper>
        </Box>
    );
}
