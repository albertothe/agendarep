"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const db_1 = require("../db");
const autenticar_1 = __importDefault(require("../middlewares/autenticar"));
const router = (0, express_1.Router)();
// Lista clientes respeitando o perfil do usuário
router.get("/", autenticar_1.default, async (req, res) => {
    const { codusuario: codParam } = req.query;
    const { codusuario, perfil } = req.user || {};
    try {
        let query = `SELECT c.id_cliente, c.nome AS nome_cliente, c.telefone,
                            g.id_grupo, g.nome AS nome_grupo,
                            cg.potencial_compra, cg.valor_comprado
                     FROM agr_clientes c
                     LEFT JOIN agr_cliente_grupo cg ON c.id_cliente = cg.id_cliente
                     LEFT JOIN agr_grupos g ON cg.id_grupo = g.id_grupo`;
        const params = [];
        if (perfil === "representante") {
            query += " WHERE c.cod_representante = $1";
            params.push(codusuario);
        }
        else if (perfil === "coordenador") {
            if (codParam) {
                query += " WHERE c.cod_representante = $1";
                params.push(codParam);
            }
            else {
                query +=
                    " WHERE c.cod_representante IN (SELECT codusuario FROM agr_usuarios WHERE coordenador_id = $1)";
                params.push(codusuario);
            }
        }
        else if (perfil === "diretor") {
            if (codParam) {
                query += " WHERE c.cod_representante = $1";
                params.push(codParam);
            }
            // Sem parâmetro: diretor visualiza todos os clientes
        }
        query += " ORDER BY c.nome, g.id_grupo";
        const { rows } = await db_1.pool.query(query, params);
        res.json(rows);
    }
    catch (err) {
        console.error("Erro ao listar clientes:", err);
        res.status(500).json({ erro: "Erro ao listar clientes" });
    }
});
// Atualiza potencial de compra de um cliente em um grupo
router.put("/:id_cliente/grupos/:id_grupo", autenticar_1.default, async (req, res) => {
    const { id_cliente, id_grupo } = req.params;
    const { potencial_compra } = req.body;
    try {
        await db_1.pool.query(`UPDATE agr_cliente_grupo SET potencial_compra = $1
                 WHERE id_cliente = $2 AND id_grupo = $3`, [potencial_compra, id_cliente, id_grupo]);
        res.sendStatus(200);
    }
    catch (err) {
        console.error("Erro ao atualizar potencial:", err);
        res.status(500).json({ erro: "Erro ao atualizar potencial" });
    }
});
exports.default = router;
