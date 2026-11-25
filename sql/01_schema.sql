-- Esquema para SQL Server (2016 ou superior)
DROP TABLE IF EXISTS chamados;
DROP TABLE IF EXISTS analistas;
DROP TABLE IF EXISTS setores;

CREATE TABLE setores (
    id   INT PRIMARY KEY,
    nome VARCHAR(60) NOT NULL
);

CREATE TABLE analistas (
    id    INT PRIMARY KEY,
    nome  VARCHAR(80) NOT NULL,
    setor INT NOT NULL REFERENCES setores(id)
);

CREATE TABLE chamados (
    id              INT PRIMARY KEY,
    setor           INT NOT NULL REFERENCES setores(id),
    analista        INT NOT NULL REFERENCES analistas(id),
    data_abertura   DATETIME2 NOT NULL,
    data_fechamento DATETIME2 NULL,   -- NULL = chamado em aberto
    categoria       VARCHAR(40) NOT NULL
);
