"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const db_1 = require("../db");
const autenticar_1 = __importDefault(require("../middlewares/autenticar"));
const router = (0, express_1.Router)();
router.get("/representantes", autenticar_1.default, async (req, res) => {
    const { codusuario, perfil } = req.user || {};
    if (!perfil) {
        return res.status(401).json({ erro: "Usuário não autenticado" });
    }
    try {
        let query = "";
        let params = [];
        if (perfil === "coordenador") {
            query = "SELECT codusuario, nome FROM agr_usuarios WHERE perfil = 'representante' AND coordenador_id = $1 ORDER BY nome";
            params = [codusuario];
        }
        else if (perfil === "diretor") {
            query = "SELECT codusuario, nome FROM agr_usuarios WHERE perfil = 'representante' ORDER BY nome";
        }
        else {
            return res.status(403).json({ erro: "Sem permissão" });
        }
        const { rows } = await db_1.pool.query(query, params);
        res.json(rows);
    }
    catch (err) {
        console.error("Erro ao listar representantes:", err);
        res.status(500).json({ erro: "Erro ao listar representantes" });
    }
});
exports.default = router;
