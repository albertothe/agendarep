// src/services/api.ts

import axios from "axios";

// Detecta se o acesso é externo (porta pública 18500) ou interno (8500)
const isExterno = window.location.port === "18500";

// Define a porta correta para o backend com base no ambiente
export const API_URL = isExterno
  ? `http://${window.location.hostname}:18501`
  : `http://${window.location.hostname}:8501`;

export const api = axios.create({
  baseURL: API_URL,
});
