"use client"

import { useState, useEffect, useCallback } from "react"
import axios from "axios"
import { jwtDecode } from "jwt-decode"

const API = import.meta.env.VITE_API_URL

interface LinhaCliente {
    id_cliente: string
    nome_cliente: string
    telefone: string | null
    id_grupo: string
    nome_grupo: string
    potencial_compra: number
    valor_comprado: number
}

export const useClientes = () => {
    const [dados, setDados] = useState<LinhaCliente[]>([])
    const [representantes, setRepresentantes] = useState<any[]>([])
    const [repSelecionado, setRepSelecionado] = useState("")
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    const token = localStorage.getItem("token")

    const carregar = useCallback(async () => {
        if (!token) return

        try {
            setLoading(true)
            setError(null)

            const params: any = {}
            if (repSelecionado) params.codusuario = repSelecionado

            const res = await axios.get(`${API}/clientes`, {
                params,
                headers: { Authorization: `Bearer ${token}` },
            })

            const convertidos = res.data.map((linha: any) => ({
                ...linha,
                potencial_compra: Number(linha.potencial_compra),
                valor_comprado: Number(linha.valor_comprado),
            }))

            setDados(convertidos)
        } catch (err: any) {
            setError(err.response?.data?.message || "Erro ao carregar clientes")
            console.error("Erro ao carregar clientes:", err)
        } finally {
            setLoading(false)
        }
    }, [token, repSelecionado])

    const carregarRepresentantes = useCallback(async () => {
        if (!token) return

        try {
            const res = await axios.get(`${API}/usuarios/representantes`, {
                headers: { Authorization: `Bearer ${token}` },
            })
            setRepresentantes(res.data)
        } catch (err) {
            console.error("Erro ao carregar representantes:", err)
        }
    }, [token])

    const salvarPotencial = useCallback(
        async (idCliente: string, idGrupo: string, potencial: number) => {
            if (!token) throw new Error("Token não encontrado")

            console.log("Salvando potencial:", { idCliente, idGrupo, potencial })

            try {
                const response = await axios.put(
                    `${API}/clientes/${idCliente}/grupos/${idGrupo}`,
                    { potencial_compra: potencial },
                    {
                        headers: {
                            Authorization: `Bearer ${token}`,
                            "Content-Type": "application/json",
                        },
                    },
                )

                console.log("Resposta da API:", response.data)
                return response.data
            } catch (error: any) {
                console.error("Erro na requisição:", error.response?.data || error.message)
                throw error
            }
        },
        [token],
    )

    const recarregar = useCallback(() => {
        return carregar()
    }, [carregar])

    useEffect(() => {
        if (token) {
            const decoded: any = jwtDecode(token)
            if (decoded.perfil === "coordenador" || decoded.perfil === "diretor") {
                carregarRepresentantes()
            }
        }
    }, [token, carregarRepresentantes])

    useEffect(() => {
        carregar()
    }, [carregar])

    return {
        dados,
        representantes,
        repSelecionado,
        setRepSelecionado,
        loading,
        error,
        salvarPotencial,
        recarregar,
    }
}
