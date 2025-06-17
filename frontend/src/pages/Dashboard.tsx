import { Box, Paper, Typography } from "@mui/material";
import { People, CalendarMonth, MonetizationOn } from "@mui/icons-material";
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

    const formatarMoeda = (valor: number) =>
        valor.toLocaleString("pt-BR", {
            style: "currency",
            currency: "BRL",
        });

    const atividades = [
        "Visita confirmada com Innovatech Solutions em 28/07/2024",
        "Visita agendada com New Lead Co. em 30/07/2024",
    ];

    return (
        <Box>
            <Typography variant="h5" gutterBottom>
                Painel Geral
            </Typography>

            <Box display="flex" flexDirection={{ xs: "column", md: "row" }} gap={3}>
                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Box display="flex" alignItems="center" gap={1}>
                        <People />
                        <Typography variant="h6">Clientes Ativos</Typography>
                    </Box>
                    <Typography variant="h4" color="primary">{qtdClientes}</Typography>
                </Paper>

                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Box display="flex" alignItems="center" gap={1}>
                        <CalendarMonth />
                        <Typography variant="h6">Visitas na Semana</Typography>
                    </Box>
                    <Typography variant="h4" color="primary">{visitas.length}</Typography>
                </Paper>

                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Box display="flex" alignItems="center" gap={1}>
                        <MonetizationOn />
                        <Typography variant="h6">Potencial Total de Compra</Typography>
                    </Box>
                    <Typography variant="h4" color="primary">{formatarMoeda(potencialTotal)}</Typography>
                </Paper>
            </Box>

            <Box mt={4}>
                <Typography variant="h6" gutterBottom>Atividade Recente</Typography>
                <Paper sx={{ p: 2 }}>
                    {atividades.map((a) => (
                        <Typography key={a}>{a}</Typography>
                    ))}
                </Paper>
            </Box>
        </Box>
    );
}
