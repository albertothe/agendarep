"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const segredo = process.env.JWT_SECRET || "chave-secreta";
const autenticar = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        res.status(401).json({ erro: "Token não fornecido" });
        return;
    }
    const [, token] = authHeader.split(" ");
    try {
        const decoded = jsonwebtoken_1.default.verify(token, segredo);
        req.user = decoded;
        next();
    }
    catch (err) {
        res.status(401).json({ erro: "Token inválido" });
        return;
    }
};
exports.default = autenticar;
