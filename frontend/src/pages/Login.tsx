import { useState, useContext } from "react";
import { useNavigate } from "react-router-dom";
import { Container, TextField, Button, Typography, Paper, Box } from "@mui/material";
import { api } from "../services/api";
import { AuthContext } from "../context/AuthContext";

export default function Login() {
    const [login, setLogin] = useState("");
    const [senha, setSenha] = useState("");
    const [erro, setErro] = useState("");
    const navigate = useNavigate();
    const { setToken } = useContext(AuthContext);

    const handleLogin = async () => {
        console.log("Tentando login com:", login, senha); // <- debug
        try {
            const response = await api.post("/auth/login", { login, senha });
            setToken(response.data.token);
            navigate("/dashboard");
        } catch (err) {
            setErro("Usuário ou senha inválidos.");
        }
    };

    return (
        <Container maxWidth="sm">
            <Paper elevation={3} sx={{ mt: 10, p: 4 }}>
                <Typography variant="h5">Login - AgendaRep</Typography>
                <TextField fullWidth label="Usuário" margin="normal" value={login} onChange={e => setLogin(e.target.value)} />
                <TextField fullWidth label="Senha" type="password" margin="normal" value={senha} onChange={e => setSenha(e.target.value)} />
                {erro && <Typography color="error">{erro}</Typography>}
                <Box mt={2}>
                    <Button fullWidth variant="contained" color="primary" onClick={handleLogin}>Entrar</Button>
                </Box>
            </Paper>
        </Container>
    );
}
