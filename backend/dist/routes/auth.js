"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verificarToken = void 0;
const express_1 = __importDefault(require("express"));
const db_1 = require("../db");
const crypto_1 = __importDefault(require("crypto"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const router = express_1.default.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'agenda-secret';
const verificarToken = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
        res.status(401).json({ error: 'Token não fornecido' });
        return;
    }
    try {
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
        req.usuario = decoded;
        next();
    }
    catch (error) {
        res.status(401).json({ error: 'Token inválido' });
    }
};
exports.verificarToken = verificarToken;
router.post('/login', async (req, res) => {
    const { login, senha } = req.body;
    if (!login || !senha) {
        res.status(400).json({ error: 'Login e senha obrigatórios.' });
        return;
    }
    const loginUpper = login.toUpperCase();
    const senhaHash = crypto_1.default
        .createHash('md5')
        .update(loginUpper + senha)
        .digest('hex');
    try {
        console.log("loginUpper:", loginUpper, "senhaHash:", senhaHash);
        const result = await db_1.pool.query('SELECT codusuario, nome, perfil FROM agr_usuarios WHERE UPPER(nome) = $1 AND senha = $2', [loginUpper, senhaHash]);
        if (result.rows.length === 0) {
            res.status(401).json({ error: 'Usuário ou senha inválidos.' });
            return;
        }
        const usuario = result.rows[0];
        const token = jsonwebtoken_1.default.sign(usuario, JWT_SECRET, { expiresIn: '1d' });
        res.json({ sucesso: true, token, usuario });
    }
    catch (error) {
        console.error('Erro na autenticação:', error.message);
        res.status(500).json({ error: error.message });
    }
});
router.get('/verificar-token', exports.verificarToken, (req, res) => {
    res.json({ valido: true, usuario: req.usuario });
});
exports.default = router;
