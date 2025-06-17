// backend/src/server.ts
import express from "express"
import cors from "cors"
import dotenv from "dotenv"
import authRoutes from "./routes/auth"
import visitasRoutes from "./routes/visitas"
import clientesRoutes from "./routes/clientes"
import usuariosRoutes from "./routes/usuarios"

dotenv.config()

const app = express()
const PORT = process.env.PORT || 8501

app.use(cors())
app.use(express.json())

app.use("/auth", authRoutes)
app.use("/visitas", visitasRoutes)
app.use("/clientes", clientesRoutes)
app.use("/usuarios", usuariosRoutes)

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`)
})