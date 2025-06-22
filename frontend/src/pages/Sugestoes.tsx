import { Box, Typography, Card, CardContent, Paper, Avatar } from "@mui/material"
import { Lightbulb, Analytics, Schedule, TrendingUp, Construction } from "@mui/icons-material"

export default function Sugestoes() {
    const plannedFeatures = [
        {
            icon: <Analytics sx={{ color: "#6366f1" }} />,
            title: "Análise de Padrões",
            description: "Identificação de clientes com maior potencial de vendas baseada em histórico",
        },
        {
            icon: <Schedule sx={{ color: "#6366f1" }} />,
            title: "Otimização de Rotas",
            description: "Sugestões inteligentes de visitas organizadas por proximidade geográfica",
        },
        {
            icon: <TrendingUp sx={{ color: "#6366f1" }} />,
            title: "Priorização Inteligente",
            description: "Ranking automático baseado em histórico de vendas e comportamento do cliente",
        },
    ]

    return (
        <Box sx={{ p: 3 }}>
            {/* Header Section */}
            <Box sx={{ mb: 4, textAlign: "center" }}>
                <Typography
                    variant="h4"
                    component="h1"
                    gutterBottom
                    sx={{
                        fontWeight: "bold",
                        color: "#1f2937",
                        mb: 2,
                    }}
                >
                    Sugestões de Visita
                </Typography>
                <Typography
                    variant="h6"
                    color="text.secondary"
                    sx={{
                        maxWidth: 600,
                        mx: "auto",
                        lineHeight: 1.6,
                        color: "#6b7280",
                    }}
                >
                    Receba sugestões inteligentes de clientes para visitar baseadas no histórico e potencial de vendas.
                </Typography>
            </Box>

            {/* Main Content */}
            <Box sx={{ display: "flex", justifyContent: "center", mb: 4 }}>
                <Paper
                    elevation={0}
                    sx={{
                        p: 4,
                        textAlign: "center",
                        backgroundColor: "#f8fafc",
                        border: "1px solid #e2e8f0",
                        maxWidth: 600,
                        width: "100%",
                    }}
                >
                    {/* Icon */}
                    <Avatar
                        sx={{
                            width: 80,
                            height: 80,
                            mx: "auto",
                            mb: 3,
                            backgroundColor: "rgba(99, 102, 241, 0.1)",
                        }}
                    >
                        <Lightbulb sx={{ fontSize: 40, color: "#6366f1" }} />
                    </Avatar>

                    {/* Development Status */}
                    <Typography
                        variant="h5"
                        component="h2"
                        gutterBottom
                        sx={{
                            fontWeight: "bold",
                            color: "#1f2937",
                            mb: 2,
                        }}
                    >
                        Em Desenvolvimento
                    </Typography>

                    <Typography
                        variant="body1"
                        color="text.secondary"
                        sx={{
                            mb: 3,
                            color: "#6b7280",
                            lineHeight: 1.6,
                        }}
                    >
                        Esta funcionalidade está sendo desenvolvida e estará disponível em breve.
                    </Typography>

                    {/* Under Construction Icon */}
                    <Construction sx={{ fontSize: 48, color: "#f59e0b", opacity: 0.7 }} />
                </Paper>
            </Box>

            {/* Planned Features */}
            <Box sx={{ mb: 4 }}>
                <Typography
                    variant="h5"
                    component="h2"
                    gutterBottom
                    sx={{
                        fontWeight: "bold",
                        color: "#1f2937",
                        textAlign: "center",
                        mb: 3,
                    }}
                >
                    Funcionalidades Planejadas
                </Typography>

                <Box
                    sx={{
                        display: "flex",
                        flexDirection: { xs: "column", md: "row" },
                        gap: 3,
                        justifyContent: "center",
                    }}
                >
                    {plannedFeatures.map((feature, index) => (
                        <Card
                            key={index}
                            elevation={0}
                            sx={{
                                flex: 1,
                                maxWidth: { md: 350 },
                                border: "1px solid #e2e8f0",
                                transition: "all 0.3s ease",
                                "&:hover": {
                                    transform: "translateY(-4px)",
                                    boxShadow: "0 10px 25px rgba(0,0,0,0.1)",
                                    borderColor: "#6366f1",
                                },
                            }}
                        >
                            <CardContent sx={{ p: 3 }}>
                                <Box sx={{ display: "flex", alignItems: "flex-start", mb: 2 }}>
                                    <Avatar
                                        sx={{
                                            width: 48,
                                            height: 48,
                                            backgroundColor: "rgba(99, 102, 241, 0.1)",
                                            mr: 2,
                                        }}
                                    >
                                        {feature.icon}
                                    </Avatar>
                                    <Box sx={{ flex: 1 }}>
                                        <Typography
                                            variant="h6"
                                            component="h3"
                                            gutterBottom
                                            sx={{
                                                fontWeight: "bold",
                                                color: "#1f2937",
                                            }}
                                        >
                                            {feature.title}
                                        </Typography>
                                        <Typography
                                            variant="body2"
                                            color="text.secondary"
                                            sx={{
                                                color: "#6b7280",
                                                lineHeight: 1.5,
                                            }}
                                        >
                                            {feature.description}
                                        </Typography>
                                    </Box>
                                </Box>
                            </CardContent>
                        </Card>
                    ))}
                </Box>
            </Box>

            {/* Additional Info */}
            <Box sx={{ display: "flex", justifyContent: "center" }}>
                <Paper
                    elevation={0}
                    sx={{
                        p: 3,
                        backgroundColor: "rgba(99, 102, 241, 0.05)",
                        border: "1px solid rgba(99, 102, 241, 0.2)",
                        textAlign: "center",
                        maxWidth: 800,
                        width: "100%",
                    }}
                >
                    <Typography
                        variant="h6"
                        gutterBottom
                        sx={{
                            color: "#6366f1",
                            fontWeight: "bold",
                        }}
                    >
                        🚀 Novidades em Breve
                    </Typography>
                    <Typography
                        variant="body1"
                        sx={{
                            color: "#4f46e5",
                            lineHeight: 1.6,
                        }}
                    >
                        Estamos trabalhando para implementar algoritmos de machine learning que irão analisar seus dados históricos
                        e sugerir as melhores oportunidades de visita.
                    </Typography>
                </Paper>
            </Box>
        </Box>
    )
}
