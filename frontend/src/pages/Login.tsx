"use client"

import type React from "react"

import { useState, useContext, useEffect } from "react"
import { useNavigate } from "react-router-dom"
import {
    Container,
    TextField,
    Button,
    Typography,
    Paper,
    Box,
    Alert,
    InputAdornment,
    IconButton,
    CircularProgress,
    FormControlLabel,
    Checkbox,
} from "@mui/material"
import { Visibility, VisibilityOff, Person, Lock, Link as LinkIcon } from "@mui/icons-material"
import { api } from "../services/api"
import { AuthContext } from "../context/AuthContext"

export default function Login() {
    const [login, setLogin] = useState("")
    const [senha, setSenha] = useState("")
    const [erro, setErro] = useState("")
    const [carregando, setCarregando] = useState(false)
    const [mostrarSenha, setMostrarSenha] = useState(false)
    const [lembrarUsuario, setLembrarUsuario] = useState(false)
    const navigate = useNavigate()
    const { setToken } = useContext(AuthContext)

    // Carregar usuário salvo ao inicializar
    useEffect(() => {
        const usuarioSalvo = localStorage.getItem("usuarioSalvo")
        if (usuarioSalvo) {
            setLogin(usuarioSalvo)
            setLembrarUsuario(true)
        }
    }, [])

    const handleLogin = async () => {
        if (!login.trim() || !senha.trim()) {
            setErro("Por favor, preencha todos os campos.")
            return
        }

        console.log("Tentando login com:", login, senha)
        try {
            setCarregando(true)
            setErro("")

            const response = await api.post("/auth/login", { login, senha })

            // Salvar ou remover usuário baseado na checkbox
            if (lembrarUsuario) {
                localStorage.setItem("usuarioSalvo", login)
            } else {
                localStorage.removeItem("usuarioSalvo")
            }

            setToken(response.data.token)
            navigate("/dashboard")
        } catch (err: any) {
            console.error("Erro no login:", err)
            setErro(err.response?.data?.message || "Usuário ou senha inválidos.")
        } finally {
            setCarregando(false)
        }
    }

    const handleKeyPress = (event: React.KeyboardEvent) => {
        if (event.key === "Enter") {
            handleLogin()
        }
    }

    const handleLembrarChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        const checked = event.target.checked
        setLembrarUsuario(checked)

        // Se desmarcou, remove o usuário salvo imediatamente
        if (!checked) {
            localStorage.removeItem("usuarioSalvo")
        }
    }

    return (
        <Box
            sx={{
                minHeight: "100vh",
                bgcolor: "#f5f6fa",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                p: 2,
            }}
        >
            <Container maxWidth="sm">
                <Paper
                    elevation={0}
                    sx={{
                        p: 4,
                        borderRadius: 3,
                        border: "1px solid #e5e7eb",
                        bgcolor: "white",
                        boxShadow: "0 4px 6px -1px rgba(0, 0, 0, 0.1)",
                    }}
                >
                    {/* Header */}
                    <Box sx={{ textAlign: "center", mb: 4 }}>
                        <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", mb: 2 }}>
                            <LinkIcon sx={{ color: "#4285f4", mr: 1, fontSize: 32 }} />
                            <Typography
                                variant="h4"
                                sx={{
                                    fontWeight: 600,
                                    color: "#4285f4",
                                    fontSize: "1.8rem",
                                }}
                            >
                                AgendaRep
                            </Typography>
                        </Box>
                        <Typography variant="h5" sx={{ fontWeight: 600, color: "#1f2937", mb: 1 }}>
                            Bem-vindo de volta
                        </Typography>
                        <Typography variant="body1" color="text.secondary">
                            Faça login para acessar sua agenda de visitas
                        </Typography>
                    </Box>

                    {/* Formulário */}
                    <Box component="form" onSubmit={(e) => e.preventDefault()}>
                        {/* Campo Usuário */}
                        <TextField
                            fullWidth
                            label="Usuário"
                            value={login}
                            onChange={(e) => setLogin(e.target.value)}
                            onKeyPress={handleKeyPress}
                            disabled={carregando}
                            sx={{ mb: 3 }}
                            InputProps={{
                                startAdornment: (
                                    <InputAdornment position="start">
                                        <Person sx={{ color: "text.secondary" }} />
                                    </InputAdornment>
                                ),
                            }}
                        />

                        {/* Campo Senha */}
                        <TextField
                            fullWidth
                            label="Senha"
                            type={mostrarSenha ? "text" : "password"}
                            value={senha}
                            onChange={(e) => setSenha(e.target.value)}
                            onKeyPress={handleKeyPress}
                            disabled={carregando}
                            sx={{ mb: 2 }}
                            InputProps={{
                                startAdornment: (
                                    <InputAdornment position="start">
                                        <Lock sx={{ color: "text.secondary" }} />
                                    </InputAdornment>
                                ),
                                endAdornment: (
                                    <InputAdornment position="end">
                                        <IconButton onClick={() => setMostrarSenha(!mostrarSenha)} edge="end" disabled={carregando}>
                                            {mostrarSenha ? <VisibilityOff /> : <Visibility />}
                                        </IconButton>
                                    </InputAdornment>
                                ),
                            }}
                        />

                        {/* Checkbox Lembrar Usuário */}
                        <FormControlLabel
                            control={
                                <Checkbox
                                    checked={lembrarUsuario}
                                    onChange={handleLembrarChange}
                                    disabled={carregando}
                                    sx={{
                                        color: "#4285f4",
                                        "&.Mui-checked": {
                                            color: "#4285f4",
                                        },
                                    }}
                                />
                            }
                            label={
                                <Typography variant="body2" color="text.secondary">
                                    Lembrar usuário
                                </Typography>
                            }
                            sx={{ mb: 3 }}
                        />

                        {/* Mensagem de erro */}
                        {erro && (
                            <Alert severity="error" sx={{ mb: 3 }}>
                                {erro}
                            </Alert>
                        )}

                        {/* Botão de login */}
                        <Button
                            fullWidth
                            variant="contained"
                            onClick={handleLogin}
                            disabled={carregando || !login.trim() || !senha.trim()}
                            sx={{
                                py: 1.5,
                                fontSize: "1rem",
                                fontWeight: 600,
                                bgcolor: "#4285f4",
                                "&:hover": {
                                    bgcolor: "#3367d6",
                                },
                                "&:disabled": {
                                    bgcolor: "#e5e7eb",
                                    color: "#9ca3af",
                                },
                            }}
                        >
                            {carregando ? (
                                <>
                                    <CircularProgress size={20} sx={{ mr: 1, color: "white" }} />
                                    Entrando...
                                </>
                            ) : (
                                "Entrar"
                            )}
                        </Button>
                    </Box>

                    {/* Footer */}
                    <Box sx={{ mt: 4, textAlign: "center" }}>
                        <Typography variant="body2" color="text.secondary">
                            Sistema de Gestão de Visitas Comerciais
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: "block" }}>
                            © 2025 Durafix. Todos os direitos reservados.
                        </Typography>
                    </Box>
                </Paper>
            </Container>
        </Box>
    )
}
