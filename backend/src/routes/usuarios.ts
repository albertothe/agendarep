import { Router, Request, Response } from "express";
import { pool } from "../db";
import autenticar from "../middlewares/autenticar";

const router = Router();

router.get("/representantes", autenticar, async (req: Request, res: Response) => {
    const { codusuario, perfil } = (req as any).user || {};

    if (!perfil) {
        return res.status(401).json({ erro: "Usuário não autenticado" });
    }

    try {
        let query = "";
        let params: any[] = [];

        if (perfil === "coordenador") {
            query = "SELECT codusuario, nome FROM agr_usuarios WHERE perfil = 'representante' AND coordenador_id = $1 ORDER BY nome";
            params = [codusuario];
        } else if (perfil === "diretor") {
            query = "SELECT codusuario, nome FROM agr_usuarios WHERE perfil = 'representante' ORDER BY nome";
        } else {
            return res.status(403).json({ erro: "Sem permissão" });
        }

        const { rows } = await pool.query(query, params);
        res.json(rows);
    } catch (err) {
        console.error("Erro ao listar representantes:", err);
        res.status(500).json({ erro: "Erro ao listar representantes" });
    }
});

export default router;
