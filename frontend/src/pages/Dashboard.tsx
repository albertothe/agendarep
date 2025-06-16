import { Box, Paper, Typography } from "@mui/material";

export default function Dashboard() {
    return (
        <Box>
            <Typography variant="h4" gutterBottom>
                Painel Geral
            </Typography>

            <Box display="flex" flexDirection={{ xs: 'column', md: 'row' }} gap={3}>
                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Typography variant="h6">Clientes Ativos</Typography>
                    <Typography variant="h4" color="primary">--</Typography>
                </Paper>

                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Typography variant="h6">Visitas na Semana</Typography>
                    <Typography variant="h4" color="primary">--</Typography>
                </Paper>

                <Paper elevation={3} sx={{ p: 2, flex: 1 }}>
                    <Typography variant="h6">Potencial Total de Compra</Typography>
                    <Typography variant="h4" color="primary">--</Typography>
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
