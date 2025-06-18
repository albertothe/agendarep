export const formatarTelefone = (tel: string | null | undefined): string => {
    if (!tel) return ""
    const numeros = tel.replace(/\D/g, "")
    if (numeros.length === 11) {
        return numeros.replace(/(\d{2})(\d{5})(\d{4})/, "($1) $2-$3")
    }
    if (numeros.length === 10) {
        return numeros.replace(/(\d{2})(\d{4})(\d{4})/, "($1) $2-$3")
    }
    return tel
}

export const formatarMoeda = (valor: number): string =>
    valor.toLocaleString("pt-BR", {
        style: "currency",
        currency: "BRL",
    })
