-- ============================================================
-- SISTEMA DE BIBLIOTECA - Script SQL (SQLite)
-- Estudo Dirigido 01 - Integridade em Banco de Dados
-- ============================================================

-- Ativar suporte a chaves estrangeiras no SQLite
PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. CRIAÇÃO DAS TABELAS
-- ============================================================

-- Tabela: Autor
CREATE TABLE IF NOT EXISTS Autor (
    id_autor    INTEGER PRIMARY KEY AUTOINCREMENT,
    nome        TEXT NOT NULL,
    nacionalidade TEXT NOT NULL DEFAULT 'Brasileira',
    ano_nascimento INTEGER CHECK (ano_nascimento > 0 AND ano_nascimento <= 2026),
    UNIQUE (nome, ano_nascimento)
);

-- Tabela: Livro
CREATE TABLE IF NOT EXISTS Livro (
    id_livro    INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo      TEXT NOT NULL,
    isbn        TEXT NOT NULL UNIQUE,
    ano_publicacao INTEGER CHECK (ano_publicacao > 0 AND ano_publicacao <= 2026),
    quantidade_total INTEGER NOT NULL CHECK (quantidade_total >= 0),
    quantidade_disponivel INTEGER NOT NULL CHECK (quantidade_disponivel >= 0),
    id_autor    INTEGER NOT NULL,
    CHECK (quantidade_disponivel <= quantidade_total),
    FOREIGN KEY (id_autor) REFERENCES Autor(id_autor)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabela: Membro
CREATE TABLE IF NOT EXISTS Membro (
    id_membro   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome        TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    telefone    TEXT,
    data_cadastro TEXT NOT NULL DEFAULT (DATE('now')),
    status      TEXT NOT NULL DEFAULT 'Ativo' CHECK (status IN ('Ativo', 'Inativo', 'Suspenso'))
);

-- Tabela: Emprestimo
CREATE TABLE IF NOT EXISTS Emprestimo (
    id_emprestimo INTEGER PRIMARY KEY AUTOINCREMENT,
    id_membro     INTEGER NOT NULL,
    id_livro      INTEGER NOT NULL,
    data_emprestimo TEXT NOT NULL DEFAULT (DATE('now')),
    data_devolucao_prevista TEXT NOT NULL,
    data_devolucao_real TEXT,
    status        TEXT NOT NULL DEFAULT 'Ativo' CHECK (status IN ('Ativo', 'Devolvido', 'Atrasado')),
    FOREIGN KEY (id_membro) REFERENCES Membro(id_membro)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_livro) REFERENCES Livro(id_livro)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================================
-- 2. TRIGGERS
-- ============================================================

-- Trigger: ao criar empréstimo, decrementar quantidade disponível
CREATE TRIGGER trg_emprestimo_insert
AFTER INSERT ON Emprestimo
WHEN NEW.status = 'Ativo'
BEGIN
    UPDATE Livro
    SET quantidade_disponivel = quantidade_disponivel - 1
    WHERE id_livro = NEW.id_livro;
END;

-- Trigger: ao devolver livro, incrementar quantidade disponível
CREATE TRIGGER trg_emprestimo_devolucao
AFTER UPDATE ON Emprestimo
WHEN OLD.status = 'Ativo' AND NEW.status = 'Devolvido'
BEGIN
    UPDATE Livro
    SET quantidade_disponivel = quantidade_disponivel + 1
    WHERE id_livro = NEW.id_livro;
END;

-- Trigger: impedir empréstimo se não há exemplar disponível
CREATE TRIGGER trg_verificar_disponibilidade
BEFORE INSERT ON Emprestimo
BEGIN
    SELECT CASE
        WHEN (SELECT quantidade_disponivel FROM Livro WHERE id_livro = NEW.id_livro) <= 0
        THEN RAISE(ABORT, 'Erro: Livro sem exemplares disponíveis para empréstimo.')
    END;
END;

-- Trigger: impedir empréstimo para membro inativo/suspenso
CREATE TRIGGER trg_verificar_membro_ativo
BEFORE INSERT ON Emprestimo
BEGIN
    SELECT CASE
        WHEN (SELECT status FROM Membro WHERE id_membro = NEW.id_membro) != 'Ativo'
        THEN RAISE(ABORT, 'Erro: Membro não está ativo. Empréstimo negado.')
    END;
END;

-- ============================================================
-- 3. INSERÇÕES VÁLIDAS
-- ============================================================

-- Autores
INSERT INTO Autor (nome, nacionalidade, ano_nascimento) VALUES ('Machado de Assis', 'Brasileira', 1839);
INSERT INTO Autor (nome, nacionalidade, ano_nascimento) VALUES ('Clarice Lispector', 'Brasileira', 1920);
INSERT INTO Autor (nome, nacionalidade, ano_nascimento) VALUES ('Jorge Amado', 'Brasileira', 1912);
INSERT INTO Autor (nome, nacionalidade, ano_nascimento) VALUES ('Gabriel García Márquez', 'Colombiana', 1927);

-- Livros
INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
VALUES ('Dom Casmurro', '978-85-0001-001-1', 1899, 5, 5, 1);

INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
VALUES ('A Hora da Estrela', '978-85-0001-002-8', 1977, 3, 3, 2);

INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
VALUES ('Capitães da Areia', '978-85-0001-003-5', 1937, 4, 4, 3);

INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
VALUES ('Cem Anos de Solidão', '978-85-0001-004-2', 1967, 2, 2, 4);

-- Membros
INSERT INTO Membro (nome, email, telefone) VALUES ('Ana Silva', 'ana.silva@email.com', '(11) 99999-1111');
INSERT INTO Membro (nome, email, telefone) VALUES ('Bruno Souza', 'bruno.souza@email.com', '(11) 99999-2222');
INSERT INTO Membro (nome, email, telefone) VALUES ('Carla Oliveira', 'carla.oliveira@email.com', '(11) 99999-3333');
INSERT INTO Membro (nome, email, telefone, status) VALUES ('Diego Lima', 'diego.lima@email.com', '(11) 99999-4444', 'Suspenso');

-- Empréstimos válidos
INSERT INTO Emprestimo (id_membro, id_livro, data_devolucao_prevista)
VALUES (1, 1, DATE('now', '+14 days'));

INSERT INTO Emprestimo (id_membro, id_livro, data_devolucao_prevista)
VALUES (2, 2, DATE('now', '+14 days'));

INSERT INTO Emprestimo (id_membro, id_livro, data_devolucao_prevista)
VALUES (3, 4, DATE('now', '+14 days'));

-- ============================================================
-- 4. TESTES DE INTEGRIDADE
-- ============================================================

-- Verificar que quantidade_disponivel foi decrementada pelo trigger
-- SELECT id_livro, titulo, quantidade_total, quantidade_disponivel FROM Livro;

-- TESTE 1: Inserção com ISBN duplicado (viola UNIQUE)
-- INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
-- VALUES ('Teste Duplicado', '978-85-0001-001-1', 2020, 1, 1, 1);
-- Resultado esperado: ERRO - UNIQUE constraint failed: Livro.isbn

-- TESTE 2: Inserção com chave estrangeira inválida
-- INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
-- VALUES ('Livro Fantasma', '978-85-0001-099-9', 2020, 1, 1, 999);
-- Resultado esperado: ERRO - FOREIGN KEY constraint failed

-- TESTE 3: quantidade_disponivel > quantidade_total (viola CHECK)
-- INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
-- VALUES ('Livro Errado', '978-85-0001-098-2', 2020, 2, 5, 1);
-- Resultado esperado: ERRO - CHECK constraint failed

-- TESTE 4: Email duplicado em Membro (viola UNIQUE)
-- INSERT INTO Membro (nome, email) VALUES ('Outro Ana', 'ana.silva@email.com');
-- Resultado esperado: ERRO - UNIQUE constraint failed: Membro.email

-- TESTE 5: Empréstimo para membro suspenso (viola trigger)
-- INSERT INTO Emprestimo (id_membro, id_livro, data_devolucao_prevista)
-- VALUES (4, 3, DATE('now', '+14 days'));
-- Resultado esperado: ERRO - Membro não está ativo

-- TESTE 6: Deletar autor com livros vinculados (viola FK RESTRICT)
-- DELETE FROM Autor WHERE id_autor = 1;
-- Resultado esperado: ERRO - FOREIGN KEY constraint failed

-- ============================================================
-- 5. OPERAÇÕES DE UPDATE E DELETE
-- ============================================================

-- Devolver um livro (UPDATE com trigger)
UPDATE Emprestimo
SET status = 'Devolvido', data_devolucao_real = DATE('now')
WHERE id_emprestimo = 1;

-- Verificar que quantidade voltou
-- SELECT id_livro, titulo, quantidade_disponivel FROM Livro WHERE id_livro = 1;

-- Atualizar dados de membro
UPDATE Membro SET telefone = '(11) 98888-1111' WHERE id_membro = 1;

-- ============================================================
-- 6. CONTROLE DE TRANSAÇÕES (COMMIT / ROLLBACK)
-- ============================================================

-- Exemplo de transação bem-sucedida
BEGIN TRANSACTION;
    INSERT INTO Autor (nome, nacionalidade, ano_nascimento) VALUES ('José Saramago', 'Portuguesa', 1922);
    INSERT INTO Livro (titulo, isbn, ano_publicacao, quantidade_total, quantidade_disponivel, id_autor)
    VALUES ('Ensaio sobre a Cegueira', '978-85-0001-005-9', 1995, 3, 3, 5);
COMMIT;

-- Exemplo de transação com ROLLBACK
BEGIN TRANSACTION;
    INSERT INTO Membro (nome, email) VALUES ('Teste Rollback', 'teste@rollback.com');
    -- Simulando que algo deu errado, desfazemos a operação
ROLLBACK;

-- Verificar que 'Teste Rollback' NÃO existe
-- SELECT * FROM Membro WHERE email = 'teste@rollback.com';
-- Resultado esperado: nenhum registro

-- ============================================================
-- 7. CONSULTAS ÚTEIS
-- ============================================================

-- Listar todos os livros com seus autores
SELECT L.titulo, L.isbn, L.ano_publicacao, A.nome AS autor,
       L.quantidade_total, L.quantidade_disponivel
FROM Livro L
INNER JOIN Autor A ON L.id_autor = A.id_autor;

-- Listar empréstimos ativos
SELECT E.id_emprestimo, M.nome AS membro, L.titulo AS livro,
       E.data_emprestimo, E.data_devolucao_prevista
FROM Emprestimo E
INNER JOIN Membro M ON E.id_membro = M.id_membro
INNER JOIN Livro L ON E.id_livro = L.id_livro
WHERE E.status = 'Ativo';

-- Verificar estado final do banco
SELECT '--- AUTORES ---' AS info;
SELECT * FROM Autor;
SELECT '--- LIVROS ---' AS info;
SELECT * FROM Livro;
SELECT '--- MEMBROS ---' AS info;
SELECT * FROM Membro;
SELECT '--- EMPRÉSTIMOS ---' AS info;
SELECT * FROM Emprestimo;
