import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useContext } from "react";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Layout from "./components/Layout";
import Agenda from "./pages/Agenda";
import Clientes from "./pages/Clientes";
import Sugestoes from "./pages/Sugestoes";
import { AuthContext } from "./context/AuthContext";

function App() {
  const { token } = useContext(AuthContext);

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
          element={token ? <Layout><Clientes /></Layout> : <Navigate to="/" />}
        />
        <Route
          path="/sugestoes"
          element={token ? <Layout><Sugestoes /></Layout> : <Navigate to="/" />}
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
