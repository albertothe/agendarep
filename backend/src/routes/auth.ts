import express, { Request, Response, NextFunction } from 'express';
import { pool } from '../db';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'agenda-secret';

interface RequestComUsuario extends Request {
  usuario?: {
    codusuario: string;
    nome: string;
    perfil: string;
  };
}

export const verificarToken = (
  req: RequestComUsuario,
  res: Response,
  next: NextFunction
): void => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    res.status(401).json({ error: 'Token não fornecido' });
    return;
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.usuario = decoded as RequestComUsuario['usuario'];
    next();
  } catch (error) {
    res.status(401).json({ error: 'Token inválido' });
  }
};

router.post('/login', async (req: Request, res: Response) => {
  const { login, senha } = req.body;
  if (!login || !senha) {
    res.status(400).json({ error: 'Login e senha obrigatórios.' });
    return;
  }

  const loginUpper = login.toUpperCase();
  const senhaHash = crypto
    .createHash('md5')
    .update(loginUpper + senha.toUpperCase())
    .digest('hex');

  try {
    console.log("loginUpper:", loginUpper, "senhaHash:", senhaHash);

    const result = await pool.query(
      'SELECT codusuario, nome, perfil FROM agr_usuarios WHERE UPPER(nome) = $1 AND senha = $2',
      [loginUpper, senhaHash]
    );

    if (result.rows.length === 0) {
      res.status(401).json({ error: 'Usuário ou senha inválidos.' });
      return;
    }

    const usuario = result.rows[0];
    const token = jwt.sign(usuario, JWT_SECRET, { expiresIn: '1d' });

    res.json({ sucesso: true, token, usuario });
  } catch (error: any) {
    console.error('Erro na autenticação:', error.message);
    res.status(500).json({ error: error.message });
  }
});

router.get('/verificar-token', verificarToken, (req: RequestComUsuario, res: Response) => {
  res.json({ valido: true, usuario: req.usuario });
});

export default router;