# Estudo Dirigido 01 — Projeto Prático de Integridade em Banco de Dados

## Sistema de Biblioteca

Projeto prático de banco de dados relacional com foco em integridade de dados, utilizando SQLite.

### Integrantes

- Pedro Paiva Ferreira
- João Hugo Teixeira Martins Botelho
- Bernardo Ladeira Leal de Medeiros
- Igor Landim

### Estrutura do Projeto

| Arquivo | Descrição |
|---------|----------|
| `biblioteca.sql` | Script SQL completo (tabelas, triggers, dados, testes, transações) |
| `relatorio_biblioteca.pdf` | Relatório completo do projeto |

### Como Executar

```bash
sqlite3 biblioteca.db < biblioteca.sql
```

Ou abra o arquivo `biblioteca.sql` em qualquer ferramenta compatível com SQLite (DBeaver, DB Browser for SQLite).

### O que foi implementado

- **4 tabelas**: Autor, Livro, Membro, Empréstimo
- **Chaves primárias e estrangeiras** com ON DELETE RESTRICT
- **Restrições**: NOT NULL, UNIQUE, CHECK
- **4 triggers**: controle automático de estoque e validações de negócio
- **Controle de transações**: COMMIT e ROLLBACK
- **8 testes de integridade** documentados

### SGBD

SQLite

### Disciplina

Banco de Dados
