import { Box, Paper, Typography, TextField, MenuItem } from "@mui/material";
import { People, CalendarMonth, MonetizationOn } from "@mui/icons-material";
import axios from "axios";
import dayjs from "dayjs";
import { useEffect, useState } from "react";
import { jwtDecode } from "jwt-decode";

export default function Dashboard() {
    const [clientes, setClientes] = useState<any[]>([]);
    const [visitas, setVisitas] = useState<any[]>([]);
    const [potencialTotal, setPotencialTotal] = useState(0);
    const [representantes, setRepresentantes] = useState<any[]>([]);
    const [repSelecionado, setRepSelecionado] = useState("");
    const [perfil, setPerfil] = useState("");
    const token = localStorage.getItem("token");

    const carregar = async () => {
        const params: any = {};
        if (repSelecionado) params.codusuario = repSelecionado;
        const resClientes = await axios.get("http://localhost:8501/clientes", {
            params,
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
        const paramsVisitas: any = { inicio, fim };
        if (repSelecionado) paramsVisitas.codusuario = repSelecionado;
        const resVisitas = await axios.get("http://localhost:8501/visitas", {
            params: paramsVisitas,
            headers: { Authorization: `Bearer ${token}` },
        });
        setVisitas(resVisitas.data);
    };

    const carregarRepresentantes = async () => {
        const res = await axios.get(
            "http://localhost:8501/usuarios/representantes",
            { headers: { Authorization: `Bearer ${token}` } }
        );
        setRepresentantes(res.data);
    };

    useEffect(() => {
        if (token) {
            const data: any = jwtDecode(token);
            setPerfil(data.perfil);
            if (data.perfil === "coordenador" || data.perfil === "diretor") {
                carregarRepresentantes();
            }
        }
    }, [token]);

    useEffect(() => {
        if (token) {
            carregar();
        }
    }, [token, repSelecionado]);

    const qtdClientes = Array.from(
        new Set(clientes.map((c: any) => c.id_cliente))
    ).length;

    const formatarMoeda = (valor: number) =>
        valor.toLocaleString("pt-BR", {
            style: "currency",
            currency: "BRL",
        });

    const atividades = visitas
        .slice()
        .sort((a, b) =>
            dayjs(`${b.data} ${b.hora}`).diff(dayjs(`${a.data} ${a.hora}`))
        )
        .map((v) => {
            const nome = v.nome_cliente || v.nome_cliente_temp;
            const dataFormatada = dayjs(v.data).format("DD/MM/YYYY");
            return v.confirmado
                ? `Visita confirmada com ${nome} em ${dataFormatada}`
                : `Visita agendada com ${nome} em ${dataFormatada}`;
        });

    return (
        <Box>
            <Typography variant="h5" gutterBottom>
                Painel Geral
            </Typography>
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
                            <MenuItem key={r.codusuario} value={r.codusuario}>
                                {r.nome}
                            </MenuItem>
                        ))}
                    </TextField>
                </Box>
            )}

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
