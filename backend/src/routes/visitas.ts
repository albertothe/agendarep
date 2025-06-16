// backend/src/routes/visitas.ts
import { Router, Request, Response } from "express"
import { pool } from "../db"
import autenticar from "../middlewares/autenticar"

const router = Router()

// Listar visitas entre duas datas
router.get("/visitas", autenticar, async (req: Request, res: Response) => {
    const { inicio, fim } = req.query
    const idUsuario = (req as any).user?.id

    try {
        const { rows } = await pool.query(
            `SELECT v.*, c.nome as nome_cliente 
       FROM agr_visitas v
       LEFT JOIN agr_clientes c ON v.id_cliente = c.id
       WHERE v.usuario_id = $1 AND v.data BETWEEN $2 AND $3
       ORDER BY v.data, v.hora`,
            [idUsuario, inicio, fim]
        )
        res.json(rows)
    } catch (err) {
        console.error("Erro ao buscar visitas:", err)
        res.status(500).json({ erro: "Erro ao buscar visitas" })
    }
})

// Cadastrar visita
router.post("/visitas", autenticar, async (req: Request, res: Response) => {
    const { data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao } = req.body
    const usuario_id = (req as any).user?.id

    try {
        await pool.query(
            `INSERT INTO agr_visitas (data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao, usuario_id, confirmado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, false)`,
            [data, hora, id_cliente || null, nome_cliente_temp, telefone_temp, observacao, usuario_id]
        )
        res.sendStatus(201)
    } catch (err) {
        console.error("Erro ao cadastrar visita:", err)
        res.status(500).json({ erro: "Erro ao cadastrar visita" })
    }
})

// Confirmar visita
router.put("/visitas/:id/confirmar", autenticar, async (req: Request, res: Response) => {
    const { id } = req.params
    try {
        await pool.query(`UPDATE agr_visitas SET confirmado = true WHERE id = $1`, [id])
        res.sendStatus(200)
    } catch (err) {
        console.error("Erro ao confirmar visita:", err)
        res.status(500).json({ erro: "Erro ao confirmar visita" })
    }
})

// Listar clientes por representante
router.get("/visitas/clientes/representante", autenticar, async (req: Request, res: Response) => {
    const representante_id = (req as any).user?.id
    try {
        const { rows } = await pool.query(
            `SELECT * FROM agr_clientes WHERE representante_id = $1`,
            [representante_id]
        )
        res.json(rows)
    } catch (err) {
        console.error("Erro ao listar clientes:", err)
        res.status(500).json({ erro: "Erro ao listar clientes" })
    }
})

export default router
