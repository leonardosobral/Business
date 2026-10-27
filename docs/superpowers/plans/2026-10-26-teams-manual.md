# Cadastro manual de Teams Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Permitir cadastro manual de Team por admin global e publicar.
**Architecture:** Botão Novo Team e formulário na mesma tela administrativa, como Empresas. Serviço exclusivo global reutiliza campos e inserção do cadastro existente; cria PENDING, registra autor global no histórico e encaminha para Revisão. Acesso dos responsáveis é configurado depois por convites existentes. Admin global criador não vira titular e nenhum atleta é vinculado.
**Tech Stack:** CFML/CF2025, PostgreSQL e HTML/CSS existentes.
**Spec:** Pedido do usuário em 26/10/2026 e comportamento descrito nesta sessão: implementar cadastro manual na gestão global e publicar.

## Global Constraints
- Preservar outras frentes, sem Git/DDL/emails de teste; único banco tem fixture rr_teams_test e rollback.
- Identidade global verificada, CSRF, validações de campos/CREF e duplicidade; novo registro pendente, sem aprovação implícita.
- Filtros/retorno e dados digitados em erros preservados; nova tela usa os campos/estilos do módulo.
- Backup recuperável, baseline/CAS, publicação só dos quatro arquivos do escopo e verificação real.

## Review Focus
- Usuário comum não chama criação global nem recebe privilégio por campos forjados.
- CSRF inválido, CPF/CREF inválido e nome/documento duplicado não criam registros.
- Admin cria sem assumir OWNER ou filiar atletas, e sem disparar convite automaticamente.
- Registro e auditoria persistem juntos, com histórico manual e revisão obrigatória.
- Falha conserva formulário e filtros; sucesso usa PRG para evitar duplicação no reload.

### Task 1: Serviço global de cadastro
**Files:** services/teams/Service.cfc; _codex/tests/teams/manual.cfm.
**Interface:** registerGlobal(userId,data) retorna id, apenas admin global, cria PENDING sem vínculo administrativo automático; register(userId,data) mantém quota e OWNER do auto cadastro.
- [x] Testar RED: método ausente; testes nativos por cenário com rollback.
- [x] Implementar núcleo privado compartilhado de inserção, limite diário só para auto cadastro, validação/duplicidade e auditoria manual.
- [x] Testar GREEN: permissão, campos inválidos, duplicidade, estado inicial e ausência de vínculos/emails; regressão do auto cadastro.

### Task 2: Formulário manual e publicação
**Files:** administracao/teams/home.cfm; administracao/teams/includes/backend.cfm; administracao/teams/includes/create.cfm; _codex/scripts/test_teams_global.py; _codex/scripts/deploy_teams_manual.py.
- [x] Testes HTTP do botão/form, autorização, CSRF, validações, filtros e redirect.
- [x] Botão Novo Team em qualquer recorte; GET novo=1 com form; POST create separado das operações com Team existente, CSRF antes do serviço. Salvar e revisar -> Team selecionado / Revisão.
- [x] Compilar os candidatos e conferir desktop/celular; revisão independente.
- [x] Publicar quatro arquivos após baseline/backup, validar produção autenticada por leitura do formulário; não criar Team real de teste.
