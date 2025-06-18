import axios from "axios";

// Base URL for API requests
const envUrl = import.meta.env.VITE_API_URL || "http://localhost:8501";
export const API_URL = envUrl.replace(
  "localhost",
  window.location.hostname,
);

export const api = axios.create({
  baseURL: API_URL,
});