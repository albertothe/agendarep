import { Box, Paper, Typography } from "@mui/material";
import axios from "axios";
import dayjs from "dayjs";
import { useEffect, useState } from "react";

export default function Dashboard() {
    const [clientes, setClientes] = useState<any[]>([]);
    const [visitas, setVisitas] = useState<any[]>([]);
    const [potencialTotal, setPotencialTotal] = useState(0);
    const token = localStorage.getItem("token");

    const carregar = async () => {
        const resClientes = await axios.get("http://localhost:8501/clientes", {
            headers: { Authorization: `Bearer ${token}` },
        });
        const dadosClientes = resClientes.data.map((l: any) => ({
            ...l,
            potencial_compra: Number(l.potencial_compra),
        }));
        setClientes(dadosClientes);
        setPotencialTotal(
            dadosClientes.reduce((s: number, c: any) => s + c.potencial_compra, 0)
        );

        const inicio = dayjs().startOf("week").format("YYYY-MM-DD");
        const fim = dayjs().endOf("week").format("YYYY-MM-DD");
        const resVisitas = await axios.get("http://localhost:8501/visitas", {
            params: { inicio, fim },
            headers: { Authorization: `Bearer ${token}` },
        });
        setVisitas(resVisitas.data);
    };

    useEffect(() => {
        carregar();
    }, []);

    const qtdClientes = Array.from(
        new Set(clientes.map((c: any) => c.id_cliente))
    ).length;

    return (
        <Box>
            <Typography variant="h4" gutterBottom>
                Painel Geral
            </Typography>

            <Box display="flex" flexDirection={{ xs: 'column', md: 'row' }} gap={3}>
                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Typography variant="h6">Clientes Ativos</Typography>
                    <Typography variant="h4" color="primary">{qtdClientes}</Typography>
                </Paper>

                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Typography variant="h6">Visitas na Semana</Typography>
                    <Typography variant="h4" color="primary">{visitas.length}</Typography>
                </Paper>

                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Typography variant="h6">Potencial Total de Compra</Typography>
                    <Typography variant="h4" color="primary">{potencialTotal.toFixed(2)}</Typography>
                </Paper>
            </Box>

            <Box mt={4}>
                <Typography variant="body1" color="textSecondary">
                    Em breve: sugestões de visitas, agenda e relatórios.
                </Typography>
            </Box>
        </Box>
    );
}
