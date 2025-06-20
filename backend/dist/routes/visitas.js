"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
// backend/src/routes/visitas.ts
const express_1 = require("express");
const db_1 = require("../db");
const autenticar_1 = __importDefault(require("../middlewares/autenticar"));
const router = (0, express_1.Router)();
// Listar visitas entre duas datas
router.get("/", autenticar_1.default, async (req, res) => {
    const { inicio, fim, codusuario: codParam } = req.query;
    const { codusuario, perfil } = req.user || {};
    try {
        let query = `SELECT v.*, c.nome AS nome_cliente, u.nome AS nome_representante
            FROM agr_visitas v
            LEFT JOIN agr_clientes c ON v.id_cliente = c.id_cliente
            LEFT JOIN agr_usuarios u ON v.codusuario = u.codusuario
            WHERE v.data BETWEEN $1 AND $2`;
        const params = [inicio, fim];
        if (perfil === "representante") {
            query += " AND v.codusuario = $3";
            params.push(codusuario);
        }
        else if (perfil === "coordenador") {
            if (codParam) {
                query += " AND v.codusuario = $3";
                params.push(codParam);
            }
            else {
                query += " AND u.coordenador_id = $3";
                params.push(codusuario);
            }
        }
        else if (perfil === "diretor" && codParam) {
            query += " AND v.codusuario = $3";
            params.push(codParam);
        }
        query += " ORDER BY v.data, v.hora";
        const { rows } = await db_1.pool.query(query, params);
        res.json(rows);
    }
    catch (err) {
        console.error("Erro ao buscar visitas:", err);
        res.status(500).json({ erro: "Erro ao buscar visitas" });
    }
});
// Cadastrar visita
router.post("/", autenticar_1.default, async (req, res) => {
    const { data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao } = req.body;
    const codusuario = req.user?.codusuario;
    try {
        await db_1.pool.query(`INSERT INTO agr_visitas (data, hora, id_cliente, nome_cliente_temp, telefone_temp, observacao, codusuario, confirmado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, false)`, [data, hora, id_cliente || null, nome_cliente_temp || null, telefone_temp || null, observacao, codusuario]);
        res.sendStatus(201);
    }
    catch (err) {
        console.error("Erro ao cadastrar visita:", err);
        res.status(500).json({ erro: "Erro ao cadastrar visita" });
    }
});
// Confirmar visita
router.put("/:id/confirmar", autenticar_1.default, async (req, res) => {
    const { id } = req.params;
    try {
        await db_1.pool.query(`UPDATE agr_visitas SET confirmado = true, data_confirmacao = CURRENT_TIMESTAMP WHERE id = $1`, [id]);
        res.sendStatus(200);
    }
    catch (err) {
        console.error("Erro ao confirmar visita:", err);
        res.status(500).json({ erro: "Erro ao confirmar visita" });
    }
});
// Atualizar observação de uma visita
router.put("/:id/observacao", autenticar_1.default, async (req, res) => {
    const { id } = req.params;
    const { observacao } = req.body;
    try {
        await db_1.pool.query("UPDATE agr_visitas SET observacao = $1 WHERE id = $2", [observacao, id]);
        res.sendStatus(200);
    }
    catch (err) {
        console.error("Erro ao atualizar observação:", err);
        res.status(500).json({ erro: "Erro ao atualizar observação" });
    }
});
// Listar clientes por representante
router.get("/clientes/representante", autenticar_1.default, async (req, res) => {
    const { codusuario: codParam } = req.query;
    const { codusuario, perfil } = req.user || {};
    const rep = (perfil === "coordenador" || perfil === "diretor") && codParam ? codParam : codusuario;
    try {
        const { rows } = await db_1.pool.query(`SELECT id_cliente, nome FROM agr_clientes WHERE cod_representante = $1`, [rep]);
        res.json(rows);
    }
    catch (err) {
        console.error("Erro ao listar clientes:", err);
        res.status(500).json({ erro: "Erro ao listar clientes" });
    }
});
exports.default = router;
