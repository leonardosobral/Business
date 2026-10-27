# Adicionar usuário existente à gestão de Team Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Adicionar usuário já cadastrado na gestão global do Team, como Empresas, e publicar.
**Architecture:** Busca global por nome/email/ID limitada a 25 usuários ativos e sem vínculo administrativo com o Team selecionado. Inclusão direta exclusiva para admin global, com papel OWNER/ADMIN/VIEWER, CSRF, auditoria, verificação transacional de duplicidade e revogação dos convites pendentes do mesmo email. Formulário global próprio incluído antes dos convites existentes.
**Tech Stack:** CFML/CF2025, PostgreSQL e formulários HTML/estilos atuais.
**Spec:** Pedido do usuário em 26/10/2026: incluir opção de adicionar usuário existente à gestão, como nas Empresas.

## Global Constraints
- Somente gestão global concede inclusão direta; demais gestores mantêm convites e regras atuais.
- Não vincular atleta, alterar perfil global/credenciais ou enviar email automaticamente.
- Só papel do Team; rejeitar duplicidade, usuário inativo/inexistente e papel inválido.
- Preservar filtros e dados em erro. GET de busca não concede acesso.
- Banco único: testes em rr_teams_test com rollback, sem adicionar usuários reais em produção.
- Preservar frentes, sem Git/DDL; publicar quatro arquivos com baseline, backup/CAS e validação real por leitura.

## Review Focus
- Gestor/consulta de Team não busca base global nem adiciona diretamente.
- Contas inativas e IDs/papéis adulterados são rejeitados.
- Duplicidade não muda acesso existente nem remove último titular.
- Convites antigos não podem rebaixar ou substituir o novo papel após inclusão direta.
- Busca parametrizada, resultados escapados e CSRF antes de toda mutação.

### Task 1: Serviço de busca/inclusão
**Files:** services/teams/Service.cfc; _codex/tests/teams/existing.cfm.
**Interfaces:** adminCandidates(userId,teamId,search) -> query id/name/email; addExistingAdmin(userId,teamId,memberId,role) -> void.
- [x] Teste nativo RED (métodos ausentes), implementar, GREEN para permissões, busca por ID/email/nome, exclusão dos já vinculados, duplicidade, papéis, revogação de convite, auditoria e ausência de filiação/email.

### Task 2: Tela, verificação e publicação
**Files:** administracao/teams/includes/backend.cfm; administracao/teams/home.cfm; administracao/teams/includes/existing_user.cfm; _codex/scripts/test_teams_global.py; _codex/scripts/deploy_teams_existing.py.
- [x] GET user_busca preserva filtros e busca do Team, mínimo dois caracteres ou ID; form POST add_existing_admin com member/role/csrf e confirmação do acesso imediato.
- [x] POST autorizado executa serviço e PRG volta à aba Equipe administrativa; erros mantêm seleção quando possível.
- [x] Testes HTTP de busca, identificação/escaping, CSRF, permissão, duplicidade, papéis e redirect; compilar candidatos, revisar e conferir desktop/celular.
- [x] Publicar só escopo com backup e CAS; verificar formulário real autenticado sem conceder acesso a usuários reais de teste; atualizar docs/recibos.
