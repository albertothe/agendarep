import { Request, Response, NextFunction } from "express"
import jwt from "jsonwebtoken"

const segredo = process.env.JWT_SECRET || "chave-secreta"

export interface JwtPayload {
    id: number
    nome: string
    nivel: string
    coordenador_id?: number
}

const autenticar = (req: Request, res: Response, next: NextFunction): void => {
    const authHeader = req.headers.authorization
    if (!authHeader) {
        res.status(401).json({ erro: "Token não fornecido" })
        return
    }

    const [, token] = authHeader.split(" ")

    try {
        const decoded = jwt.verify(token, segredo) as JwtPayload
        (req as any).user = decoded;
        next()
    } catch (err) {
        res.status(401).json({ erro: "Token inválido" })
        return
    }
}

export default autenticar
