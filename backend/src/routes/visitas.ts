// backend/src/routes/visitas.ts
import { Router, type Request, type Response } from "express"
import { pool } from "../db"
import autenticar from "../middlewares/autenticar"

const router = Router()

// Listar visitas entre duas datas
router.get("/", autenticar, async (req: Request, res: Response) => {
    const { inicio, fim, codusuario: codParam } = req.query as any
    const { codusuario, perfil } = (req as any).user || {}

    console.log("🔍 GET /visitas - Parâmetros recebidos:", { inicio, fim, codParam })
    console.log("👤 Usuário autenticado:", { codusuario, perfil })

    try {
        let query = `SELECT v.*, c.nome AS nome_cliente, u.nome AS nome_representante
            FROM agr_visitas v
            LEFT JOIN agr_clientes c ON v.id_cliente = c.id_cliente
            LEFT JOIN agr_usuarios u ON v.codusuario = u.codusuario
            WHERE v.data BETWEEN $1 AND $2`
        const params: any[] = [inicio, fim]

        if (perfil === "representante") {
            query += " AND v.codusuario = $3"
            params.push(codusuario)
        } else if (perfil === "coordenador") {
            if (codParam) {
                query += " AND v.codusuario = $3"
                params.push(codParam)
            } else {
                query += " AND u.coordenador_id = $3"
                params.push(codusuario)
            }
        } else if (perfil === "diretor" && codParam) {
            query += " AND v.codusuario = $3"
            params.push(codParam)
        }

        query += " ORDER BY v.data, v.hora"

        console.log("🔍 Query final:", query)
        console.log("🔍 Parâmetros finais:", params)

        const { rows } = await pool.query(query, params)
        console.log("✅ Visitas encontradas:", rows.length)
        res.json(rows)
    } catch (err) {
        console.error("❌ Erro ao buscar visitas:", err)
        res.status(500).json({ erro: "Erro ao buscar visitas" })
    }
})

// Cadastrar visita
router.post("/", autenticar, async (req: Request, res: Response) => {
    const { data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao, codusuario: codusuarioBody } = req.body
    const { codusuario: codusuarioToken, perfil } = (req as any).user || {}

    console.log("=== DEBUG POST /visitas ===")
    console.log("🌐 Headers:", req.headers)
    console.log("📥 Body completo:", JSON.stringify(req.body, null, 2))
    console.log("👤 Usuário do token:", { codusuario: codusuarioToken, perfil })
    console.log("🎯 codusuario do body:", codusuarioBody)
    console.log("🔍 Tipo do codusuario body:", typeof codusuarioBody)
    console.log("🔍 codusuario body é null/undefined?", codusuarioBody == null)
    console.log("🔍 codusuario body é string vazia?", codusuarioBody === "")

    // Validação mais rigorosa do codusuario do body
    const codusuarioBodyValido =
        codusuarioBody && codusuarioBody !== "" && codusuarioBody !== "null" && codusuarioBody !== "undefined"

    console.log("🔍 codusuario body é válido?", codusuarioBodyValido)

    // Determinar qual codusuario usar com validação mais rigorosa
    let codusuarioFinal = codusuarioToken

    if ((perfil === "coordenador" || perfil === "diretor") && codusuarioBodyValido) {
        codusuarioFinal = codusuarioBody
        console.log("✅ Usando codusuario do representante selecionado:", codusuarioFinal)
    } else {
        console.log("✅ Usando codusuario do token (representante logado):", codusuarioFinal)

        // Log adicional para debug
        if (perfil === "coordenador" || perfil === "diretor") {
            console.log("⚠️ ATENÇÃO: Coordenador/Diretor mas codusuario do body inválido!")
            console.log("⚠️ Perfil:", perfil)
            console.log("⚠️ codusuario body original:", codusuarioBody)
            console.log("⚠️ codusuario body válido:", codusuarioBodyValido)
        }
    }

    console.log("🔧 codusuario final que será salvo:", codusuarioFinal)
    console.log("🔧 Tipo do codusuario final:", typeof codusuarioFinal)
    console.log("========================")

    // Validação adicional antes de salvar
    if (!codusuarioFinal) {
        console.error("❌ ERRO: codusuario final está vazio!")
        return res.status(400).json({ erro: "Código do usuário não pode estar vazio" })
    }

    try {
        const result = await pool.query(
            `INSERT INTO agr_visitas (data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao, codusuario, confirmado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, false) RETURNING *`,
            [data, hora, id_cliente || null, nome_cliente_temp || null, telefone_temp || null, observacao, codusuarioFinal],
        )

        console.log("✅ Visita criada com sucesso:")
        console.log("📋 ID:", result.rows[0].id)
        console.log("📋 Data/Hora:", result.rows[0].data, result.rows[0].hora)
        console.log("📋 Codusuario salvo:", result.rows[0].codusuario)
        console.log("📋 Cliente:", result.rows[0].nome_cliente_temp || result.rows[0].id_cliente)

        res.status(201).json(result.rows[0])
    } catch (err) {
        console.error("❌ Erro ao cadastrar visita:", err)
        res.status(500).json({ erro: "Erro ao cadastrar visita" })
    }
})

// Confirmar visita
router.put("/:id/confirmar", autenticar, async (req: Request, res: Response) => {
    const { id } = req.params
    try {
        await pool.query(`UPDATE agr_visitas SET confirmado = true, data_confirmacao = CURRENT_TIMESTAMP WHERE id = $1`, [
            id,
        ])
        res.sendStatus(200)
    } catch (err) {
        console.error("Erro ao confirmar visita:", err)
        res.status(500).json({ erro: "Erro ao confirmar visita" })
    }
})

// Atualizar observação de uma visita
router.put("/:id/observacao", autenticar, async (req: Request, res: Response) => {
    const { id } = req.params
    const { observacao } = req.body
    try {
        await pool.query("UPDATE agr_visitas SET observacao = $1 WHERE id = $2", [observacao, id])
        res.sendStatus(200)
    } catch (err) {
        console.error("Erro ao atualizar observação:", err)
        res.status(500).json({ erro: "Erro ao atualizar observação" })
    }
})

// Listar clientes por representante
router.get("/clientes/representante", autenticar, async (req: Request, res: Response) => {
    const { codusuario: codParam } = req.query as any
    const { codusuario, perfil } = (req as any).user || {}
    const rep = (perfil === "coordenador" || perfil === "diretor") && codParam ? codParam : codusuario
    try {
        const { rows } = await pool.query(`SELECT id_cliente, nome FROM agr_clientes WHERE cod_representante = $1`, [rep])
        res.json(rows)
    } catch (err) {
        console.error("Erro ao listar clientes:", err)
        res.status(500).json({ erro: "Erro ao listar clientes" })
    }
})

export default router
