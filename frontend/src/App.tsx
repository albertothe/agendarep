import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Layout from "./components/Layout";
import Agenda from "./pages/Agenda";

function App() {
  const token = localStorage.getItem("token");

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/login" element={<Login />} />
        <Route
          path="/dashboard"
          element={token ? <Layout><Dashboard /></Layout> : <Navigate to="/" />}
        />
        <Route
          path="/agenda"
          element={token ? <Layout><Agenda /></Layout> : <Navigate to="/" />}
        />
        <Route
          path="/clientes"
          element={token ? <Layout><div>Clientes</div></Layout> : <Navigate to="/" />}
        />
        <Route
          path="/potenciais"
          element={token ? <Layout><div>Sugestões de Visita</div></Layout> : <Navigate to="/" />}
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
