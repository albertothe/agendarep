// backend/src/routes/visitas.ts
import { Router, Request, Response } from "express";
import { pool } from "../db";
import autenticar from "../middlewares/autenticar";

const router = Router();

// Listar visitas entre duas datas
router.get("/", autenticar, async (req: Request, res: Response) => {
    const { inicio, fim } = req.query;
    const codusuario = (req as any).user?.codusuario;

    try {
        const { rows } = await pool.query(
            `SELECT v.*, c.nome AS nome_cliente
       FROM agr_visitas v
       LEFT JOIN agr_clientes c ON v.id_cliente = c.id_cliente
       WHERE v.codusuario = $1 AND v.data BETWEEN $2 AND $3
       ORDER BY v.data, v.hora`,
            [codusuario, inicio, fim]
        );
        res.json(rows);
    } catch (err) {
        console.error("Erro ao buscar visitas:", err);
        res.status(500).json({ erro: "Erro ao buscar visitas" });
    }
});

// Cadastrar visita
router.post("/", autenticar, async (req: Request, res: Response) => {
    const { data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao } = req.body;
    const codusuario = (req as any).user?.codusuario;

    try {
        await pool.query(
            `INSERT INTO agr_visitas (data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao, codusuario, confirmado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, false)`,
            [data, hora, id_cliente || null, nome_cliente_temp || null, telefone_temp || null, observacao, codusuario]
        );
        res.sendStatus(201);
    } catch (err) {
        console.error("Erro ao cadastrar visita:", err);
        res.status(500).json({ erro: "Erro ao cadastrar visita" });
    }
});

// Confirmar visita
router.put("/:id/confirmar", autenticar, async (req: Request, res: Response) => {
    const { id } = req.params;
    try {
        await pool.query(`UPDATE agr_visitas SET confirmado = true, data_confirmacao = CURRENT_TIMESTAMP WHERE id = $1`, [id]);
        res.sendStatus(200);
    } catch (err) {
        console.error("Erro ao confirmar visita:", err);
        res.status(500).json({ erro: "Erro ao confirmar visita" });
    }
});

// Atualizar observação de uma visita
router.put("/:id/observacao", autenticar, async (req: Request, res: Response) => {
    const { id } = req.params;
    const { observacao } = req.body;
    try {
        await pool.query("UPDATE agr_visitas SET observacao = $1 WHERE id = $2", [observacao, id]);
        res.sendStatus(200);
    } catch (err) {
        console.error("Erro ao atualizar observação:", err);
        res.status(500).json({ erro: "Erro ao atualizar observação" });
    }
});

// Listar clientes por representante
router.get("/clientes/representante", autenticar, async (req: Request, res: Response) => {
    const codusuario = (req as any).user?.codusuario;
    try {
        const { rows } = await pool.query(
            `SELECT id_cliente, nome FROM agr_clientes WHERE cod_representante = $1`,
            [codusuario]
        );
        res.json(rows);
    } catch (err) {
        console.error("Erro ao listar clientes:", err);
        res.status(500).json({ erro: "Erro ao listar clientes" });
    }
});

export default router;
