-- Tabela de usuários (representantes, coordenadores, diretores)
CREATE TABLE agr_usuarios (
  codusuario CHAR(3) PRIMARY KEY,
  nome TEXT NOT NULL,
  perfil VARCHAR(20) NOT NULL,
  senha TEXT NOT NULL,
  coordenador_id CHAR(3)
);

-- Tabela de grupos
CREATE TABLE agr_grupos (
  id_grupo CHAR(2) PRIMARY KEY,
  nome TEXT NOT NULL
);

-- Tabela de clientes
CREATE TABLE agr_clientes (
  id_cliente CHAR(8) PRIMARY KEY,
  nome TEXT NOT NULL,
  cnpj VARCHAR(18),
  telefone VARCHAR(20),
  cod_representante CHAR(3)
);

-- Tabela relacional cliente x grupo com valores
CREATE TABLE agr_cliente_grupo (
  id_cliente CHAR(8),
  id_grupo CHAR(2),
  potencial_compra NUMERIC(12, 2),
  valor_comprado NUMERIC(12, 2),
  PRIMARY KEY (id_cliente, id_grupo)
);

-- Tabela de agendamento de visitas
CREATE TABLE agr_visitas (
  id SERIAL PRIMARY KEY,
  codusuario CHAR(3),
  data DATE NOT NULL,
  hora TIME NOT NULL,
  id_cliente CHAR(8),
  nome_cliente_temp TEXT,
  telefone_temp VARCHAR(20),
  observacao TEXT,
  confirmado BOOLEAN DEFAULT FALSE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  data_confirmacao TIMESTAMP,
  CONSTRAINT fk_cliente_valido FOREIGN KEY (id_cliente) REFERENCES agr_clientes(id_cliente)
);

-- Regras:
-- Se "id_cliente" for NULL, os campos "nome_cliente_temp" e "telefone_temp" devem ser preenchidos
-- Se "id_cliente" não for NULL, os campos temporários devem ser NULL
