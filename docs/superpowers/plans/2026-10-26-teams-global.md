# Teams Global Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Separar a administração global da operação de cada Team e publicar.
**Architecture:** Novo módulo administrativo com o shell existente e serviço Teams, preservando o painel dos responsáveis. Consultas globais autorizadas no serviço, decisão global somente no controlador global; reutilizar formulários de cadastro e admins com CSS local ao módulo.
**Tech Stack:** CF2025/CFML, PostgreSQL, HTML/CSS e JS existente.
**Spec:** docs/superpowers/specs/2026-10-26-teams-global-design.md

## Global Constraints
- Preservar produção e frentes locais; trabalhar no checkout atual já usado pelo módulo, sem operações Git.
- Publicar somente escopo, com backup e validação real; nenhum DDL nem envio de email de teste.
- Identidade verificada + is_admin ativo; defesa por rota e serviço; CSRF/versão.
- Cinza, branco, amarelo e abas acessíveis com GET, filtros e paginação preservados.

## Review Focus
- Não admin, cookie falso e acesso delegado não entram na gestão.
- Filtros combinados, resultados vazios e página excedente não quebram listagem.
- Versão obsoleta e CSRF inválido não gravam revisão.
- Dados HTML são escapados e cadastro digitado não se perde em erro.
- Redirecionamento do painel antigo mantém Team selecionado e menu correto.

### Task 1: Consulta global autorizada
**Files:** services/teams/Service.cfc; _codex/tests/teams/global.cfm; _codex/scripts/test_teams_native.py.
**Interfaces:** globalTeams(userId,search,status,type,uf,page) retorna teams/stats/total/page/pages; ownedTeams(userId,search,page) só vínculos administrativos próprios.
- [x] Criar teste funcional de acesso, filtros, totais, paginação e injeção, observar falha antes de implementar.
- [x] Implementar consultas parametrizadas, validar filtros e executar teste verde com rollback integral.

### Task 2: Área administrativa e separação
**Files:** administracao/teams/{index.cfm,home.cfm,assets/manager.css,includes/backend.cfm,includes/review.cfm}; teams/index.cfm; teams/includes/registration.cfm; includes/estrutura/sidenav.cfm; teams/includes/header.cfm.
**Interfaces:** backend autoriza antes de ler dados globais; GET team/tab/q/status/type/uf/page; POST operation/team/version/csrf e filtros em URL.
- [x] Implementar shell padrão, lista/indicadores e detalhes por abas, revisão e histórico, preservando filtros e entradas.
- [x] Mover revisão global para a nova rota; redirecionar admins globais na rota antiga; usar ownedTeams para painel de responsáveis.
- [x] Validar permissão por HTTP, CSRF, revisão com versão obsoleta, cadastro inválido, navegação/escaping e mobile/desktop.

### Task 3: Verificação e publicação
**Files:** _codex/scripts/deploy_teams_global.py; _codex/teams/global/*; _codex/docs/2026-10-26_teams_operacao.md.
- [x] Compilar candidatos CF e revisar o conjunto final com revisor independente.
- [x] Ler baseline produção e comparar os arquivos existentes antes de publicar; incorporar somente patch de menu preservando frentes.
- [x] Backup recuperável, substituição atômica/CAS com rollback e probes HTTP e autenticado somente leitura.
- [x] Atualizar documentação, recibos/hashes cumulativos e validar resultado visível em produção.
